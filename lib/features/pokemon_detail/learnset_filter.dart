import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../domain/models/move_entry.dart';
import '../../domain/models/refs.dart';

/// 招式列表排序维度。
enum MoveSort { level, power, name }

/// 学习集筛选与排序状态（features 目录普通类，不用 freezed；
/// 整体不可变，变更时由 Notifier 替换实例）。
class LearnsetFilter {
  const LearnsetFilter({
    this.versionGroup = '',
    this.methods = const <String>{},
    this.sort = MoveSort.level,
  });

  /// 版本组 id；空串 = 跟随默认（getFormVersionGroups 的第一个，最新组）。
  final String versionGroup;

  /// 选中来源（method identifier 多选 OR）；空集合 = 全部。
  final Set<String> methods;

  final MoveSort sort;

  LearnsetFilter copyWith({
    String? versionGroup,
    Set<String>? methods,
    MoveSort? sort,
  }) {
    return LearnsetFilter(
      versionGroup: versionGroup ?? this.versionGroup,
      methods: methods ?? this.methods,
      sort: sort ?? this.sort,
    );
  }
}

/// formId → 学习集筛选状态。
class LearnsetFilterNotifier
    extends AutoDisposeFamilyNotifier<LearnsetFilter, int> {
  @override
  LearnsetFilter build(int arg) => const LearnsetFilter();

  void setVersionGroup(String id) => state = state.copyWith(versionGroup: id);

  /// 整体替换来源集合（「全部」传空集合）。
  void setMethods(Set<String> methods) =>
      state = state.copyWith(methods: methods);

  void setSort(MoveSort sort) => state = state.copyWith(sort: sort);
}

/// formId → 学习集筛选状态。
final learnsetFilterProvider = NotifierProvider.autoDispose
    .family<LearnsetFilterNotifier, LearnsetFilter, int>(
  LearnsetFilterNotifier.new,
);

/// 来源 method 的分组展示序：升级 → 学习器 → 遗传 → 导师 → 其他。
int methodGroupOrder(String method) => switch (method) {
      'level_up' => 0,
      'machine' => 1,
      'egg' => 2,
      'tutor' => 3,
      _ => 4,
    };

/// 招式排序比较器：
/// - level：(method 组序, 等级, 编号)，等级缺失排尾（沿用仓储的分组序）；
/// - power：威力缺失排尾，其余降序，同威力按编号；
/// - name：先简中名后英文名（无 intl 依赖，退化为 UTF-16 码元序）。
int compareMoveEntries(MoveEntry a, MoveEntry b, MoveSort sort) {
  switch (sort) {
    case MoveSort.level:
      final byMethod =
          methodGroupOrder(a.method).compareTo(methodGroupOrder(b.method));
      if (byMethod != 0) return byMethod;
      final aLevel = a.level;
      final bLevel = b.level;
      if (aLevel == null && bLevel == null) {
        return a.moveId.compareTo(b.moveId);
      }
      if (aLevel == null) return 1;
      if (bLevel == null) return -1;
      final byLevel = aLevel.compareTo(bLevel);
      return byLevel != 0 ? byLevel : a.moveId.compareTo(b.moveId);
    case MoveSort.power:
      final aPower = a.power;
      final bPower = b.power;
      if (aPower == null && bPower == null) {
        return a.moveId.compareTo(b.moveId);
      }
      if (aPower == null) return 1;
      if (bPower == null) return -1;
      final byPower = bPower.compareTo(aPower);
      return byPower != 0 ? byPower : a.moveId.compareTo(b.moveId);
    case MoveSort.name:
      final byZh = a.nameZh.compareTo(b.nameZh);
      if (byZh != 0) return byZh;
      return a.nameEn.compareTo(b.nameEn);
  }
}

/// formId → 该形态有学习集的版本组（新→旧）。
final learnsetVersionGroupsProvider =
    FutureProvider.autoDispose.family<List<VersionGroupRef>, int>((
  ref,
  formId,
) {
  return ref.watch(pokedexRepositoryProvider).getFormVersionGroups(formId);
});

/// learnset 查询参数（record 作 family 参数：字段值变化即触发重查询）。
typedef LearnsetQuery = (int formId, LearnsetFilter filter);

/// formId + 筛选 → 排序后的学习集。
///
/// versionGroup 为空时先解析默认（最新）版本组再查询。
final learnsetProvider =
    FutureProvider.autoDispose.family<List<MoveEntry>, LearnsetQuery>(
  (ref, query) async {
    final (formId, filter) = query;
    final repo = ref.watch(pokedexRepositoryProvider);
    var versionGroup = filter.versionGroup;
    if (versionGroup.isEmpty) {
      final groups = await repo.getFormVersionGroups(formId);
      if (groups.isEmpty) return const <MoveEntry>[];
      versionGroup = groups.first.id;
    }
    final moves = await repo.getLearnset(
      formId,
      versionGroup,
      methods: filter.methods.isEmpty ? null : filter.methods,
    );
    return [...moves]
      ..sort((a, b) => compareMoveEntries(a, b, filter.sort));
  },
);
