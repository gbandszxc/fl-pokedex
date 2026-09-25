import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../../domain/models/ability_ref.dart';
import '../../domain/models/evolution.dart';
import '../../domain/models/filters.dart';
import '../../domain/models/flavor_entry.dart';
import '../../domain/models/form_summary.dart';
import '../../domain/models/move_detail.dart';
import '../../domain/models/move_entry.dart';
import '../../domain/models/pokemon_summary.dart';
import '../../domain/models/refs.dart';
import '../../domain/models/stat_block.dart';
import 'tables.dart';

part 'pokedex_database.g.dart';

/// 只读图鉴库（assets/database/pokedex.db 的副本）。
///
/// 数据库文件由 assets 复制而来（复制与版本比对逻辑见 lib/core/di.dart，
/// 本文件保持纯 Dart 依赖——codegen 需要完整 resolve 本库，引入
/// Flutter SDK 源码会让 drift_dev 崩溃）。打开时以 `PRAGMA query_only`
/// + `enableMigrations: false` 双保险：SQLite 层面禁写，drift 也不尝试
/// 迁移或写 user_version（schema 演进完全由数据构建脚本负责）。
@DriftDatabase(
  tables: [
    Meta,
    Generations,
    Types,
    Abilities,
    Moves,
    Species,
    Forms,
    FormTypes,
    FormStats,
    FormAbilities,
    PokemonFormMoves,
    EvolutionChains,
    EvolutionEdges,
    Versions,
    FlavorTexts,
    Pokedexes,
    SpeciesDexNumbers,
  ],
  daos: [PokedexDao, MoveDao, EvolutionDao, MetaDao],
)
class PokedexDatabase extends _$PokedexDatabase {
  PokedexDatabase(super.executor);

  /// 资产库路径（复制与 manifest 读取见 lib/core/di.dart）。
  static const String assetDbPath = 'assets/database/pokedex.db';

  /// manifest 路径。
  static const String assetManifestPath = 'assets/database/manifest.json';

  /// 只读执行器：禁迁移（库文件 schema 完全由数据构建期负责），
  /// 并用 `PRAGMA query_only` 在 SQLite 层面禁止任何写入。
  ///
  /// 说明：drift 2.28 的 [NativeDatabase] 没有 readOnly 参数，
  /// 这是等价且更严格的做法（正式打开与宿主测试共用）。
  static QueryExecutor readOnlyExecutor(File file) => NativeDatabase(
        file,
        enableMigrations: false,
        setup: (db) => db.execute('PRAGMA query_only = ON'),
      );

  /// 临时只读连接探测本地副本的 meta.schema_version（di 复制策略使用）。
  static Future<int?> storedSchemaVersion(File file) async {
    if (!file.existsSync()) return null;
    final probe = PokedexDatabase(readOnlyExecutor(file));
    try {
      final raw = await probe.metaDao.getMetaValue('schema_version');
      return raw == null ? null : int.tryParse(raw);
    } on Exception {
      return null; // 表缺失/文件损坏 → 视为需要覆盖复制
    } finally {
      try {
        await probe.close();
      } on Exception {
        // 连接未成功打开等场景，忽略关闭异常
      }
    }
  }

  @override
  int get schemaVersion => 1;
}

/// 进化边原始行（DAO 查询结果；由 PokedexRepositoryImpl 组装成树）。
///
/// 同时携带 to 端 species 的展示信息（编号/简中名/默认形态缩略图）：
/// 链上每个 species 至少作为一条边的 to 端出现，因此信息完整。
class EvolutionEdgeData {
  const EvolutionEdgeData({
    required this.chainId,
    required this.fromSpeciesId,
    required this.toSpeciesId,
    required this.trigger,
    required this.toNationalDex,
    required this.toNameZh,
    required this.toThumbAsset,
    this.minLevel,
    this.item,
    this.heldItem,
    this.knownMove,
    this.knownMoveType,
    this.location,
    this.timeOfDay,
    this.gender,
    this.minHappiness,
    this.minAffection,
    this.minBeauty,
    this.relativePhysicalStats,
    this.partySpecies,
    this.partyType,
    this.tradeSpecies,
    required this.needsRain,
    required this.turnUpsideDown,
  });

