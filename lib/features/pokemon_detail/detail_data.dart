import 'package:fl_pokedex/domain/models/ability_ref.dart';
import 'package:fl_pokedex/domain/models/flavor_entry.dart';
import 'package:fl_pokedex/domain/models/form_summary.dart';
import 'package:fl_pokedex/domain/models/stat_block.dart';

/// 详情页视图数据（本单元普通类，不用 freezed——features 目录不在
/// codegen 白名单内，见 architecture.md §1）。
///
/// species 级静态数据：由 [PokemonDetailData] 承载；形态级数据（种族值 /
/// 特性等）按形态惰性取回，由 [FormDetailData] 承载。

/// species 级详情数据。
class PokemonDetailData {
  const PokemonDetailData({
    required this.speciesId,
    required this.nationalDex,
    required this.nameZhHans,
    required this.nameEn,
    required this.nameJa,
    required this.generationId,
    required this.forms,
    this.genusZh,
    this.genusEn,
  });

  final int speciesId;

  /// 全国图鉴编号。
  final int nationalDex;

  /// 简体中文名。
  final String nameZhHans;

  final String nameEn;

  final String nameJa;

  /// 分类（如「种子宝可梦」，来自 SpeciesInfo.genusZh）。
  final String? genusZh;

  /// 分类英文名（来自 SpeciesInfo.genusEn，简中缺失时的回退）。
  final String? genusEn;

  final int generationId;

  /// 全部形态（form_order 排序，含 typeIds / 立绘路径 / 身高体重）。
  final List<FormSummary> forms;
}

/// 形态级详情数据（按形态惰性取回）。
class FormDetailData {
  const FormDetailData({
    required this.typeIds,
    required this.stats,
    required this.abilities,
    required this.artworkAsset,
    this.heightM,
    this.weightKg,
  });

  /// 本形态属性 identifier（slot 顺序）。
  final List<String> typeIds;

  final StatBlock stats;

  /// 特性（非隐藏在前），含说明文本（descriptionZh/descriptionEn）。
  final List<AbilityRef> abilities;

  /// 身高（m，取自 FormSummary.heightM）；上游缺失或为 0 时为 null（UI 显示 —）。
  final double? heightM;

  /// 体重（kg，取自 FormSummary.weightKg）；上游缺失时为 null（UI 显示 —）。
  final double? weightKg;

  /// 本形态立绘资产路径；数据缺失时为 null（UI 回退默认形态或占位图）。
  final String? artworkAsset;
}

/// 从形态列表解析当前选中形态：显式选中 → 默认形态 → 第一个。
FormSummary resolveSelectedForm(List<FormSummary> forms, int? selectedFormId) {
  if (forms.isEmpty) {
    throw ArgumentError.value(forms, 'forms', '形态列表不能为空');
  }
  for (final form in forms) {
    if (form.formId == selectedFormId) {
      return form;
    }
  }
  for (final form in forms) {
    if (form.isDefault) {
      return form;
    }
  }
  return forms.first;
}

/// 图鉴说明的一个版本聚合（该版本下全部语言条目）。
class FlavorVersion {
  const FlavorVersion({
    required this.versionId,
    required this.label,
    required this.entries,
  });

  final int versionId;

  /// chip 显示名：简中优先，无则英文。
  final String label;

  /// 该版本全部语言条目（zh_hans / zh_hant / en / ja 任意子集）。
  final List<FlavorEntry> entries;

  /// 语言回退取正文：zh_hans > zh_hant > en > ja。
  FlavorEntry? entryForDisplay() {
    for (final language in const ['zh_hans', 'zh_hant', 'en', 'ja']) {
      for (final entry in entries) {
        if (entry.language == language) {
          return entry;
        }
      }
    }
    return null;
  }
}

/// 图鉴说明的世代分组（新→旧）。
class FlavorVersionGroup {
  const FlavorVersionGroup({
    required this.generationId,
    required this.versions,
  });

  final int generationId;

  /// 该世代下的版本，versionId 大→小（新→旧）。
  final List<FlavorVersion> versions;
}

/// 图鉴说明解析结果：世代分组 + 当前选中版本。
class FlavorSelection {
  const FlavorSelection({required this.groups, required this.selected});

  /// 世代分组，新→旧。
  final List<FlavorVersionGroup> groups;

  /// 当前选中版本；species 没有任何文本时为 null。
  final FlavorVersion? selected;
}

/// 把全部语言条目解析为「世代分组（新→旧）+ 选中版本」。
///
/// 选中规则：显式 [selectedVersionId] 命中 → 用之；否则取「最新一个含
/// zh_hans 的版本」，再否则取最新版本（皮卡丘在朱/紫无任何语言文本、
/// 妙蛙种子老版本仅英文等场景由此兜底）。
FlavorSelection resolveFlavorSelection(
  List<FlavorEntry> entries,
  int? selectedVersionId,
) {
  if (entries.isEmpty) {
    return const FlavorSelection(groups: [], selected: null);
  }

  final byVersionId = <int, List<FlavorEntry>>{};
  for (final entry in entries) {
    byVersionId.putIfAbsent(entry.versionId, () => []).add(entry);
  }

  FlavorVersion buildVersion(int versionId) {
    final list = byVersionId[versionId]!;
    final first = list.first;
    final label = first.versionNameZh.isNotEmpty
        ? first.versionNameZh
        : first.versionNameEn;
    return FlavorVersion(
      versionId: versionId,
      label: label,
      entries: List.unmodifiable(list),
    );
  }

  // 世代分组（新→旧），组内版本新→旧。
  final versionIdsByGeneration = <int, List<int>>{};
  byVersionId.forEach((versionId, list) {
    versionIdsByGeneration
        .putIfAbsent(list.first.generationId, () => [])
        .add(versionId);
  });
  final generations = versionIdsByGeneration.keys.toList()
    ..sort((a, b) => b.compareTo(a));
  final groups = <FlavorVersionGroup>[];
  final allVersions = <FlavorVersion>[];
  for (final generation in generations) {
    final ids = versionIdsByGeneration[generation]!
      ..sort((a, b) => b.compareTo(a));
    final versions = [for (final id in ids) buildVersion(id)];
    groups.add(
      FlavorVersionGroup(generationId: generation, versions: versions),
    );
    allVersions.addAll(versions);
  }

  FlavorVersion? selected;
  for (final version in allVersions) {
    if (version.versionId == selectedVersionId) {
      selected = version;
      break;
    }
  }
  selected ??= _defaultVersion(allVersions);
  return FlavorSelection(groups: groups, selected: selected);
}

/// 最新一个含 zh_hans 的版本，否则最新版本。
FlavorVersion _defaultVersion(List<FlavorVersion> versionsNewToOld) {
  for (final version in versionsNewToOld) {
    if (version.entries.any((entry) => entry.language == 'zh_hans')) {
      return version;
    }
  }
  return versionsNewToOld.first;
}

/// 语言回退提示里的语言显示名；zh_hans 正常显示时返回 null。
String? flavorFallbackLanguageLabel(FlavorVersion version) {
  final entry = version.entryForDisplay();
  if (entry == null || entry.language == 'zh_hans') {
    return null;
  }
  return switch (entry.language) {
    'zh_hant' => '繁體中文',
    'en' => 'English',
    'ja' => '日本語',
    _ => entry.language,
  };
}
