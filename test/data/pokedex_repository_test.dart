import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_pokedex/data/database/pokedex_database.dart';
import 'package:fl_pokedex/data/repository/pokedex_repository_impl.dart';
import 'package:fl_pokedex/domain/models/filters.dart';
import 'package:fl_pokedex/domain/models/manifest.dart';
import 'package:fl_pokedex/domain/repositories/pokedex_repository.dart';
import 'package:fl_pokedex/features/pokedex/providers.dart'
    show primaryPokedexIdGroups;

import '../helpers/sqlite_loader.dart';

/// 直接对 assets/database/pokedex.db 只读开库，验证仓储 SQL 与数据契约
/// （AGENTS.md 构建校验 §8 的关键事实）。
void main() {
  loadSqliteForHostTests();

  late PokedexDatabase db;
  late PokedexRepository repo;

  setUp(() {
    db = PokedexDatabase(
      PokedexDatabase.readOnlyExecutor(File('assets/database/pokedex.db')),
    );
    repo = PokedexRepositoryImpl(
      db,
      // 数据层保持纯 Dart，manifest 读取由外部注入（宿主测试直接读文件）
      loadManifestJson: () async => jsonDecode(
            await File('assets/database/manifest.json').readAsString(),
          ) as Map<String, dynamic>,
    );
  });

  tearDown(() => db.close());

  group('queryPokemon 搜索（§7 WHERE 语义）', () {
    Future<List<int>> searchIds(String query) async {
      final items = await repo.queryPokemon(
        FilterState(query: query),
        limit: 30,
        offset: 0,
      );
      return items.map((item) => item.speciesId).toList();
    }

    test('中文"妙蛙种子"命中 #1 且带默认形态缩略图与属性', () async {
      final items = await repo.queryPokemon(
        const FilterState(query: '妙蛙种子'),
        limit: 10,
        offset: 0,
      );
      expect(items, isNotEmpty);
      expect(items.first.speciesId, 1);
      expect(items.first.nationalDex, 1);
      expect(items.first.nameZh, '妙蛙种子');
      expect(items.first.nameEn, 'Bulbasaur');
      expect(items.first.nameJa, 'フシギダネ');
      expect(items.first.typeIds, ['grass', 'poison']);
      expect(items.first.thumbAsset, 'assets/pokemon/thumb/1.webp');
      expect(items.first.generationId, 1);
    });

    test('英文 Bulbasaur / 日文片假名 / "001" / "#001" / 大小写 bulba', () async {
      expect(await searchIds('Bulbasaur'), contains(1));
      expect(await searchIds('フシギダネ'), contains(1));
      expect((await searchIds('001')).first, 1);
      expect((await searchIds('#001')).first, 1);
      expect(await searchIds('bulba'), contains(1)); // LOWER(name_en)
    });

    test('组合筛选：世代=3 + 水属性 + 关键词"龙"', () async {
      final f = const FilterState(
        query: '龙',
        generations: {3},
        typeIds: {'water'},
      );
      final items = await repo.queryPokemon(f, limit: 100, offset: 0);
      expect(items, isNotEmpty);
      for (final item in items) {
        expect(item.generationId, 3, reason: '${item.nameZh} 世代不符');
        expect(item.typeIds, contains('water'), reason: '${item.nameZh} 属性不符');
      }
      expect(items.map((e) => e.speciesId), containsAll([341, 342]));
      expect(await repo.countPokemon(f), items.length);
    });

    test('双属性 all 模式：草+毒 只有妙蛙种子家族等', () async {
      final f = const FilterState(
        typeIds: {'grass', 'poison'},
        typeMatchMode: TypeMatchMode.all,
      );
      final items = await repo.queryPokemon(f, limit: 100, offset: 0);
      expect(items, isNotEmpty);
      for (final item in items) {
        expect(item.typeIds, containsAll(['grass', 'poison']));
      }
    });

    test('mega 标签与编号范围筛选', () async {
      final megaCount = await repo.countPokemon(
        const FilterState(tags: {SpecialTag.mega}),
      );
      expect(megaCount, greaterThan(0));

      final ranged = await repo.queryPokemon(
        const FilterState(dexMin: 1, dexMax: 10),
        limit: 20,
        offset: 0,
      );
      expect(ranged, hasLength(10));
      expect(ranged.map((item) => item.nationalDex), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    });

    test('地区筛选：卡洛斯中央图鉴成员命中（含老世代成员与帕尼?)', () async {
      // 上游 kalos-central 含 153 只：既有御三家(650)也有老世代成员(1)
      final kalos = await repo.queryPokemon(
        const FilterState(pokedexIds: {12}), // kalos-central
        limit: 200,
        offset: 0,
      );
      final ids = kalos.map((item) => item.nationalDex).toSet();
      expect(ids, contains(1)); // 妙蛙种子（XY 可获得 → 入地区图鉴）
      expect(ids, contains(650)); // 哈力栗（中央图鉴 #1）
      expect(
        await repo.countPokemon(const FilterState(pokedexIds: {12})),
        kalos.length,
      );
    });

    test('分页 limit/offset 与总数 1025', () async {
      final total = await repo.countPokemon(const FilterState());
      expect(total, 1025);

      final page1 = await repo.queryPokemon(
        const FilterState(),
        limit: 10,
        offset: 0,
      );
      final page2 = await repo.queryPokemon(
        const FilterState(),
        limit: 10,
        offset: 10,
      );
      expect(page1, hasLength(10));
      expect(page2, hasLength(10));
      expect(page1.last.nationalDex, lessThan(page2.first.nationalDex));
      expect(
        page1.expand((item) => item.typeIds),
        everyElement(isA<String>()),
      );
    });
  });

  group('进化树', () {
    test('伊布(#133)：根节点 8 条出边，注册表含全部 9 个成员', () async {
      final tree = await repo.getEvolutionTree(133);
      expect(tree, isNotNull);
      expect(tree!.root.speciesId, 133);
      expect(tree.root.nationalDex, 133);
      expect(tree.root.nameZh, '伊布');
      expect(tree.root.children, hasLength(8));
      expect(
        tree.root.children.map((edge) => edge.trigger).toSet(),
        containsAll(['level-up', 'use-item']),
      );
      final memberIds = {133, 134, 135, 136, 196, 197, 470, 471, 700};
      expect(tree.nodesBySpeciesId.keys.toSet(), memberIds);
      // 每个注册表节点都有编号/简中名（含末段进化的展示信息）
      for (final id in memberIds) {
        final node = tree.nodesBySpeciesId[id]!;
        expect(node.nationalDex, id, reason: 'species $id 编号不符');
        expect(node.nameZh, isNotEmpty, reason: 'species $id 缺简中名');
      }
      expect(tree.nodesBySpeciesId[134]!.nameZh, '水伊布');
      expect(tree.nodesBySpeciesId[700]!.nameZh, '仙子伊布');
      // root 在注册表中的节点与 tree.root 一致
      expect(
        identical(tree.nodesBySpeciesId[133], tree.root),
        isTrue,
      );
    });

    test('土居忍士(#290)：shed 边到 #292 盔甲鸟?→土居忍士链存在', () async {
      final tree = await repo.getEvolutionTree(290);
      expect(tree, isNotNull);
      expect(tree!.root.speciesId, 290);
      final shed = tree.root.children
          .firstWhere((edge) => edge.trigger == 'shed', orElse: () => throw fail('缺少 shed 边'));
      expect(shed.fromSpeciesId, 290);
      expect(shed.toSpeciesId, 292); // 脱壳忍者
      expect(
        tree.root.children.map((edge) => edge.toSpeciesId),
        contains(291), // 铁面忍者（level-up）
      );
    });

    test('不存在的 species 返回 null（无链语义）', () async {
      // 当前上游数据 1025 只全部有 chain_id，用不存在的 id 验证 null 语义
      final tree = await repo.getEvolutionTree(99999);
      expect(tree, isNull);
    });

    test('形态级进化树：魔墙人偶(#122/#439/#866) 仅伽勒尔形态进化到踏冰人偶', () async {
      final tree = await repo.getEvolutionTree(122);
      expect(tree, isNotNull);
      expect(tree!.roots.map((r) => r.resolvedFormId).toList(), [439]);

      final mimeJr = tree.nodesByFormId[439]!;
      expect(mimeJr.children, hasLength(2));
      final toDefault =
          mimeJr.children.singleWhere((e) => e.resolvedToFormId == 122);
      final toGalar =
          mimeJr.children.singleWhere((e) => e.resolvedToFormId == 10168);
      expect(toDefault.region, isNull);
      expect(toDefault.knownMove, 'mimic');
      expect(toGalar.region, 'galar');
      expect(toGalar.knownMove, 'mimic');

      final defaultMime = tree.nodesByFormId[122]!;
      expect(defaultMime.formNameZh, isNull);
      expect(defaultMime.typeIds, ['psychic', 'fairy']);
      expect(defaultMime.children, isEmpty);

      final galarMime = tree.nodesByFormId[10168]!;
      expect(galarMime.formNameZh, '伽勒尔的样子');
      expect(galarMime.typeIds, ['ice', 'psychic']);
      expect(galarMime.thumbAsset, 'assets/pokemon/full/10168.webp');
      expect(galarMime.children, hasLength(1));
      expect(galarMime.children.single.resolvedToFormId, 866);
      expect(galarMime.children.single.minLevel, 42);
    });

    test('多根并行与仅特殊形态进化：呆呆兽 / 喵喵 / 大葱鸭 / 武道熊师', () async {
      final slowpoke = await repo.getEvolutionTree(79);
      expect(slowpoke!.roots.map((r) => r.resolvedFormId).toList(), [79, 10164]);
      expect(
        slowpoke.nodesByFormId[79]!.children.map((e) => e.resolvedToFormId),
        containsAll([80, 199]),
      );
      expect(
        slowpoke.nodesByFormId[10164]!.children.map((e) => e.resolvedToFormId),
        containsAll([10165, 10172]),
      );

      final meowth = await repo.getEvolutionTree(52);
      expect(
        meowth!.roots.map((r) => r.resolvedFormId).toList(),
        [52, 10107, 10161],
      );
      expect(meowth.nodesByFormId[52]!.children.single.resolvedToFormId, 53);
      expect(
        meowth.nodesByFormId[10107]!.children.single.resolvedToFormId,
        10108,
      );
      expect(
        meowth.nodesByFormId[10161]!.children.single.resolvedToFormId,
        863,
      );

      final farfetchd = await repo.getEvolutionTree(83);
      expect(
        farfetchd!.roots.map((r) => r.resolvedFormId).toList(),
        [10166],
      );
      expect(farfetchd.nodesByFormId.containsKey(83), isFalse);
      expect(
        farfetchd.nodesByFormId[10166]!.children.single.resolvedToFormId,
        865,
      );

      final urshifu = await repo.getEvolutionTree(891);
      expect(urshifu!.nodesByFormId[892]!.formNameZh, '一击流');
      expect(urshifu.nodesByFormId[10191]!.formNameZh, '连击流');
    });
  });

  group('学习集', () {
    test('皮卡丘(#25) sword-shield：machine>0 且 level_up>0，排序符合组序', () async {
      final moves = await repo.getLearnset(25, 'sword-shield');
      final byMethod = <String, int>{};
      for (final move in moves) {
        byMethod[move.method] = (byMethod[move.method] ?? 0) + 1;
      }
      expect(byMethod['machine'] ?? 0, greaterThan(0));
      expect(byMethod['level_up'] ?? 0, greaterThan(0));

      // 排序：method 组序 level_up→machine→tutor→egg→other，组内 level 升序
      int rank(String method) => switch (method) {
            'level_up' => 0,
            'machine' => 1,
            'tutor' => 2,
            'egg' => 3,
            _ => 4,
          };
      for (var i = 1; i < moves.length; i++) {
        final prev = moves[i - 1];
        final curr = moves[i];
        final prevRank = rank(prev.method);
        final currRank = rank(curr.method);
        final prevLevel = prev.level ?? 1 << 30;
        final currLevel = curr.level ?? 1 << 30;
        final inOrder = prevRank < currRank ||
            (prevRank == currRank &&
                (prevLevel < currLevel ||
                    (prevLevel == currLevel && prev.moveId <= curr.moveId)));
        expect(
          inOrder,
          isTrue,
          reason: '排序错误：${prev.moveId}(${prev.method}/${prev.level}) '
              '应不晚于 ${curr.moveId}(${curr.method}/${curr.level})',
        );
      }

      // methods 过滤参数
      final onlyMachine = await repo.getLearnset(
        25,
        'sword-shield',
        methods: {'machine'},
      );
      expect(onlyMachine.map((m) => m.method), everyElement('machine'));
      expect(onlyMachine, isNotEmpty);
    });

    test('getFormVersionGroups(#25)：9 组、世代新→旧，首为 scarlet-violet', () async {
      final groups = await repo.getFormVersionGroups(25);
      expect(groups.map((g) => g.id).toList(), [
        'scarlet-violet',
        'sword-shield',
        'ultra-sun-ultra-moon',
        'omega-ruby-alpha-sapphire',
        'black-2-white-2',
        'heartgold-soulsilver',
        'emerald',
        'crystal',
        'yellow',
      ]);
      expect(groups.first.generationId, 9);
      expect(groups.first.labelZh, contains('朱'));
      expect(
        groups.firstWhere((g) => g.id == 'sword-shield').labelZh,
        '剑/盾',
      );
      expect(groups.firstWhere((g) => g.id == 'yellow').generationId, 1);
    });
  });

  group('招式伤害分类（A2 回归：上游 move_damage_classes 1=status/2=physical/3=special）', () {
    test('抽样：tackle=physical(威力40)、thunderbolt=special(威力90)、growl/hypnosis=status',
        () async {
      final tackle = await repo.getMoveDetail(33);
      expect(tackle, isNotNull);
      expect(tackle!.damageClass, 'physical', reason: '撞击是物理招式');
      expect(tackle.power, 40);

      final thunderbolt = await repo.getMoveDetail(85);
      expect(thunderbolt, isNotNull);
      expect(thunderbolt!.damageClass, 'special', reason: '十万伏特是特殊招式');
      expect(thunderbolt.power, 90);

      final growl = await repo.getMoveDetail(45);
      expect(growl!.damageClass, 'status', reason: '叫声是变化招式');

      final hypnosis = await repo.getMoveDetail(95);
      expect(hypnosis!.damageClass, 'status', reason: '催眠术是变化招式');
    });

    test('三类分布与上游 CSV 一致：status 277 / physical 395 / special 266', () async {
      // 回归锚（上游 @de6760be）；新增的「归无之光」为特殊招式。
      final rows = await db
          .customSelect(
            'SELECT damage_class, COUNT(*) AS n FROM moves GROUP BY damage_class',
          )
          .get();
      final dist = {
        for (final row in rows)
          row.data['damage_class'] as String: row.data['n'] as int,
      };
      expect(dist['status'], 277);
      expect(dist['physical'], 395);
      expect(dist['special'], 266);
      expect(dist.values.fold<int>(0, (sum, n) => sum + n), 938);
    });
  });

  group('形态', () {
    test('喷火龙(#6)：≥3 个形态且超级进化存在、默认形态唯一', () async {
      final forms = await repo.getForms(6);
      expect(forms.length, greaterThanOrEqualTo(3));
      expect(forms.where((form) => form.isDefault), hasLength(1));
      expect(forms.any((form) => form.isMega), isTrue);
      expect(forms.any((form) => form.isGmax), isTrue);

      // form_order 排序：默认形态在前
      expect(forms.first.isDefault, isTrue);
      expect(forms.first.formId, 6);
      expect(forms.first.typeIds, ['fire', 'flying']);
    });

    test('皮卡丘(#25) 默认形态身高体重：heightM=0.4、weightKg=6.0', () async {
      final forms = await repo.getForms(25);
      final def = forms.firstWhere((form) => form.isDefault);
      expect(def.heightM, 0.4); // forms.height = 4 dm
      expect(def.weightKg, 6.0); // forms.weight = 60 hg
    });
  });

  group('特性', () {
    test('茂盛(overgrow)：descriptionZh 非空且 descriptionEn 非空', () async {
      final abilities = await repo.getFormAbilities(1); // 妙蛙种子默认形态
      final overgrow = abilities.firstWhere((a) => !a.isHidden);
      expect(overgrow.nameEn, 'Overgrow');
      expect(overgrow.descriptionZh, isNotNull);
      expect(overgrow.descriptionZh, isNotEmpty);
      expect(overgrow.descriptionEn, isNotNull);
      expect(overgrow.descriptionEn, isNotEmpty);
    });
  });

  group('C2：species 信息与批量摘要', () {
    test('getSpeciesInfo(1)：genusZh == "种子宝可梦"', () async {
      final info = await repo.getSpeciesInfo(1);
      expect(info.speciesId, 1);
      expect(info.nationalDex, 1);
      expect(info.generationId, 1);
      expect(info.genusZh, '种子宝可梦');
      expect(info.genusEn, 'Seed Pokémon');
    });

    test('getPokemonSummaries([6,1,9999,25]) 按入参顺序返回 [6,1,25]', () async {
      final summaries = await repo.getPokemonSummaries([6, 1, 9999, 25]);
      expect(summaries.map((s) => s.speciesId).toList(), [6, 1, 25]);
      final bulba = summaries.firstWhere((s) => s.speciesId == 1);
      expect(bulba.nameZh, '妙蛙种子');
      expect(bulba.typeIds, ['grass', 'poison']);

      // 空入参安全
      expect(await repo.getPokemonSummaries(const []), isEmpty);
    });
  });

  group('图鉴文本', () {
    test('皮卡丘(#25) 存在官方简中图鉴文本（剑/盾与朱/紫版本）', () async {
      final flavors = await repo.getFlavorTexts(25);
      final zhHans = flavors
          .where((entry) => entry.language == 'zh_hans')
          .toList();
      expect(zhHans, isNotEmpty);
      // 上游 #1733 补齐 Switch 时代图鉴文本：剑/盾之外，朱/紫也有官方简中。
      expect(
        zhHans.map((entry) => entry.versionIdentifier),
        containsAll(['sword', 'shield', 'scarlet', 'violet']),
      );
      // 同一版本的中文和英文说明应并存。
      expect(
        flavors
            .where((entry) => entry.language == 'en')
            .map((entry) => entry.versionIdentifier),
        containsAll(['scarlet', 'violet']),
      );
      expect(flavors.every((entry) => entry.text.isNotEmpty), isTrue);
      // 排序：generation_id 升序
      final generations = flavors.map((entry) => entry.generationId).toList();
      expect(generations, equals(List.of(generations)..sort()));
    });

    test('新叶喵(#906)：朱/紫官方 zh_hans、zh_hant 与英文文本并存', () async {
      final flavors = await repo.getFlavorTexts(906);
      for (final version in const ['scarlet', 'violet']) {
        expect(
          flavors
              .where((entry) => entry.versionIdentifier == version)
              .map((entry) => entry.language),
          containsAll(const ['zh_hans', 'zh_hant', 'en']),
          reason: '$version 应保留英文并含官方简繁中文图鉴文本',
        );
      }
    });

    test('妙蛙种子(#1)：老版本存在无 zh_hans 的条目（en 有）', () async {
      final flavors = await repo.getFlavorTexts(1);
      final redEntries = flavors
          .where((entry) => entry.versionIdentifier == 'red')
          .toList();
      expect(redEntries, isNotEmpty);
      expect(
        redEntries.map((entry) => entry.language),
        everyElement(isNot('zh_hans')),
      );
      expect(redEntries.map((entry) => entry.language), contains('en'));
      // 新版本有简中（Let's Go 起）
      expect(
        flavors.any((entry) =>
            entry.language == 'zh_hans' && entry.versionIdentifier == 'sword'),
        isTrue,
      );
    });
  });

  group('地区形态专属说明（form_flavor_texts，data-contract §6）', () {
    test('呆呆兽(#79) 伽勒尔形态(10164)：剑/盾简中文本可读', () async {
      final forms = await repo.getForms(79);
      final galarForm = forms.singleWhere((form) => form.formIdentifier == 'galar');
      expect(galarForm.isRegional, isTrue);
      expect(galarForm.formId, 10164);

      final flavors = await repo.getFormFlavorTexts(galarForm.formId);
      final swordZh = flavors.firstWhere(
        (entry) =>
            entry.versionIdentifier == 'sword' && entry.language == 'zh_hans',
      );
      final shieldZh = flavors.firstWhere(
        (entry) =>
            entry.versionIdentifier == 'shield' && entry.language == 'zh_hans',
      );
      expect(swordZh.text, isNotEmpty);
      expect(shieldZh.text, isNotEmpty);
      // 剑/盾地区图鉴登记的是伽勒尔形态：文本描述伽勒尔的样子
      // （呆尾巴诱饵是伽勒尔形态特有习性，与 species 级文本不同）。
      expect(swordZh.text, isNot(shieldZh.text));
    });

    test('呆呆兽(#79) species 级：剑/盾行已剔除，lets-go 仍在', () async {
      final flavors = await repo.getFlavorTexts(79);
      final versionIds = flavors.map((entry) => entry.versionIdentifier).toSet();
      expect(versionIds.intersection(const {'sword', 'shield'}), isEmpty);
      expect(versionIds, containsAll(['lets-go-pikachu', 'lets-go-eevee']));
      // lets-go 简中文本描述默认形态（关都图鉴）。
      final letsGoZh = flavors.firstWhere(
        (entry) =>
            entry.versionIdentifier == 'lets-go-pikachu' &&
            entry.language == 'zh_hans',
      );
      expect(letsGoZh.text, contains('非常呆'));
    });

    test('喵喵(#52)：sun/moon→阿罗拉形态、剑/盾→伽勒尔形态', () async {
      final forms = await repo.getForms(52);
      final alola = forms.singleWhere((form) => form.formIdentifier == 'alola');
      final galar = forms.singleWhere((form) => form.formIdentifier == 'galar');

      final alolaVersions = (await repo.getFormFlavorTexts(alola.formId))
          .map((entry) => entry.versionIdentifier)
          .toSet();
      expect(alolaVersions,
          containsAll(['sun', 'moon', 'ultra-sun', 'ultra-moon']));
      final galarVersions = (await repo.getFormFlavorTexts(galar.formId))
          .map((entry) => entry.versionIdentifier)
          .toSet();
      expect(galarVersions, containsAll(['sword', 'shield']));

      // species 级不保留这些版本的行。
      final speciesVersions =
          (await repo.getFlavorTexts(52)).map((e) => e.versionIdentifier).toSet();
      expect(
        speciesVersions.intersection(const {
          'sun', 'moon', 'ultra-sun', 'ultra-moon', 'sword', 'shield',
        }),
        isEmpty,
      );
    });

    test('非地区形态无专属文本：getFormFlavorTexts(1) 返回空列表', () async {
      expect(await repo.getFormFlavorTexts(1), isEmpty);
    });

    test('外键可解析：form_flavor_texts.form_id 全部指向 is_regional 形态',
        () async {
      final rows = await db.customSelect(
        'SELECT COUNT(*) AS n FROM form_flavor_texts x '
        'LEFT JOIN forms f ON f.id = x.form_id '
        'WHERE f.id IS NULL OR f.is_regional <> 1',
      ).getSingle();
      expect(rows.data['n'] as int, 0);
    });
  });

  group('基础引用', () {
    test('getTypes / getGenerations / getPokedexes', () async {
      final types = await repo.getTypes();
      final fire = types.firstWhere((t) => t.id == 'fire');
      expect(fire.nameZh, isNotEmpty);
      expect(types.any((t) => t.id == 'water'), isTrue);

      final generations = await repo.getGenerations();
      expect(generations, hasLength(9));
      expect(generations.first.id, 1);

      final pokedexes = await repo.getPokedexes();
      expect(pokedexes.any((d) => d.identifier == 'kanto'), isTrue);
      expect(pokedexes.first.nameZh, isNotEmpty);
    });
  });

  group('地区白名单分组对齐随包 DB（providers.primaryPokedexIdGroups 防漂移）', () {
    test('18 个 identifier 全部存在于 pokedexes 表且总数恰 18', () async {
      var hits = 0;
      for (final group in primaryPokedexIdGroups) {
        for (final identifier in group) {
          final rows = await db
              .customSelect(
                'SELECT id FROM pokedexes WHERE identifier = ?',
                variables: [Variable.withString(identifier)],
              )
              .get();
          expect(
            rows,
            isNotEmpty,
            reason: '白名单 identifier "$identifier" 不在随包 DB pokedexes 表',
          );
          hits += rows.length;
        }
      }
      // 恰 18 行：任一侧漂移（DB 改名 / 白名单手改）都会在此变红。
      expect(hits, 18);
    });

    test('10 组映射到 DB 后 pokedex id 两两不相交', () async {
      Future<Set<int>> idsOf(List<String> identifiers) async {
        final placeholders = List.filled(identifiers.length, '?').join(', ');
        final rows = await db
            .customSelect(
              'SELECT id FROM pokedexes WHERE identifier IN ($placeholders)',
              variables: identifiers.map(Variable.withString).toList(),
            )
            .get();
        return rows.map((row) => row.data['id'] as int).toSet();
      }

      final seen = <int>{};
      for (final group in primaryPokedexIdGroups) {
        final ids = await idsOf(group);
        expect(ids, isNotEmpty, reason: '分组 $group 在 DB 中无任何行');
        expect(
          ids.intersection(seen),
          isEmpty,
          reason: '分组 $group 与先前分组的 pokedex id 相交：${ids.intersection(seen)}',
        );
        seen.addAll(ids);
      }
      expect(seen, hasLength(18));
    });

    test('地区芯片=组内并集：卡洛斯 457 只、关都 153 只（含美录坦家族）',
        () async {
      Future<int> unionCount(List<String> identifiers) async {
        final placeholders = List.filled(identifiers.length, '?').join(', ');
        final row = await db
            .customSelect(
              'SELECT COUNT(DISTINCT d.species_id) AS n '
              'FROM species_dex_numbers d '
              'JOIN pokedexes p ON p.id = d.pokedex_id '
              'WHERE p.identifier IN ($placeholders)',
              variables: identifiers.map(Variable.withString).toList(),
            )
            .getSingle();
        return row.data['n'] as int;
      }

      expect(await unionCount(primaryPokedexIdGroups[5]), 457); // 卡洛斯
      expect(await unionCount(primaryPokedexIdGroups[0]), 153); // 关都
      // letsgo-kanto 并入关都的意义：美录坦(808)/美录梅塔(809) 仅
      // 登记于 Let's Go 图鉴。
      final meltan = await db
          .customSelect(
            "SELECT COUNT(DISTINCT d.species_id) AS n "
            "FROM species_dex_numbers d "
            "JOIN pokedexes p ON p.id = d.pokedex_id "
            "WHERE p.identifier = 'letsgo-kanto' AND d.species_id IN (808, 809)",
          )
          .getSingle();
      expect(meltan.data['n'] as int, 2);
    });
  });

  test('getManifest 解析成功且 pokemonCount=1025', () async {
    final manifest = await repo.getManifest();
    expect(manifest, isA<DataManifest>());
    expect(manifest.schemaVersion, 6);
    expect(manifest.pokemonCount, 1025);
    expect(manifest.learnsetVersionGroups, contains('sword-shield'));
    expect(manifest.upstreamRevision, contains('pokeapi'));
  });

  group('检索增强：俗名 / 拼音 / 模糊 / 标签 / 分类 / 任意形态属性', () {
    test('俗名旧译命中并带别名提示', () async {
      final cases = <(String query, int expectId, String expectHint)>[
        ('比雕', 18, '别名：比雕'),
        ('乘龙', 131, '别名：乘龙'),
        ('血翼飞龙', 373, '别名：血翼飞龙'),
        ('裂空座', 384, '别名：裂空座'),
        ('谜拟Q', 778, '别名：谜拟Q'),
        ('3D龙', 137, '别名：3D龙'),
      ];
      for (final (q, id, hint) in cases) {
        final items = await repo.queryPokemon(
          FilterState(query: q),
          limit: 10,
          offset: 0,
        );
        expect(items, isNotEmpty, reason: '搜「$q」无结果');
        expect(items.first.speciesId, id, reason: '搜「$q」首位应为 #$id');
        expect(items.first.matchHint, hint, reason: '搜「$q」提示不符');
      }
    });

    test('拼音全拼与首字母搜索', () async {
      final bd = await repo.queryPokemon(
        const FilterState(query: 'bd'),
        limit: 10,
        offset: 0,
      );
      expect(bd.first.speciesId, 18);
      expect(bd.first.matchHint, '别名：比雕');

      final bidiao = await repo.queryPokemon(
        const FilterState(query: 'bidiao'),
        limit: 10,
        offset: 0,
      );
      expect(bidiao.first.speciesId, 18);

      final dbn = await repo.queryPokemon(
        const FilterState(query: 'dbn'),
        limit: 10,
        offset: 0,
      );
      expect(dbn.first.speciesId, 18);

      final pkq = await repo.queryPokemon(
        const FilterState(query: 'pkq'),
        limit: 10,
        offset: 0,
      );
      expect(pkq.first.speciesId, 25);
    });

    test('非连续子序列、无序、编辑距离与多词交集', () async {
      final daNiao = await repo.queryPokemon(
        const FilterState(query: '大鸟'),
        limit: 20,
        offset: 0,
      );
      expect(daNiao.first.speciesId, 567); // 含连续子串「大鸟」（始祖大鸟）
      expect(daNiao.map((e) => e.speciesId), contains(18)); // 非连续子序列命中大比鸟

      final miaoZi = await repo.queryPokemon(
        const FilterState(query: '妙子'),
        limit: 10,
        offset: 0,
      );
      expect(miaoZi.first.speciesId, 1); // 非连续子序列：妙蛙种子

      final penLong = await repo.queryPokemon(
        const FilterState(query: '喷龙'),
        limit: 20,
        offset: 0,
      );
      expect(penLong.first.speciesId, 6);

      final unordered = await repo.queryPokemon(
        const FilterState(query: '鸟比'),
        limit: 20,
        offset: 0,
      );
      expect(unordered.any((e) => e.speciesId == 18), isTrue);

      final pikacu = await repo.queryPokemon(
        const FilterState(query: 'pikacu'),
        limit: 10,
        offset: 0,
      );
      expect(pikacu.first.speciesId, 25);

      final alolaVulpix = await repo.queryPokemon(
        const FilterState(query: '阿罗拉 六尾'),
        limit: 10,
        offset: 0,
      );
      expect(alolaVulpix.map((e) => e.speciesId), [37]);

      final fossilBirds = await repo.queryPokemon(
        const FilterState(query: '化石 鸟'),
        limit: 20,
        offset: 0,
      );
      expect(fossilBirds.map((e) => e.speciesId), containsAll([566, 567]));
    });

    test('检索标签精确计数与究极异兽修复回归', () async {
      expect(
        await repo.countPokemon(const FilterState(tags: {SpecialTag.fossil})),
        25,
      );
      expect(
        await repo.countPokemon(const FilterState(tags: {SpecialTag.paradox})),
        22,
      );
      expect(
        await repo.countPokemon(const FilterState(tags: {SpecialTag.starter})),
        81,
      );
      expect(
        await repo.countPokemon(
          const FilterState(tags: {SpecialTag.pseudoLegendary}),
        ),
        30,
      );
      expect(
        await repo.countPokemon(const FilterState(tags: {SpecialTag.baby})),
        19,
      );

      final ubs = await repo.queryPokemon(
        const FilterState(tags: {SpecialTag.ultraBeast}),
        limit: 50,
        offset: 0,
      );
      final ubIds = ubs.map((e) => e.speciesId).toSet();
      expect(ubIds, hasLength(11));
      expect(ubIds, containsAll([803, 804]));
      expect(ubIds, isNot(anyElement(isIn([807, 808]))));

      final aerodactylInfo = await repo.getSpeciesInfo(142);
      expect(aerodactylInfo.tags, contains(SpecialTag.fossil));
    });

    test('搜索框检索标签词（化石 / 御三家 / 准神）直接命中', () async {
      expect(
        await repo.countPokemon(const FilterState(query: '化石')),
        25,
      );
      final starters = await repo.queryPokemon(
        const FilterState(query: '御三家'),
        limit: 100,
        offset: 0,
      );
      expect(starters, hasLength(81));

      final pseudos = await repo.queryPokemon(
        const FilterState(query: '准神'),
        limit: 50,
        offset: 0,
      );
      expect(pseudos, hasLength(30));
    });

    test('图鉴分类 genus 精确筛选（含英文回退分类）', () async {
      final birds = await repo.queryPokemon(
        const FilterState(genus: '鸟宝可梦'),
        limit: 20,
        offset: 0,
      );
      expect(birds.map((e) => e.speciesId), [17, 18]);

      final matcha = await repo.queryPokemon(
        const FilterState(genus: 'Matcha Pokémon'),
        limit: 20,
        offset: 0,
      );
      expect(matcha.map((e) => e.speciesId), [1012, 1013]);
    });

    test('任意形态属性筛选与同形态 all 约束（不跨形态错配）', () async {
      final dragons = await repo.queryPokemon(
        const FilterState(typeIds: {'dragon'}),
        limit: 200,
        offset: 0,
      );
      final charizard = dragons.firstWhere((e) => e.speciesId == 6);
      expect(charizard.matchHint, '形态：超级喷火龙Ｘ');

      final ice = await repo.queryPokemon(
        const FilterState(typeIds: {'ice'}),
        limit: 200,
        offset: 0,
      );
      final vulpix = ice.firstWhere((e) => e.speciesId == 37);
      expect(vulpix.matchHint, '形态：阿罗拉的样子');

      // 喷火龙默认/Mega Y 为火+飞，Mega X 为火+龙，不存在同一形态兼具飞+龙。
      final flyingAndDragon = await repo.queryPokemon(
        const FilterState(
          typeIds: {'flying', 'dragon'},
          typeMatchMode: TypeMatchMode.all,
        ),
        limit: 100,
        offset: 0,
      );
      final fdIds = flyingAndDragon.map((e) => e.speciesId).toSet();
      expect(fdIds, containsAll([149, 384]));
      expect(fdIds, isNot(contains(6)));
    });
  });
}