  final int chainId;
  final int? fromSpeciesId;
  final int toSpeciesId;
  final String trigger;
  final int toNationalDex;
  final String toNameZh;
  final String? toThumbAsset;
  final int? minLevel;
  final String? item;
  final String? heldItem;
  final String? knownMove;
  final String? knownMoveType;
  final String? location;
  final String? timeOfDay;
  final String? gender;
  final int? minHappiness;
  final int? minAffection;
  final int? minBeauty;
  final String? relativePhysicalStats;
  final String? partySpecies;
  final String? partyType;
  final String? tradeSpecies;
  final bool needsRain;
  final bool turnUpsideDown;

  bool get isRootRow => trigger == 'root' && fromSpeciesId == null;

  EvolutionEdge toDomain() => EvolutionEdge(
        chainId: chainId,
        fromSpeciesId: fromSpeciesId,
        toSpeciesId: toSpeciesId,
        trigger: trigger,
        minLevel: minLevel,
        item: item,
        heldItem: heldItem,
        knownMove: knownMove,
        knownMoveType: knownMoveType,
        location: location,
        timeOfDay: timeOfDay,
        gender: gender,
        minHappiness: minHappiness,
        minAffection: minAffection,
        minBeauty: minBeauty,
        relativePhysicalStats: relativePhysicalStats,
        partySpecies: partySpecies,
        partyType: partyType,
        tradeSpecies: tradeSpecies,
        needsRain: needsRain,
        turnUpsideDown: turnUpsideDown,
      );
}

