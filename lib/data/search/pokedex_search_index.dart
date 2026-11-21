import '../../domain/models/filters.dart';

/// 检索归一化：全角 ASCII 转半角、全角空格转半角空格、转小写并去除空白与分隔符。
///
/// 与 `tools/data_builder/build_db.py` 的 `normalize_search_text` 口径一致；
/// `#` 保留以便识别 `#001` 类编号输入。
String normalizeSearchText(String raw) {
  final buffer = StringBuffer();
  for (final rune in raw.runes) {
    var ch = rune;
    // 全角 ASCII（！..～）转半角
    if (ch >= 0xFF01 && ch <= 0xFF5E) {
      ch -= 0xFEE0;
    } else if (ch == 0x3000) {
      continue;
    }
    if (ch >= 0x41 && ch <= 0x5A) {
      ch += 0x20; // A-Z → a-z
    }
    if (_isIgnoredSeparator(ch)) {
      continue;
    }
    buffer.writeCharCode(ch);
  }
  return buffer.toString();
}

bool _isIgnoredSeparator(int rune) {
  return rune <= 0x20 ||
      rune == 0x2D || // -
      rune == 0x5F || // _
      rune == 0xB7 || // ·
      rune == 0x30FB || // ・
      rune == 0x27 || // '
      rune == 0x2019 || // ’
      rune == 0x2E || // .
      rune == 0x3A || // :
      rune == 0x3002 || // 。
      rune == 0xFF0C; // ，
}

/// 按空白（含全角空格）拆分多词查询并归一化。
List<String> tokenizeQuery(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return const <String>[];
  final parts = trimmed.split(RegExp(r'[\s\u3000]+'));
  final out = <String>[];
  for (final part in parts) {
    final norm = normalizeSearchText(part);
    if (norm.isNotEmpty) {
      out.add(norm);
    }
  }
  return out;
}

bool _isAsciiAlnum(String s) {
  if (s.isEmpty) return false;
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    final isDigit = c >= 0x30 && c <= 0x39;
    final isLower = c >= 0x61 && c <= 0x7A;
    if (!isDigit && !isLower) return false;
  }
  return true;
}

/// 单条俗名 / 旧译记录。
class SearchAliasEntry {
  const SearchAliasEntry({
    required this.alias,
    required this.aliasNorm,
    required this.priority,
  });

  final String alias;
  final String aliasNorm;
  final int priority;
}

/// 单条非默认形态名记录。
class SearchFormEntry {
  const SearchFormEntry({
    required this.formNameZh,
    required this.formNameEn,
  });

  final String formNameZh;
  final String formNameEn;
}

/// 倒排索引输入项（每个 species 一条）。
class SearchSpeciesEntry {
  const SearchSpeciesEntry({
    required this.speciesId,
    required this.nationalDex,
    required this.nameZhHans,
    required this.nameZhHant,
    required this.nameEn,
    required this.nameJa,
    required this.nameJaHrkt,
    this.nameRoomaji,
    this.genusZh,
    this.genusEn,
    required this.namePinyin,
    required this.nameInitials,
    this.aliasesPinyin = const <String>[],
    this.aliasesInitials = const <String>[],
    this.aliases = const <SearchAliasEntry>[],
    this.altForms = const <SearchFormEntry>[],
    this.tags = const <SpecialTag>[],
  });

  final int speciesId;
  final int nationalDex;
  final String nameZhHans;
  final String nameZhHant;
  final String nameEn;
  final String nameJa;
  final String nameJaHrkt;
  final String? nameRoomaji;
  final String? genusZh;
  final String? genusEn;
  final List<String> namePinyin;
  final List<String> nameInitials;
  final List<String> aliasesPinyin;
  final List<String> aliasesInitials;
  final List<SearchAliasEntry> aliases;
  final List<SearchFormEntry> altForms;
  final List<SpecialTag> tags;
}

