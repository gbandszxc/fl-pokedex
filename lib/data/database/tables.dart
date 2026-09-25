// pokedex.db 全部 17 张表的 drift 定义。
//
// 与 docs/data-contract.md §3 的 DDL 逐字对齐：表名用 `tableName` 覆写、
// 列名用 `.named()` 显式 snake_case 命名；复合主键表通过 `primaryKey`
// 覆写声明。
//
// 说明：架构文档 §6 写的 `@Table(name:)` / `@ColumnInfo(name:)` 在
// drift 2.28 中不存在（`Table` 无 name 参数、无 ColumnInfo 类型），
// 这里用该版本官方等价写法，命名结果与契约 DDL 完全一致。
//
// 注意：数据库文件由 tools/data_builder 预先生成，drift 在运行时
// **不会**执行这里的 CREATE 语句（见 PokedexDatabase 的打开策略），
// 本文件只负责把既有 schema 映射为强类型查询。
import 'package:drift/drift.dart';

/// meta(key TEXT PRIMARY KEY, value TEXT NOT NULL)
@DataClassName('MetaRow')
class Meta extends Table {
  @override
  String get tableName => 'meta';

  TextColumn get key => text().named('key')();

  TextColumn get value => text().named('value')();

  @override
  Set<Column> get primaryKey => {key};
}

/// generations(id INTEGER PRIMARY KEY, identifier TEXT NOT NULL UNIQUE, region TEXT NOT NULL)
@DataClassName('GenerationsRow')
class Generations extends Table {
  @override
  String get tableName => 'generations';

  IntColumn get id => integer().named('id')();

  TextColumn get identifier => text().named('identifier')();

  TextColumn get region => text().named('region')();
}

/// types(id INTEGER PRIMARY KEY, identifier, name_zh_hans, name_zh_hant, name_en, name_ja)
@DataClassName('TypesRow')
class Types extends Table {
  @override
  String get tableName => 'types';

  IntColumn get id => integer().named('id')();

  TextColumn get identifier => text().named('identifier')();

  TextColumn get nameZhHans => text().named('name_zh_hans')();

  TextColumn get nameZhHant => text().named('name_zh_hant')();

  TextColumn get nameEn => text().named('name_en')();

  TextColumn get nameJa => text().named('name_ja')();
}

/// abilities(id, identifier, name_zh_hans, name_en, name_ja, generation_id,
///           text_zh_hans?, text_en?)
@DataClassName('AbilitiesRow')
class Abilities extends Table {
  @override
  String get tableName => 'abilities';

  IntColumn get id => integer().named('id')();

  TextColumn get identifier => text().named('identifier')();

  TextColumn get nameZhHans => text().named('name_zh_hans')();

  TextColumn get nameEn => text().named('name_en')();

  TextColumn get nameJa => text().named('name_ja')();

  IntColumn get generationId => integer().named('generation_id')();

  TextColumn get textZhHans => text().nullable().named('text_zh_hans')();

  TextColumn get textEn => text().nullable().named('text_en')();
}

/// moves(id, identifier, generation_id, type_id, damage_class, power?, pp?,
///       accuracy?, priority, target?, effect_chance?, name_zh_hans, name_en,
///       name_ja, effect_en?, flavor_zh_hans?)
@DataClassName('MovesRow')
class Moves extends Table {
  @override
  String get tableName => 'moves';

  IntColumn get id => integer().named('id')();

  TextColumn get identifier => text().named('identifier')();

  IntColumn get generationId => integer().named('generation_id')();

  IntColumn get typeId => integer().named('type_id')();

  TextColumn get damageClass => text().named('damage_class')();

  IntColumn get power => integer().nullable().named('power')();

  IntColumn get pp => integer().nullable().named('pp')();

  IntColumn get accuracy => integer().nullable().named('accuracy')();

  IntColumn get priority => integer().named('priority')();

  TextColumn get target => text().nullable().named('target')();

  IntColumn get effectChance => integer().nullable().named('effect_chance')();

  TextColumn get nameZhHans => text().named('name_zh_hans')();

  TextColumn get nameEn => text().named('name_en')();

  TextColumn get nameJa => text().named('name_ja')();

  TextColumn get effectEn => text().nullable().named('effect_en')();

  TextColumn get flavorZhHans => text().nullable().named('flavor_zh_hans')();
}

/// species(id, national_dex, generation_id, 六语种名称, genus, 三个分类标志位,
///         is_baby, evolution_chain_id?, 捕获/孵蛋等生态列)
@DataClassName('SpeciesRow')
class Species extends Table {
  @override
  String get tableName => 'species';

  IntColumn get id => integer().named('id')();

  IntColumn get nationalDex => integer().named('national_dex')();

  IntColumn get generationId => integer().named('generation_id')();

  TextColumn get nameZhHans => text().named('name_zh_hans')();

  TextColumn get nameZhHant => text().named('name_zh_hant')();