/// 列表/详情类查询：物种、形态、图鉴文本与基础引用表。
@DriftAccessor()
class PokedexDao extends DatabaseAccessor<PokedexDatabase>
    with _$PokedexDaoMixin {
  PokedexDao(super.attachedDatabase);

  /// 列表页查询（architecture.md §7 WHERE 语义），单条 SQL 聚合：
  /// species 基本列 + 默认形态 thumb + 默认形态属性（有序 CSV）。
  Future<List<PokemonSummary>> queryPokemon(
    FilterState f, {
    required int limit,
    required int offset,
  }) async {
    final (whereSql, whereVariables) = _buildWhere(f);
    final variables = [
      ...whereVariables,
      Variable.withInt(limit),
      Variable.withInt(offset),
    ];
    final rows = await customSelect(
      'SELECT s.id AS species_id, s.national_dex, s.name_zh_hans, s.name_en, '
      '       s.name_ja, s.generation_id, s.is_legendary, s.is_mythical, '
      '       s.is_ultra_beast, df.thumb_asset, '
      '       (SELECT GROUP_CONCAT(x.identifier, \',\') FROM ('
      '          SELECT t.identifier FROM form_types ft '
      '          JOIN types t ON t.id = ft.type_id '
      '          WHERE ft.form_id = df.id ORDER BY ft.slot ASC) AS x'
      '       ) AS type_ids_csv '
      'FROM species s '
      'JOIN forms df ON df.species_id = s.id AND df.is_default = 1 '
      '$whereSql '
      'ORDER BY s.national_dex ASC LIMIT ? OFFSET ?',
      variables: variables,
      readsFrom: {
        attachedDatabase.species,
        attachedDatabase.forms,
        attachedDatabase.formTypes,
        attachedDatabase.types,
      },
    ).get();
    return rows.map(_mapPokemonSummary).toList(growable: false);
  }

  /// 与 [queryPokemon] 相同 WHERE 的总数（分页用）。
  Future<int> countPokemon(FilterState f) async {
    final (whereSql, variables) = _buildWhere(f);
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM species s '
      'JOIN forms df ON df.species_id = s.id AND df.is_default = 1 '
      '$whereSql',
      variables: variables,
      readsFrom: {
        attachedDatabase.species,
        attachedDatabase.forms,
        attachedDatabase.formTypes,
        attachedDatabase.types,
        attachedDatabase.speciesDexNumbers,
      },
    ).getSingle();
    return row.data['c'] as int;
  }

  /// species 全部形态 + 各自属性（有序 CSV），按 form_order 排序。
  Future<List<FormSummary>> getForms(int speciesId) async {
    final rows = await customSelect(
      'SELECT f.id AS form_id, f.species_id, f.form_identifier, '
      '       f.form_name_zh, f.form_name_en, f.is_default, f.is_mega, '
      '       f.is_gmax, f.is_regional, f.artwork_asset, '
      '       (SELECT GROUP_CONCAT(x.identifier, \',\') FROM ('
      '          SELECT t.identifier FROM form_types ft '
      '          JOIN types t ON t.id = ft.type_id '
      '          WHERE ft.form_id = f.id ORDER BY ft.slot ASC) AS x'
      '       ) AS type_ids_csv '
      'FROM forms f WHERE f.species_id = ? ORDER BY f.form_order ASC',
      variables: [Variable.withInt(speciesId)],
      readsFrom: {
        attachedDatabase.forms,
        attachedDatabase.formTypes,
        attachedDatabase.types,
      },
    ).get();
    return rows
        .map(
          (row) => FormSummary(
            formId: row.data['form_id'] as int,
            speciesId: row.data['species_id'] as int,
            formIdentifier: row.data['form_identifier'] as String?,
            formNameZh: row.data['form_name_zh'] as String,
            formNameEn: row.data['form_name_en'] as String,
            isDefault: (row.data['is_default'] as int) != 0,
            isMega: (row.data['is_mega'] as int) != 0,
            isGmax: (row.data['is_gmax'] as int) != 0,
            isRegional: (row.data['is_regional'] as int) != 0,
            artworkAsset: row.data['artwork_asset'] as String?,
            typeIds: _typeIdsFromCsv(row.data['type_ids_csv'] as String?),
          ),
        )
        .toList(growable: false);
  }

  /// 六项种族值（数据契约保证每形态 6 行齐全）。
  Future<StatBlock> getFormStats(int formId) async {
    final rows = await (select(attachedDatabase.formStats)
          ..where((tbl) => tbl.formId.equals(formId)))
        .get();
    int stat(String name) => rows
        .firstWhere(
          (r) => r.stat == name,
          orElse: () => throw StateError(
            'form_stats 缺少 form_id=$formId 的 $name 行',
          ),
        )
        .baseValue;
    return StatBlock(
      hp: stat('hp'),
      attack: stat('attack'),
      defense: stat('defense'),
      specialAttack: stat('special_attack'),
      specialDefense: stat('special_defense'),
      speed: stat('speed'),
    );
  }

  /// 形态特性（非隐藏在前，同槽位按 slot 排序）。
  Future<List<AbilityRef>> getFormAbilities(int formId) async {
    final rows = await customSelect(
      'SELECT a.id, a.name_zh_hans, a.name_en, fa.is_hidden '
      'FROM form_abilities fa JOIN abilities a ON a.id = fa.ability_id '
      'WHERE fa.form_id = ? '
      'ORDER BY fa.is_hidden ASC, fa.slot ASC',
      variables: [Variable.withInt(formId)],
      readsFrom: {
        attachedDatabase.formAbilities,
        attachedDatabase.abilities,
      },
    ).get();
    return rows
        .map(
          (row) => AbilityRef(
            id: row.data['id'] as int,
            nameZh: row.data['name_zh_hans'] as String,
            nameEn: row.data['name_en'] as String,
            isHidden: (row.data['is_hidden'] as int) != 0,
          ),
        )
        .toList(growable: false);
  }

  /// 全部语言图鉴文本，按 generation_id + version_id 排序（zh 优先交给 UI）。
  Future<List<FlavorEntry>> getFlavorTexts(int speciesId) async {
    final rows = await customSelect(
      'SELECT ft.version_id, v.identifier AS version_identifier, '
      '       v.name_zh_hans AS version_name_zh, v.name_en AS version_name_en, '
      '       v.generation_id, ft.language, ft.flavor_text '
      'FROM flavor_texts ft JOIN versions v ON v.id = ft.version_id '
      'WHERE ft.species_id = ? '
      'ORDER BY v.generation_id ASC, ft.version_id ASC',
      variables: [Variable.withInt(speciesId)],
      readsFrom: {attachedDatabase.flavorTexts, attachedDatabase.versions},
    ).get();
    return rows
        .map(
          (row) => FlavorEntry(
            versionId: row.data['version_id'] as int,
            versionIdentifier: row.data['version_identifier'] as String,
            versionNameZh: row.data['version_name_zh'] as String? ?? '',
            versionNameEn: row.data['version_name_en'] as String,
            generationId: row.data['generation_id'] as int,
            language: row.data['language'] as String,
            text: row.data['flavor_text'] as String,
          ),
        )
        .toList(growable: false);
  }

  /// 该形态在 pokemon_form_moves 中出现过的版本组（去重，世代新→旧）。
  ///
  /// 同组多版本时 zh 标签取去重并集（如"朱/紫"），无官方简中回退英文。
  Future<List<VersionGroupRef>> getFormVersionGroups(int formId) async {
    final rows = await customSelect(
      'SELECT pfm.version_group AS id, MAX(v.generation_id) AS generation_id, '
      '       GROUP_CONCAT(DISTINCT v.name_zh_hans) AS zh_csv, '
      '       GROUP_CONCAT(DISTINCT v.name_en) AS en_csv '
      'FROM pokemon_form_moves pfm '
      'JOIN versions v ON v.version_group = pfm.version_group '
      'WHERE pfm.form_id = ? '
      'GROUP BY pfm.version_group '
      'ORDER BY generation_id DESC',
      variables: [Variable.withInt(formId)],
      readsFrom: {
        attachedDatabase.pokemonFormMoves,
        attachedDatabase.versions,
      },
    ).get();
    return rows
        .map(
          (row) => VersionGroupRef(
            id: row.data['id'] as String,
            labelZh: _versionGroupLabel(
              row.data['zh_csv'] as String?,
              row.data['en_csv'] as String?,
            ),
            generationId: row.data['generation_id'] as int,
          ),
        )
        .toList(growable: false);
  }

  Future<List<TypeRef>> getTypes() async {
    final rows = await select(attachedDatabase.types).get();
    return rows
        .map((r) => TypeRef(id: r.identifier, nameZh: r.nameZhHans))
        .toList(growable: false);
  }

  Future<List<GenerationRef>> getGenerations() async {
    final rows = await (select(attachedDatabase.generations)
          ..orderBy([(g) => OrderingTerm.asc(g.id)]))
        .get();
    return rows
        .map(
          (r) => GenerationRef(id: r.id, identifier: r.identifier, region: r.region),
        )
        .toList(growable: false);
  }

  Future<List<PokedexRef>> getPokedexes() async {
    final rows = await (select(attachedDatabase.pokedexes)
          ..orderBy([(d) => OrderingTerm.asc(d.id)]))
        .get();
    return rows
        .map(
          (r) => PokedexRef(
            id: r.id,
            identifier: r.identifier,
            nameZh: r.nameZhHans,
            generationId: r.generationId,
          ),
        )
        .toList(growable: false);
  }

  // ---- 内部 ----

  /// architecture.md §7 的 WHERE 组合（编号正则→整值等值；六语名称 LIKE；
  /// 世代 IN；属性 any/all 走默认形态 form_types；地区 EXISTS；编号范围；
  /// 特殊分类标志位）。
  (String, List<Variable>) _buildWhere(FilterState f) {
    final conditions = <String>[];
    final variables = <Variable>[];

    final q = f.query.trim();
    if (q.isNotEmpty) {
      final likeTerms = <String>[
        's.name_zh_hans LIKE ?',
        's.name_zh_hant LIKE ?',
        'LOWER(s.name_en) LIKE ?',
        's.name_ja LIKE ?',
        's.name_ja_hrkt LIKE ?',
        's.name_roomaji LIKE ?',
      ];
      final likeVariables = <Variable>[
        Variable.withString('%$q%'),
        Variable.withString('%$q%'),
        Variable.withString('%${q.toLowerCase()}%'),
        Variable.withString('%$q%'),
        Variable.withString('%$q%'),
        Variable.withString('%$q%'),
      ];
      final dexMatch = RegExp(r'^#?(\d{1,4})$').firstMatch(q);
      if (dexMatch != null) {
        // 去前导零：'001' / '#001' → 1
        final n = int.parse(dexMatch.group(1)!);
        conditions.add(
          '(s.national_dex = ? OR (${likeTerms.join(' OR ')}))',
        );
        variables
          ..add(Variable.withInt(n))
          ..addAll(likeVariables);
      } else {
        conditions.add('(${likeTerms.join(' OR ')})');
        variables.addAll(likeVariables);
      }
    }

    if (f.generations.isNotEmpty) {
      conditions.add(
        's.generation_id IN (${_placeholders(f.generations.length)})',
      );
      variables.addAll(f.generations.map(Variable.withInt));
    }

    if (f.typeIds.isNotEmpty) {
      final placeholders = _placeholders(f.typeIds.length);
      switch (f.typeMatchMode) {
        case TypeMatchMode.any:
          conditions.add(
            'EXISTS (SELECT 1 FROM form_types ft '
            'JOIN types t ON t.id = ft.type_id '
            'WHERE ft.form_id = df.id AND t.identifier IN ($placeholders))',
          );
          variables.addAll(f.typeIds.map(Variable.withString));
        case TypeMatchMode.all:
          conditions.add(
            '(SELECT COUNT(DISTINCT ft.type_id) FROM form_types ft '
            'JOIN types t ON t.id = ft.type_id '
            'WHERE ft.form_id = df.id AND t.identifier IN ($placeholders)) = ?',
          );
          variables
            ..addAll(f.typeIds.map(Variable.withString))
            ..add(Variable.withInt(f.typeIds.length));
      }
    }

    if (f.pokedexIds.isNotEmpty) {
      conditions.add(
        'EXISTS (SELECT 1 FROM species_dex_numbers d '
        'WHERE d.species_id = s.id AND '
        'd.pokedex_id IN (${_placeholders(f.pokedexIds.length)}))',
      );
      variables.addAll(f.pokedexIds.map(Variable.withInt));
    }

    if (f.dexMin != null) {
      conditions.add('s.national_dex >= ?');
      variables.add(Variable.withInt(f.dexMin!));
    }
    if (f.dexMax != null) {
      conditions.add('s.national_dex <= ?');
      variables.add(Variable.withInt(f.dexMax!));
    }

    for (final tag in f.tags) {
      switch (tag) {
        case SpecialTag.legendary:
          conditions.add('s.is_legendary = 1');
        case SpecialTag.mythical:
          conditions.add('s.is_mythical = 1');
        case SpecialTag.ultraBeast:
          conditions.add('s.is_ultra_beast = 1');
        case SpecialTag.mega:
          conditions.add(
            'EXISTS (SELECT 1 FROM forms fm '
            'WHERE fm.species_id = s.id AND fm.is_mega = 1)',
          );
        case SpecialTag.gmax:
          conditions.add(
            'EXISTS (SELECT 1 FROM forms fm '
            'WHERE fm.species_id = s.id AND fm.is_gmax = 1)',
          );
        case SpecialTag.regional:
          conditions.add(
            'EXISTS (SELECT 1 FROM forms fm '
            'WHERE fm.species_id = s.id AND fm.is_regional = 1)',
          );
      }
    }

    return (
      conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}',
      variables,
    );
  }

  PokemonSummary _mapPokemonSummary(QueryRow row) => PokemonSummary(
        speciesId: row.data['species_id'] as int,
        nationalDex: row.data['national_dex'] as int,
        nameZh: row.data['name_zh_hans'] as String,
        nameEn: row.data['name_en'] as String,
        nameJa: row.data['name_ja'] as String,
        typeIds: _typeIdsFromCsv(row.data['type_ids_csv'] as String?),
        thumbAsset: row.data['thumb_asset'] as String?,
        generationId: row.data['generation_id'] as int,
        isLegendary: (row.data['is_legendary'] as int) != 0,
        isMythical: (row.data['is_mythical'] as int) != 0,
        isUltraBeast: (row.data['is_ultra_beast'] as int) != 0,
      );
}