/// 检索命中结果（按相关性排序输出）。
class SearchHit {
  const SearchHit({
    required this.speciesId,
    required this.nationalDex,
    required this.score,
    this.matchHint,
  });

  final int speciesId;
  final int nationalDex;
  final int score;
  final String? matchHint;
}

enum _HintKind { none, alias, form, tag, genus }

class _Doc {
  _Doc({
    required this.entry,
    required this.officialNorms,
    required this.officialRuneSets,
    required this.aliases,
    required this.forms,
    required this.genusNorms,
    required this.genusDisplay,
    required this.tagTerms,
    required this.allRunes,
  });

  final SearchSpeciesEntry entry;
  // index 0 为 nameZhHans；其余为繁/英/日/假名/罗马音
  final List<String> officialNorms;
  final List<List<int>> officialRuneSets;
  final List<({String alias, String norm, List<int> runes, int priority})>
      aliases;
  final List<({String formNameZh, String norm, List<int> runes})> forms;
  final List<String> genusNorms;
  final String? genusDisplay;
  final List<({SpecialTag tag, String norm})> tagTerms;
  final Set<int> allRunes;

  bool officialContains(String token) {
    for (final norm in officialNorms) {
      if (norm.contains(token)) return true;
    }
    return false;
  }
}

class _TokenMatch {
  const _TokenMatch({
    required this.score,
    required this.hint,
    required this.hintKind,
  });

  final int score;
  final String? hint;
  final _HintKind hintKind;
}

/// 纯 Dart 内存倒排索引：字符级 Unigram 倒排 + 分层相关性打分。
///
/// 支持全国图鉴编号、六语官译、俗名旧译、非默认形态名、全拼/首字母、
/// 非连续有序子序列、无序全字命中、受控编辑距离（<=1）以及图鉴分类/检索标签，
/// 并支持空格拆多词交集（AND）。
class PokedexSearchIndex {
  PokedexSearchIndex._({
    required List<_Doc> docs,
    required Map<int, int> byDex,
    required Map<int, List<int>> charPosting,
    required Map<int, List<int>> metaPosting,
    required Map<int, List<int>> pinyinFirstCharPosting,
  })  : _docs = docs,
        _byDex = byDex,
        _charPosting = charPosting,
        _metaPosting = metaPosting,
        _pinyinFirstCharPosting = pinyinFirstCharPosting;

