import 'package:flutter_test/flutter_test.dart';

import 'package:fl_pokedex/domain/models/flavor_entry.dart';
import 'package:fl_pokedex/domain/models/form_summary.dart';
import 'package:fl_pokedex/features/pokemon_detail/detail_data.dart';

FlavorEntry entry(
  int versionId, {
  required int generationId,
  required String language,
  String versionNameZh = '',
  String? versionNameEn,
}) =>
    FlavorEntry(
      versionId: versionId,
      versionIdentifier: 'v$versionId',
      versionNameZh: versionNameZh,
      versionNameEn: versionNameEn ?? 'Ver$versionId',
      generationId: generationId,
      language: language,
      text: '$versionId-$language',
    );

void main() {
  group('resolveFlavorSelection', () {
    test('空条目：无分组、无选中', () {
      final selection = resolveFlavorSelection(const [], null);
      expect(selection.groups, isEmpty);
      expect(selection.selected, isNull);
    });

    test('默认选最新一个含 zh_hans 的版本（跨世代）', () {
      final selection = resolveFlavorSelection([
        entry(1, generationId: 1, language: 'zh_hans', versionNameZh: '红'),
        entry(2, generationId: 3, language: 'en'),
        entry(3, generationId: 9, language: 'ja'),
      ], null);
      // gen9 / gen3 均无 zh_hans → 回落到 gen1 的版本。
      expect(selection.selected!.versionId, 1);
      // 分组新→旧：第九世代在前。
      expect(
        selection.groups.map((g) => g.generationId).toList(),
        [9, 3, 1],
      );
    });

    test('最新含 zh_hans 优先于最新版本本身', () {
      final selection = resolveFlavorSelection([
        entry(1, generationId: 1, language: 'zh_hans', versionNameZh: '红'),
        entry(2, generationId: 1, language: 'zh_hans', versionNameZh: '蓝'),
      ], null);
      expect(selection.selected!.versionId, 2); // 同世代取 versionId 更大的
    });

    test('全部语言都缺失 zh_hans 时选最新版本', () {
      final selection = resolveFlavorSelection([
        entry(1, generationId: 1, language: 'en'),
        entry(2, generationId: 3, language: 'ja'),
      ], null);
      expect(selection.selected!.versionId, 2);
    });

    test('显式选中的版本优先于默认', () {
      final selection = resolveFlavorSelection([
        entry(1, generationId: 1, language: 'zh_hans', versionNameZh: '红'),
        entry(2, generationId: 3, language: 'en'),
      ], 2);
      expect(selection.selected!.versionId, 2);
    });

    test('chip 标签：简中优先，无简中回退英文', () {
      final selection = resolveFlavorSelection([
        entry(1,
            generationId: 1,
            language: 'en',
            versionNameZh: '',
            versionNameEn: 'Red'),
        entry(2,
            generationId: 9,
            language: 'zh_hans',
            versionNameZh: '朱',
            versionNameEn: 'Scarlet'),
      ], null);
      final versions = [
        for (final group in selection.groups)
          for (final version in group.versions) version,
      ];
      expect(
        {for (final v in versions) v.versionId: v.label},
        {1: 'Red', 2: '朱'},
      );
    });
  });

  group('FlavorVersion.entryForDisplay', () {
    test('语言回退 zh_hans > zh_hant > en > ja', () {
      final version = FlavorVersion(
        versionId: 1,
        label: '红',
        entries: [
          entry(1, generationId: 1, language: 'ja'),
          entry(1, generationId: 1, language: 'en'),
          entry(1, generationId: 1, language: 'zh_hant'),
          entry(1, generationId: 1, language: 'zh_hans'),
        ],
      );
      expect(version.entryForDisplay()!.language, 'zh_hans');
    });

    test('缺简中时取繁中，再缺取英文', () {
      FlavorVersion make(List<String> languages) => FlavorVersion(
            versionId: 1,
            label: '红',
            entries: [
              for (final language in languages)
                entry(1, generationId: 1, language: language),
            ],
          );
      expect(make(['zh_hant', 'en']).entryForDisplay()!.language, 'zh_hant');
      expect(make(['ja', 'en']).entryForDisplay()!.language, 'en');
    });
  });

  group('flavorFallbackLanguageLabel', () {
    FlavorVersion make(String language) => FlavorVersion(
          versionId: 1,
          label: '红',
          entries: [entry(1, generationId: 1, language: language)],
        );

    test('zh_hans 正常显示不提示', () {
      expect(flavorFallbackLanguageLabel(make('zh_hans')), isNull);
    });

    test('其余语言给出显示名', () {
      expect(flavorFallbackLanguageLabel(make('zh_hant')), '繁體中文');
      expect(flavorFallbackLanguageLabel(make('en')), 'English');
      expect(flavorFallbackLanguageLabel(make('ja')), '日本語');
    });
  });

  group('resolveSelectedForm', () {
    test('未选中时取默认形态，选中后取指定形态', () {
      final forms = [
        defaultForm(1),
        defaultForm(2, isDefault: false),
      ];
      expect(resolveSelectedForm(forms, null).formId, 1);
      expect(resolveSelectedForm(forms, 2).formId, 2);
    });

    test('无默认形态时回落第一个', () {
      final forms = [defaultForm(7, isDefault: false)];
      expect(resolveSelectedForm(forms, null).formId, 7);
    });
  });
}

FormSummary defaultForm(int formId, {bool isDefault = true}) => FormSummary(
      formId: formId,
      speciesId: 1,
      formIdentifier: null,
      formNameZh: '形态$formId',
      formNameEn: 'Form$formId',
      isDefault: isDefault,
      isMega: false,
      isGmax: false,
      isRegional: false,
      artworkAsset: null,
      typeIds: const ['normal'],
    );