/// 学习集与招式详情。
@DriftAccessor()
class MoveDao extends DatabaseAccessor<PokedexDatabase> with _$MoveDaoMixin {
  MoveDao(super.attachedDatabase);

  /// 指定版本组的学习集：JOIN moves + types 一次取回全部条目，
  /// 按 (method 组序 level_up→machine→tutor→egg→other, level, move_id) 排序。
  ///
  /// [methods] 为 null 或空集合时表示不过滤学习方式。
  Future<List<MoveEntry>> getLearnset(
    int formId,
    String versionGroup, {
    Set<String>? methods,
  }) async {
    final filter = (methods == null || methods.isEmpty)
        ? ''
        : ' AND pfm.method IN (${_placeholders(methods.length)})';
    final variables = <Variable>[
      Variable.withInt(formId),
      Variable.withString(versionGroup),
      if (methods != null && methods.isNotEmpty)
        ...methods.map(Variable.withString),
    ];
    final rows = await customSelect(
      'SELECT pfm.method, pfm.level, m.id AS move_id, m.name_zh_hans, '
      '       m.name_en, t.identifier AS type_id, m.damage_class, m.power, '
      '       m.pp, m.accuracy '
      'FROM pokemon_form_moves pfm '
      'JOIN moves m ON m.id = pfm.move_id '
      'JOIN types t ON t.id = m.type_id '
      'WHERE pfm.form_id = ? AND pfm.version_group = ?$filter',
      variables: variables,
      readsFrom: {
        attachedDatabase.pokemonFormMoves,
        attachedDatabase.moves,
        attachedDatabase.types,
      },
    ).get();
    final entries = rows
        .map(
          (row) => MoveEntry(
            moveId: row.data['move_id'] as int,
            nameZh: row.data['name_zh_hans'] as String,
            nameEn: row.data['name_en'] as String,
            typeId: row.data['type_id'] as String,
            damageClass: row.data['damage_class'] as String,
            power: row.data['power'] as int?,
            pp: row.data['pp'] as int?,
            accuracy: row.data['accuracy'] as int?,
            level: row.data['level'] as int?,
            method: row.data['method'] as String,
            versionGroup: versionGroup,
          ),
        )
        .toList();
    entries.sort(_learnsetComparator);
    return entries;
  }