  factory PokedexSearchIndex.build(List<SearchSpeciesEntry> entries) {
    final docs = <_Doc>[];
    final byDex = <int, int>{};
    final charPosting = <int, List<int>>{};
    final metaPosting = <int, List<int>>{};
    final pinyinFirstCharPosting = <int, List<int>>{};

    void addPosting(Map<int, List<int>> map, int key, int docIndex) {
      final list = map.putIfAbsent(key, () => <int>[]);
      if (list.isEmpty || list.last != docIndex) {
        list.add(docIndex);
      }
    }

    for (var idx = 0; idx < entries.length; idx++) {
      final e = entries[idx];
      byDex[e.nationalDex] = idx;

      final officialNorms = <String>[
        normalizeSearchText(e.nameZhHans),
        normalizeSearchText(e.nameZhHant),
        normalizeSearchText(e.nameEn),
        normalizeSearchText(e.nameJa),
        normalizeSearchText(e.nameJaHrkt),
        if (e.nameRoomaji != null && e.nameRoomaji!.isNotEmpty)
          normalizeSearchText(e.nameRoomaji!),
      ].where((s) => s.isNotEmpty).toList(growable: false);

      final allRunes = <int>{};
      final officialRuneSets = <List<int>>[];
      for (final norm in officialNorms) {
        final runes = norm.runes.toList(growable: false);
        officialRuneSets.add(runes);
        for (final r in runes) {
          allRunes.add(r);
          addPosting(charPosting, r, idx);
        }
      }

      final sortedAliases = [...e.aliases]
        ..sort((a, b) => b.priority.compareTo(a.priority));
      final aliases =
          <({String alias, String norm, List<int> runes, int priority})>[];
      for (final a in sortedAliases) {
        final norm = a.aliasNorm.isEmpty
            ? normalizeSearchText(a.alias)
            : a.aliasNorm;
        if (norm.isEmpty) continue;
        final runes = norm.runes.toList(growable: false);
        aliases.add((
          alias: a.alias,
          norm: norm,
          runes: runes,
          priority: a.priority,
        ));
        for (final r in runes) {
          allRunes.add(r);
          addPosting(charPosting, r, idx);
        }
      }

      final forms = <({String formNameZh, String norm, List<int> runes})>[];
      for (final f in e.altForms) {
        final seenFormNorm = <String>{};
        for (final rawName in [f.formNameZh, f.formNameEn]) {
          final norm = normalizeSearchText(rawName);
          if (norm.isEmpty || !seenFormNorm.add(norm)) continue;
          final runes = norm.runes.toList(growable: false);
          forms.add((formNameZh: f.formNameZh, norm: norm, runes: runes));
          for (final r in runes) {
            allRunes.add(r);
            addPosting(charPosting, r, idx);
          }
        }
      }

      final genusNorms = <String>[
        if (e.genusZh != null && e.genusZh!.isNotEmpty)
          normalizeSearchText(e.genusZh!),
        if (e.genusEn != null && e.genusEn!.isNotEmpty)
          normalizeSearchText(e.genusEn!),
      ].where((s) => s.isNotEmpty).toList(growable: false);
      final genusDisplay = (e.genusZh != null && e.genusZh!.isNotEmpty)
          ? e.genusZh
          : e.genusEn;
      for (final gNorm in genusNorms) {
        for (final r in gNorm.runes) {
          addPosting(metaPosting, r, idx);
        }
      }

      final tagTerms = <({SpecialTag tag, String norm})>[];
      for (final tag in e.tags) {
        for (final term in tag.searchTerms) {
          final norm = normalizeSearchText(term);
          if (norm.isEmpty) continue;
          tagTerms.add((tag: tag, norm: norm));
          for (final r in norm.runes) {
            addPosting(metaPosting, r, idx);
          }
        }
      }

      for (final py in [
        ...e.namePinyin,
        ...e.nameInitials,
        ...e.aliasesPinyin,
        ...e.aliasesInitials,
      ]) {
        if (py.isEmpty) continue;
        addPosting(pinyinFirstCharPosting, py.codeUnitAt(0), idx);
      }

      docs.add(_Doc(
        entry: e,
        officialNorms: officialNorms,
        officialRuneSets: officialRuneSets,
        aliases: aliases,
        forms: forms,
        genusNorms: genusNorms,
        genusDisplay: genusDisplay,
        tagTerms: tagTerms,
        allRunes: allRunes,
      ));
    }

    return PokedexSearchIndex._(
      docs: docs,
      byDex: byDex,
      charPosting: charPosting,
      metaPosting: metaPosting,
      pinyinFirstCharPosting: pinyinFirstCharPosting,
    );
  }

  final List<_Doc> _docs;
  final Map<int, int> _byDex;
  final Map<int, List<int>> _charPosting;
  final Map<int, List<int>> _metaPosting;
  final Map<int, List<int>> _pinyinFirstCharPosting;

  static final RegExp _dexPattern = RegExp(r'^#?(\d{1,4})$');