  TextColumn get nameEn => text().named('name_en')();

  TextColumn get nameJa => text().named('name_ja')();

  TextColumn get nameJaHrkt => text().named('name_ja_hrkt')();

  TextColumn get nameRoomaji => text().nullable().named('name_roomaji')();

  TextColumn get genusZhHans => text().nullable().named('genus_zh_hans')();

  TextColumn get genusEn => text().nullable().named('genus_en')();

  BoolColumn get isLegendary => boolean().named('is_legendary')();

  BoolColumn get isMythical => boolean().named('is_mythical')();

  BoolColumn get isUltraBeast => boolean().named('is_ultra_beast')();

  BoolColumn get isBaby => boolean().named('is_baby')();

  IntColumn get evolutionChainId =>
      integer().nullable().named('evolution_chain_id')();

  IntColumn get captureRate => integer().nullable().named('capture_rate')();

  IntColumn get baseHappiness =>
      integer().nullable().named('base_happiness')();

  IntColumn get genderRate => integer().nullable().named('gender_rate')();

  IntColumn get hatchCounter =>
      integer().nullable().named('hatch_counter')();

  TextColumn get growthRate => text().nullable().named('growth_rate')();

  TextColumn get eggGroup1 => text().nullable().named('egg_group_1')();

  TextColumn get eggGroup2 => text().nullable().named('egg_group_2')();

  TextColumn get color => text().nullable().named('color')();

  TextColumn get shape => text().nullable().named('shape')();

  TextColumn get habitat => text().nullable().named('habitat')();
}

/// forms(id, species_id, form_identifier?, form_name_zh, form_name_en,
///       is_default / is_mega / is_gmax / is_regional / is_battle_only,
///       form_order, height?, weight?, base_experience?,
///       has_gender_difference, artwork_asset?, thumb_asset?)
@DataClassName('FormsRow')
class Forms extends Table {
  @override
  String get tableName => 'forms';

  IntColumn get id => integer().named('id')();

  IntColumn get speciesId => integer().named('species_id')();

  TextColumn get formIdentifier =>
      text().nullable().named('form_identifier')();

  TextColumn get formNameZh => text().named('form_name_zh')();

  TextColumn get formNameEn => text().named('form_name_en')();

  BoolColumn get isDefault => boolean().named('is_default')();

  BoolColumn get isMega => boolean().named('is_mega')();

  BoolColumn get isGmax => boolean().named('is_gmax')();

  BoolColumn get isRegional => boolean().named('is_regional')();

  BoolColumn get isBattleOnly => boolean().named('is_battle_only')();

  IntColumn get formOrder => integer().named('form_order')();

  IntColumn get height => integer().nullable().named('height')();

  IntColumn get weight => integer().nullable().named('weight')();

  IntColumn get baseExperience =>
      integer().nullable().named('base_experience')();

  BoolColumn get hasGenderDifference =>
      boolean().named('has_gender_difference')();

  TextColumn get artworkAsset =>
      text().nullable().named('artwork_asset')();

  TextColumn get thumbAsset => text().nullable().named('thumb_asset')();
}

/// form_types(form_id, slot, type_id, PRIMARY KEY(form_id, slot))
@DataClassName('FormTypesRow')
class FormTypes extends Table {
  @override
  String get tableName => 'form_types';

  IntColumn get formId => integer().named('form_id')();

  IntColumn get slot => integer().named('slot')();

  IntColumn get typeId => integer().named('type_id')();

  @override
  Set<Column> get primaryKey => {formId, slot};
}

/// form_stats(form_id, stat, base_value, PRIMARY KEY(form_id, stat))
@DataClassName('FormStatsRow')
class FormStats extends Table {
  @override
  String get tableName => 'form_stats';

  IntColumn get formId => integer().named('form_id')();

  TextColumn get stat => text().named('stat')();

  IntColumn get baseValue => integer().named('base_value')();

  @override
  Set<Column> get primaryKey => {formId, stat};
}

/// form_abilities(form_id, slot, ability_id, is_hidden,
///                PRIMARY KEY(form_id, slot, is_hidden))
@DataClassName('FormAbilitiesRow')
class FormAbilities extends Table {
  @override
  String get tableName => 'form_abilities';

  IntColumn get formId => integer().named('form_id')();

  IntColumn get slot => integer().named('slot')();

  IntColumn get abilityId => integer().named('ability_id')();

  BoolColumn get isHidden => boolean().named('is_hidden')();

  @override
  Set<Column> get primaryKey => {formId, slot, isHidden};
}

/// pokemon_form_moves(form_id, move_id, method, level?, version_group,
///                    PRIMARY KEY(form_id, move_id, method, version_group))
@DataClassName('PokemonFormMovesRow')
class PokemonFormMoves extends Table {
  @override
  String get tableName => 'pokemon_form_moves';

  IntColumn get formId => integer().named('form_id')();