  Future<MoveDetail?> getMoveDetail(int moveId) async {
    final row = await customSelect(
      'SELECT m.id, m.name_zh_hans, m.name_en, m.name_ja, '
      '       t.identifier AS type_id, m.damage_class, m.power, m.pp, '
      '       m.accuracy, m.priority, m.effect_chance, m.effect_en, '
      '       m.flavor_zh_hans, m.generation_id '
      'FROM moves m JOIN types t ON t.id = m.type_id WHERE m.id = ?',
      variables: [Variable.withInt(moveId)],
      readsFrom: {attachedDatabase.moves, attachedDatabase.types},
    ).getSingleOrNull();
    if (row == null) return null;
    return MoveDetail(
      id: row.data['id'] as int,
      nameZh: row.data['name_zh_hans'] as String,
      nameEn: row.data['name_en'] as String,
      nameJa: row.data['name_ja'] as String,
      typeId: row.data['type_id'] as String,
      damageClass: row.data['damage_class'] as String,
      power: row.data['power'] as int?,
      pp: row.data['pp'] as int?,
      accuracy: row.data['accuracy'] as int?,
      priority: row.data['priority'] as int,
      effectChance: row.data['effect_chance'] as int?,
      effectEn: row.data['effect_en'] as String?,
      flavorZh: row.data['flavor_zh_hans'] as String?,
      generationId: row.data['generation_id'] as int,
    );
  }