  /// 执行检索并返回按相关性降序、同分按编号升序的结果。
  List<SearchHit> search(String rawQuery) {
    final tokens = tokenizeQuery(rawQuery);
    if (tokens.isEmpty) return const <SearchHit>[];

    Map<int, _TokenMatch>? intersected;
    for (final token in tokens) {
      final tokenHits = _searchSingleToken(token);
      if (tokenHits.isEmpty) {
        return const <SearchHit>[];
      }
      if (intersected == null) {
        intersected = tokenHits;
      } else {
        final next = <int, _TokenMatch>{};
        for (final entry in intersected.entries) {
          final other = tokenHits[entry.key];
          if (other == null) continue;
          final mergedHint = _pickHint(entry.value, other);
          next[entry.key] = _TokenMatch(
            score: entry.value.score + other.score,
            hint: mergedHint.$1,
            hintKind: mergedHint.$2,
          );
        }
        if (next.isEmpty) {
          return const <SearchHit>[];
        }
        intersected = next;
      }
    }

    final hits = <SearchHit>[
      for (final entry in intersected!.entries)
        SearchHit(
          speciesId: _docs[entry.key].entry.speciesId,
          nationalDex: _docs[entry.key].entry.nationalDex,
          score: entry.value.score,
          matchHint: entry.value.hint,
        ),
    ];
    hits.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.nationalDex.compareTo(b.nationalDex);
    });
    return hits;
  }

  (String?, _HintKind) _pickHint(_TokenMatch a, _TokenMatch b) {
    // 优先级：别名 > 形态 > 标签 > 分类 > 无
    int rank(_HintKind kind) => switch (kind) {
          _HintKind.alias => 4,
          _HintKind.form => 3,
          _HintKind.tag => 2,
          _HintKind.genus => 1,
          _HintKind.none => 0,
        };
    if (a.hint == null) return (b.hint, b.hintKind);
    if (b.hint == null) return (a.hint, a.hintKind);
    return rank(b.hintKind) > rank(a.hintKind)
        ? (b.hint, b.hintKind)
        : (a.hint, a.hintKind);
  }

  Map<int, _TokenMatch> _searchSingleToken(String token) {
    final results = <int, _TokenMatch>{};

    // Tier 1: 全国图鉴编号精确命中
    final dexMatch = _dexPattern.firstMatch(token);
    if (dexMatch != null) {
      final n = int.parse(dexMatch.group(1)!);
      final docIdx = _byDex[n];
      if (docIdx != null) {
        results[docIdx] = const _TokenMatch(
          score: 10000,
          hint: null,
          hintKind: _HintKind.none,
        );
      }
    }

    final textToken = token.replaceAll('#', '');
    if (textToken.isEmpty) return results;

    final queryRunes = textToken.runes.toList(growable: false);
    final uniqueRunes = queryRunes.toSet().toList(growable: false);
    final isAscii = _isAsciiAlnum(textToken);
    final isPureDigits = dexMatch != null;

    // 1) 从倒排索引收集候选 doc
    final charHitCounts = <int, int>{};
    for (final r in uniqueRunes) {
      final posting = _charPosting[r];
      if (posting == null) continue;
      for (final idx in posting) {
        charHitCounts[idx] = (charHitCounts[idx] ?? 0) + 1;
      }
    }

    final candidates = <int>{};
    final minRequiredHits = (textToken.length >= 3 && !isPureDigits)
        ? (uniqueRunes.length - 1).clamp(1, uniqueRunes.length)
        : uniqueRunes.length;
    for (final entry in charHitCounts.entries) {
      if (entry.value >= minRequiredHits) {
        candidates.add(entry.key);
      }
    }

    // 拼音候选（ASCII 且长度 >= 2）
    if (isAscii && textToken.length >= 2) {
      final firstPosting = _pinyinFirstCharPosting[textToken.codeUnitAt(0)];
      if (firstPosting != null) {
        candidates.addAll(firstPosting);
      }
      // 长度 >= 4 时允许首字母打错的拼音容错：兼收第 2 字符桶
      if (textToken.length >= 4) {
        final secondPosting = _pinyinFirstCharPosting[textToken.codeUnitAt(1)];
        if (secondPosting != null) {
          candidates.addAll(secondPosting);
        }
      }
    }

    // 分类 / 标签候选（严格子串/精确命中）
    final metaCounts = <int, int>{};
    for (final r in uniqueRunes) {
      final posting = _metaPosting[r];
      if (posting == null) continue;
      for (final idx in posting) {
        metaCounts[idx] = (metaCounts[idx] ?? 0) + 1;
      }
    }
    for (final entry in metaCounts.entries) {
      if (entry.value == uniqueRunes.length) {
        candidates.add(entry.key);
      }
    }

    // 2) 对每个候选 doc 逐层打分，保留最高命中
    for (final idx in candidates) {
      final existing = results[idx];
      if (existing != null && existing.score >= 10000) {
        continue; // 已命中图鉴编号
      }
      final match = _scoreDoc(
        _docs[idx],
        textToken,
        queryRunes,
        isAscii: isAscii,
        isPureDigits: isPureDigits,
      );
      if (match == null) continue;
      if (existing == null || match.score > existing.score) {
        results[idx] = match;
      }
    }

    return results;
  }

  _TokenMatch? _scoreDoc(
    _Doc doc,
    String token,
    List<int> queryRunes, {
    required bool isAscii,
    required bool isPureDigits,
  }) {
    _TokenMatch? best;
    void consider(int score, String? hint, _HintKind kind) {
      if (best == null || score > best!.score) {
        best = _TokenMatch(score: score, hint: hint, hintKind: kind);
      }
    }

    final officialHit = doc.officialContains(token);

    // Tier 2: 官译精确 / 前缀
    for (var i = 0; i < doc.officialNorms.length; i++) {
      final norm = doc.officialNorms[i];
      final zhBonus = i == 0 ? 100 : 0;
      if (norm == token) {
        consider(9000 + zhBonus, null, _HintKind.none);
      } else if (norm.startsWith(token)) {
        consider(8200 + zhBonus, null, _HintKind.none);
      }
    }

    // Tier 3: 俗名 / 旧译精确 / 前缀
    for (final a in doc.aliases) {
      final pBonus = a.priority ~/ 10;
      final hint = officialHit ? null : '别名：${a.alias}';
      final kind = officialHit ? _HintKind.none : _HintKind.alias;
      if (a.norm == token) {
        consider(7800 + pBonus, hint, kind);
      } else if (a.norm.startsWith(token)) {
        consider(7200 + pBonus, hint, kind);
      }
    }

    // Tier 4a: 官译子串
    for (var i = 0; i < doc.officialNorms.length; i++) {
      if (doc.officialNorms[i].contains(token)) {
        consider(6800 + (i == 0 ? 50 : 0), null, _HintKind.none);
      }
    }

    // Tier 4b: 官译拼音（ASCII >= 2）
    if (isAscii && token.length >= 2) {
      for (final py in doc.entry.namePinyin) {
        if (py == token) {
          consider(6600, null, _HintKind.none);
        } else if (py.startsWith(token)) {
          consider(6100, null, _HintKind.none);
        } else if (token.length >= 4 && py.contains(token)) {
          consider(5700, null, _HintKind.none);
        }
      }
      for (final init in doc.entry.nameInitials) {
        if (init == token) {
          consider(6400, null, _HintKind.none);
        } else if (init.startsWith(token)) {
          consider(5900, null, _HintKind.none);
        }
      }
    }

    // Tier 4c: 俗名子串与俗名拼音
    for (final a in doc.aliases) {
      if (a.norm.contains(token)) {
        final hint = officialHit ? null : '别名：${a.alias}';
        final kind = officialHit ? _HintKind.none : _HintKind.alias;
        consider(6400 + a.priority ~/ 10, hint, kind);
      }
    }
    if (isAscii && token.length >= 2 && doc.aliases.isNotEmpty) {
      for (final py in doc.entry.aliasesPinyin) {
        if (py == token) {
          final a = _bestAliasForPinyin(doc, token, isInitial: false);
          consider(
            6300 + a.priority ~/ 10,
            officialHit ? null : '别名：${a.alias}',
            officialHit ? _HintKind.none : _HintKind.alias,
          );
        } else if (py.startsWith(token)) {
          final a = _bestAliasForPinyin(doc, token, isInitial: false);
          consider(
            5800 + a.priority ~/ 10,
            officialHit ? null : '别名：${a.alias}',
            officialHit ? _HintKind.none : _HintKind.alias,
          );
        }
      }
      for (final init in doc.entry.aliasesInitials) {
        if (init == token) {
          final a = _bestAliasForPinyin(doc, token, isInitial: true);
          consider(
            6200 + a.priority ~/ 10,
            officialHit ? null : '别名：${a.alias}',
            officialHit ? _HintKind.none : _HintKind.alias,
          );
        } else if (init.startsWith(token)) {
          final a = _bestAliasForPinyin(doc, token, isInitial: true);
          consider(
            5600 + a.priority ~/ 10,
            officialHit ? null : '别名：${a.alias}',
            officialHit ? _HintKind.none : _HintKind.alias,
          );
        }
      }
    }

    // Tier 4d: 非默认形态名
    for (final f in doc.forms) {
      final hint = officialHit ? null : '形态：${f.formNameZh}';
      final kind = officialHit ? _HintKind.none : _HintKind.form;
      if (f.norm == token) {
        consider(5580, hint, kind);
      } else if (f.norm.startsWith(token)) {
        consider(5540, hint, kind);
      } else if (f.norm.contains(token)) {
        consider(5500, hint, kind);
      }
    }

    // 若已命中 Tier 2~4，不再需要进入低优先级模糊分支
    if (best != null && best!.score >= 5500) {
      return best;
    }

    // Tier 5: 倒排索引非连续模糊匹配（仅长度 >= 2 且非纯数字）
    if (queryRunes.length >= 2 && !isPureDigits) {
      // 5a: 非连续有序子序列（大鸟 → 大比鸟，喷龙 → 喷火龙）
      for (final runes in doc.officialRuneSets) {
        final gap = _subsequenceGap(queryRunes, runes);
        if (gap >= 0) {
          final penalty = (gap * 40).clamp(0, 280);
          consider(4800 - penalty, null, _HintKind.none);
        }
      }
      for (final a in doc.aliases) {
        final gap = _subsequenceGap(queryRunes, a.runes);
        if (gap >= 0) {
          final penalty = (gap * 40).clamp(0, 280);
          consider(4500 - penalty, '别名：${a.alias}', _HintKind.alias);
        }
      }
      for (final f in doc.forms) {
        final gap = _subsequenceGap(queryRunes, f.runes);
        if (gap >= 0) {
          final penalty = (gap * 40).clamp(0, 280);
          consider(4200 - penalty, '形态：${f.formNameZh}', _HintKind.form);
        }
      }

      // 5b: 无序全字符命中（鸟比 → 大比鸟）
      if (doc.allRunes.containsAll(queryRunes)) {
        for (final runes in doc.officialRuneSets) {
          if (_containsAllMultiset(queryRunes, runes)) {
            final extra = (runes.length - queryRunes.length).clamp(0, 10);
            consider(4000 - extra * 15, null, _HintKind.none);
          }
        }
        for (final a in doc.aliases) {
          if (_containsAllMultiset(queryRunes, a.runes)) {
            final extra = (a.runes.length - queryRunes.length).clamp(0, 10);
            consider(3800 - extra * 15, '别名：${a.alias}', _HintKind.alias);
          }
        }
      }

      // 5c: 受控编辑距离 <= 1（仅长度 >= 3）
      if (queryRunes.length >= 3) {
        for (final runes in doc.officialRuneSets) {
          if ((runes.length - queryRunes.length).abs() <= 1 &&
              _isEditDistanceOne(queryRunes, runes)) {
            consider(3600, null, _HintKind.none);
          }
        }
        if (isAscii && token.length >= 4) {
          for (final py in doc.entry.namePinyin) {
            if ((py.length - token.length).abs() <= 1 &&
                _isEditDistanceOneAscii(token, py)) {
              consider(3550, null, _HintKind.none);
            }
          }
        }
        for (final a in doc.aliases) {
          if ((a.runes.length - queryRunes.length).abs() <= 1 &&
              _isEditDistanceOne(queryRunes, a.runes)) {
            consider(3500 + a.priority ~/ 20, '别名：${a.alias}', _HintKind.alias);
          }
        }
      }
    }

    // Tier 6: 图鉴分类与检索标签
    if (doc.genusDisplay != null) {
      for (final gNorm in doc.genusNorms) {
        if (gNorm == token) {
          consider(3000, '分类：${doc.genusDisplay}', _HintKind.genus);
        } else if ((token.length >= 2 || !isAscii) && gNorm.contains(token)) {
          consider(2600, '分类：${doc.genusDisplay}', _HintKind.genus);
        }
      }
    }
    for (final t in doc.tagTerms) {
      if (t.norm == token) {
        consider(2800, '标签：${t.tag.detailLabelZh}', _HintKind.tag);
      } else if (token.length >= 2 && t.norm.contains(token)) {
        consider(2400, '标签：${t.tag.detailLabelZh}', _HintKind.tag);
      }
    }

    return best;
  }

  /// 多别名场景下，尽量挑出长度或文本特征最贴合该拼音词的别名用于提示。
  ({String alias, String norm, List<int> runes, int priority})
      _bestAliasForPinyin(
    _Doc doc,
    String token, {
    required bool isInitial,
  }) {
    if (isInitial) {
      for (final a in doc.aliases) {
        if (a.runes.length == token.length) {
          return a;
        }
      }
    }
    return doc.aliases.first;
  }

  /// 有序子序列检查：命中返回跳字总数（>= 0），否则返回 -1。
  static int _subsequenceGap(List<int> query, List<int> target) {
    if (query.length > target.length) return -1;
    var qi = 0;
    var firstMatch = -1;
    var lastMatch = -1;
    for (var ti = 0; ti < target.length && qi < query.length; ti++) {
      if (target[ti] == query[qi]) {
        if (firstMatch < 0) firstMatch = ti;
        lastMatch = ti;
        qi++;
      }
    }
    if (qi < query.length) return -1;
    return (lastMatch - firstMatch + 1) - query.length;
  }

  /// 无序多重集包含检查（考虑重复字频）。
  static bool _containsAllMultiset(List<int> query, List<int> target) {
    if (query.length > target.length) return false;
    final counts = <int, int>{};
    for (final r in target) {
      counts[r] = (counts[r] ?? 0) + 1;
    }
    for (final r in query) {
      final c = counts[r] ?? 0;
      if (c <= 0) return false;
      counts[r] = c - 1;
    }
    return true;
  }

  /// 判定两字符列表的 Levenshtein 编辑距离是否恰为 <= 1（已前置长度差 <= 1）。
  static bool _isEditDistanceOne(List<int> a, List<int> b) {
    final la = a.length;
    final lb = b.length;
    if ((la - lb).abs() > 1) return false;
    var i = 0;
    var j = 0;
    var edits = 0;
    while (i < la && j < lb) {
      if (a[i] == b[j]) {
        i++;
        j++;
      } else {
        edits++;
        if (edits > 1) return false;
        if (la > lb) {
          i++;
        } else if (lb > la) {
          j++;
        } else {
          i++;
          j++;
        }
      }
    }
    if (i < la || j < lb) edits++;
    return edits <= 1;
  }

  static bool _isEditDistanceOneAscii(String a, String b) {
    final la = a.length;
    final lb = b.length;
    if ((la - lb).abs() > 1) return false;
    var i = 0;
    var j = 0;
    var edits = 0;
    while (i < la && j < lb) {
      if (a.codeUnitAt(i) == b.codeUnitAt(j)) {
        i++;
        j++;
      } else {
        edits++;
        if (edits > 1) return false;
        if (la > lb) {
          i++;
        } else if (lb > la) {
          j++;
        } else {
          i++;
          j++;
        }
      }
    }
    if (i < la || j < lb) edits++;
    return edits <= 1;
  }
}