  IntColumn get moveId => integer().named('move_id')();

  TextColumn get method => text().named('method')();

  IntColumn get level => integer().nullable().named('level')();

  TextColumn get versionGroup => text().named('version_group')();

  @override
  Set<Column> get primaryKey => {formId, moveId, method, versionGroup};
}

/// evolution_chains(id INTEGER PRIMARY KEY, root_species_id INTEGER NOT NULL)
@DataClassName('EvolutionChainsRow')
class EvolutionChains extends Table {
  @override
  String get tableName => 'evolution_chains';

  IntColumn get id => integer().named('id')();

  IntColumn get rootSpeciesId => integer().named('root_species_id')();
}

/// evolution_edges(chain_id, from_species_id?, to_species_id, trigger, 条件列…,
///                 needs_overworld_rain, turn_upside_down,
///                 PRIMARY KEY(chain_id, to_species_id))
///
/// 根节点行：from_species_id 为 NULL（trigger = 'root'，to = 链根 species）。
@DataClassName('EvolutionEdgesRow')
class EvolutionEdges extends Table {
  @override
  String get tableName => 'evolution_edges';

  IntColumn get chainId => integer().named('chain_id')();

  IntColumn get fromSpeciesId =>
      integer().nullable().named('from_species_id')();

  IntColumn get toSpeciesId => integer().named('to_species_id')();

  TextColumn get trigger => text().named('trigger')();

  IntColumn get minLevel => integer().nullable().named('min_level')();

  TextColumn get item => text().nullable().named('item')();

  TextColumn get heldItem => text().nullable().named('held_item')();

  TextColumn get knownMove => text().nullable().named('known_move')();

  TextColumn get knownMoveType =>
      text().nullable().named('known_move_type')();

  TextColumn get location => text().nullable().named('location')();

  TextColumn get timeOfDay => text().nullable().named('time_of_day')();

  TextColumn get gender => text().nullable().named('gender')();

  IntColumn get minHappiness => integer().nullable().named('min_happiness')();

  IntColumn get minAffection => integer().nullable().named('min_affection')();

  IntColumn get minBeauty => integer().nullable().named('min_beauty')();

  TextColumn get relativePhysicalStats =>
      text().nullable().named('relative_physical_stats')();

  TextColumn get partySpecies =>
      text().nullable().named('party_species')();

  TextColumn get partyType => text().nullable().named('party_type')();

  TextColumn get tradeSpecies => text().nullable().named('trade_species')();

  BoolColumn get needsOverworldRain =>
      boolean().named('needs_overworld_rain')();

  BoolColumn get turnUpsideDown => boolean().named('turn_upside_down')();

  @override
  Set<Column> get primaryKey => {chainId, toSpeciesId};
}

/// versions(id, identifier, generation_id, version_group,
///          name_zh_hans?, name_en, name_ja?)
@DataClassName('VersionsRow')
class Versions extends Table {
  @override
  String get tableName => 'versions';

  IntColumn get id => integer().named('id')();

  TextColumn get identifier => text().named('identifier')();

  IntColumn get generationId => integer().named('generation_id')();

  TextColumn get versionGroup => text().named('version_group')();

  TextColumn get nameZhHans => text().nullable().named('name_zh_hans')();

  TextColumn get nameEn => text().named('name_en')();

  TextColumn get nameJa => text().nullable().named('name_ja')();
}

/// flavor_texts(species_id, version_id, language, flavor_text,
///              PRIMARY KEY(species_id, version_id, language))
@DataClassName('FlavorTextsRow')
class FlavorTexts extends Table {
  @override
  String get tableName => 'flavor_texts';

  IntColumn get speciesId => integer().named('species_id')();

  IntColumn get versionId => integer().named('version_id')();

  TextColumn get language => text().named('language')();

  TextColumn get flavorText => text().named('flavor_text')();

  @override
  Set<Column> get primaryKey => {speciesId, versionId, language};
}

/// pokedexes(id, identifier, name_zh_hans, generation_id?)
@DataClassName('PokedexesRow')
class Pokedexes extends Table {
  @override
  String get tableName => 'pokedexes';

  IntColumn get id => integer().named('id')();

  TextColumn get identifier => text().named('identifier')();

  TextColumn get nameZhHans => text().named('name_zh_hans')();

  IntColumn get generationId => integer().nullable().named('generation_id')();
}

/// species_dex_numbers(pokedex_id, species_id, dex_number,
///                     PRIMARY KEY(pokedex_id, species_id))
@DataClassName('SpeciesDexNumbersRow')
class SpeciesDexNumbers extends Table {
  @override
  String get tableName => 'species_dex_numbers';

  IntColumn get pokedexId => integer().named('pokedex_id')();

  IntColumn get speciesId => integer().named('species_id')();

  IntColumn get dexNumber => integer().named('dex_number')();

  @override
  Set<Column> get primaryKey => {pokedexId, speciesId};
}