  static int _methodRank(String method) => switch (method) {
        'level_up' => 0,
        'machine' => 1,
        'tutor' => 2,
        'egg' => 3,
        _ => 4,
      };

  static int _learnsetComparator(MoveEntry a, MoveEntry b) {
    final byMethod =
        _methodRank(a.method).compareTo(_methodRank(b.method));
    if (byMethod != 0) return byMethod;
    final byLevel =
        (a.level ?? 1 << 30).compareTo(b.level ?? 1 << 30);
    if (byLevel != 0) return byLevel;
    return a.moveId.compareTo(b.moveId);
  }
}

/// 进化链查询（树形组装在 repository 侧完成）。
@DriftAccessor()
class EvolutionDao extends DatabaseAccessor<PokedexDatabase>
    with _$EvolutionDaoMixin {
  EvolutionDao(super.attachedDatabase);

  /// species 所属进化链 id；无链返回 null。
  Future<int?> getEvolutionChainId(int speciesId) async {
    final row = await customSelect(
      'SELECT evolution_chain_id AS cid FROM species WHERE id = ?',
      variables: [Variable.withInt(speciesId)],
      readsFrom: {attachedDatabase.species},
    ).getSingleOrNull();
    return row?.data['cid'] as int?;
  }

  /// 一条链的全部进化边，附带 to 端 species 展示信息，按 to_species_id 排序。
  Future<List<EvolutionEdgeData>> getChainEdges(int chainId) async {
    final rows = await customSelect(
      'SELECT e.chain_id, e.from_species_id, e.to_species_id, e.trigger, '
      '       e.min_level, e.item, e.held_item, e.known_move, '
      '       e.known_move_type, e.location, e.time_of_day, e.gender, '
      '       e.min_happiness, e.min_affection, e.min_beauty, '
      '       e.relative_physical_stats, e.party_species, e.party_type, '
      '       e.trade_species, e.needs_overworld_rain, e.turn_upside_down, '
      '       ts.national_dex AS to_national_dex, '
      '       ts.name_zh_hans AS to_name_zh, '
      '       dft.thumb_asset AS to_thumb_asset '
      'FROM evolution_edges e '
      'JOIN species ts ON ts.id = e.to_species_id '
      'LEFT JOIN forms dft ON dft.species_id = ts.id AND dft.is_default = 1 '
      'WHERE e.chain_id = ? '
      'ORDER BY e.to_species_id ASC',
      variables: [Variable.withInt(chainId)],
      readsFrom: {
        attachedDatabase.evolutionEdges,
        attachedDatabase.species,
        attachedDatabase.forms,
      },
    ).get();
    return rows
        .map(
          (row) => EvolutionEdgeData(
            chainId: row.data['chain_id'] as int,
            fromSpeciesId: row.data['from_species_id'] as int?,
            toSpeciesId: row.data['to_species_id'] as int,
            trigger: row.data['trigger'] as String,
            toNationalDex: row.data['to_national_dex'] as int,
            toNameZh: row.data['to_name_zh'] as String,
            toThumbAsset: row.data['to_thumb_asset'] as String?,
            minLevel: row.data['min_level'] as int?,
            item: row.data['item'] as String?,
            heldItem: row.data['held_item'] as String?,
            knownMove: row.data['known_move'] as String?,
            knownMoveType: row.data['known_move_type'] as String?,
            location: row.data['location'] as String?,
            timeOfDay: row.data['time_of_day'] as String?,
            gender: row.data['gender'] as String?,
            minHappiness: row.data['min_happiness'] as int?,
            minAffection: row.data['min_affection'] as int?,
            minBeauty: row.data['min_beauty'] as int?,
            relativePhysicalStats:
                row.data['relative_physical_stats'] as String?,
            partySpecies: row.data['party_species'] as String?,
            partyType: row.data['party_type'] as String?,
            tradeSpecies: row.data['trade_species'] as String?,
            needsRain: (row.data['needs_overworld_rain'] as int) != 0,
            turnUpsideDown: (row.data['turn_upside_down'] as int) != 0,
          ),
        )
        .toList(growable: false);
  }
}

/// meta 键值表读取（schema 版本比对等）。
@DriftAccessor()
class MetaDao extends DatabaseAccessor<PokedexDatabase> with _$MetaDaoMixin {
  MetaDao(super.attachedDatabase);

  Future<String?> getMetaValue(String key) async {
    final row = await (select(attachedDatabase.meta)
          ..where((tbl) => tbl.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }
}

// ---- 文件内共享的小工具 ----

String _placeholders(int count) => List.filled(count, '?').join(', ');

List<String> _typeIdsFromCsv(String? csv) =>
    csv == null || csv.isEmpty ? const <String>[] : csv.split(',');

String _versionGroupLabel(String? zhCsv, String? enCsv) {
  var names = (zhCsv ?? '')
      .split(',')
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList();
  if (names.isEmpty) {
    names = (enCsv ?? '').split(',').where((name) => name.isNotEmpty).toSet().toList();
  }
  return names.join('/');
}
