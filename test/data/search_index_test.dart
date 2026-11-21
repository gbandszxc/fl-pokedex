import 'package:flutter_test/flutter_test.dart';

import 'package:fl_pokedex/data/search/pokedex_search_index.dart';
import 'package:fl_pokedex/domain/models/filters.dart';

void main() {
  late PokedexSearchIndex index;

  setUp(() {
    index = PokedexSearchIndex.build(const [
      SearchSpeciesEntry(
        speciesId: 18,
        nationalDex: 18,
        nameZhHans: '大比鸟',
        nameZhHant: '大比鳥',
        nameEn: 'Pidgeot',
        nameJa: 'ピジョット',
        nameJaHrkt: 'ピジョット',
        nameRoomaji: 'Pigeot',
        genusZh: '鸟宝可梦',
        genusEn: 'Bird Pokémon',
        namePinyin: ['dabiniao'],
        nameInitials: ['dbn'],
        aliasesPinyin: ['bidiao', 'dabidiao'],
        aliasesInitials: ['bd', 'dbd'],
        aliases: [
          SearchAliasEntry(alias: '比雕', aliasNorm: '比雕', priority: 100),
          SearchAliasEntry(alias: '大比雕', aliasNorm: '大比雕', priority: 95),
        ],
        altForms: [
          SearchFormEntry(
            formNameZh: '超级大比鸟',
            formNameEn: 'Pidgeot Mega',
          ),
        ],
        tags: [SpecialTag.mega],
      ),
      SearchSpeciesEntry(
        speciesId: 37,
        nationalDex: 37,
        nameZhHans: '六尾',
        nameZhHant: '六尾',
        nameEn: 'Vulpix',
        nameJa: 'ロコン',
        nameJaHrkt: 'ロコン',
        genusZh: '狐狸宝可梦',
        genusEn: 'Fox Pokémon',
        namePinyin: ['liuwei'],
        nameInitials: ['lw'],
        altForms: [
          SearchFormEntry(
            formNameZh: '阿罗拉的样子',
            formNameEn: 'Vulpix Alola',
          ),
        ],
        tags: [SpecialTag.regional],
      ),
      SearchSpeciesEntry(
        speciesId: 25,
        nationalDex: 25,
        nameZhHans: '皮卡丘',
        nameZhHant: '皮卡丘',
        nameEn: 'Pikachu',
        nameJa: 'ピカチュウ',
        nameJaHrkt: 'ピカチュウ',
        genusZh: '鼠宝可梦',
        genusEn: 'Mouse Pokémon',
        namePinyin: ['pikaqiu'],
        nameInitials: ['pkq'],
        aliasesPinyin: ['bikachao'],
        aliasesInitials: ['bkc'],
        aliases: [
          SearchAliasEntry(alias: '比卡超', aliasNorm: '比卡超', priority: 100),
        ],
        tags: [SpecialTag.gmax],
      ),
      SearchSpeciesEntry(
        speciesId: 566,
        nationalDex: 566,
        nameZhHans: '始祖小鸟',
        nameZhHant: '始祖小鳥',
        nameEn: 'Archen',
        nameJa: 'アーケン',
        nameJaHrkt: 'アーケン',
        genusZh: '远古鸟宝可梦',
        genusEn: 'First Bird Pokémon',
        namePinyin: ['shizuxiaoniao'],
        nameInitials: ['szxn'],
        tags: [SpecialTag.fossil],
      ),
      SearchSpeciesEntry(
        speciesId: 282,
        nationalDex: 282,
        nameZhHans: '沙奈朵',
        nameZhHant: '沙奈朵',
        nameEn: 'Gardevoir',
        nameJa: 'サーナイト',
        nameJaHrkt: 'サーナイト',
        genusZh: '包容宝可梦',
        genusEn: 'Embrace Pokémon',
        namePinyin: ['shanaiduo'],
        nameInitials: ['snd'],
        aliases: [
          SearchAliasEntry(alias: '沙耐朵', aliasNorm: '沙耐朵', priority: 90),
        ],
        tags: [SpecialTag.mega],
      ),
    ]);
  });

  group('归一化与分词', () {
    test('全角转半角 / 小写 / 去分隔符，保留 #', () {
      expect(normalizeSearchText('  谜拟Ｑ · ２ '), '谜拟q2');
      expect(normalizeSearchText('#018'), '#018');
      expect(tokenizeQuery('阿罗拉　六尾  '), ['阿罗拉', '六尾']);
    });
  });

  group('分层相关性与倒排索引检索', () {
    test('编号精确命中排第一且无别名提示', () {
      final hits = index.search('#018');
      expect(hits.first.speciesId, 18);
      expect(hits.first.matchHint, isNull);
    });

    test('俗名精确命中排前且标注别名；官译已含关键词时不重复标注', () {
      final aliasHits = index.search('比雕');
      expect(aliasHits.first.speciesId, 18);
      expect(aliasHits.first.matchHint, '别名：比雕');

      // 「比」已存在于官译「大比鸟」中，不应标「别名：比雕」。
      final charHits = index.search('比');
      final pidgeot = charHits.firstWhere((h) => h.speciesId == 18);
      expect(pidgeot.matchHint, isNull);
    });

    test('拼音全拼与首字母命中官译与别名', () {
      expect(index.search('dbn').first.speciesId, 18);
      expect(index.search('dbn').first.matchHint, isNull);
      expect(index.search('dabiniao').first.speciesId, 18);

      final bd = index.search('bd').first;
      expect(bd.speciesId, 18);
      expect(bd.matchHint, '别名：比雕');

      expect(index.search('pkq').first.speciesId, 25);
    });

    test('非连续有序子序列与无序全字命中', () {
      final subseq = index.search('大鸟');
      expect(subseq.first.speciesId, 18);
      expect(subseq.first.matchHint, isNull);

      final unordered = index.search('鸟比');
      expect(unordered.any((h) => h.speciesId == 18), isTrue);
    });

    test('受控编辑距离 <= 1 仅在长度 >= 3 时生效', () {
      final typoEn = index.search('pikacu');
      expect(typoEn.first.speciesId, 25);

      // 长度 1 不触发编辑距离误报。
      expect(index.search('囧'), isEmpty);
    });

    test('空格多词交集（AND）保留最具信息量的提示', () {
      final regional = index.search('阿罗拉 六尾');
      expect(regional.map((h) => h.speciesId), [37]);
      expect(regional.single.matchHint, '形态：阿罗拉的样子');

      final fossilBird = index.search('化石 鸟');
      expect(fossilBird.map((h) => h.speciesId), [566]);
    });
  });
}
