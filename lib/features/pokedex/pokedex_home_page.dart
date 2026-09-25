import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/tokens.dart';
import '../../core/di.dart';
import '../../domain/models/filters.dart';
import '../../domain/models/pokemon_summary.dart';
import '../../shared/responsive/breakpoints.dart';
import '../../shared/widgets/widgets.dart';
import 'providers.dart';

/// 图鉴首页（design-ui.md §1 / §7）：
///
/// - compact / medium：AppBar 内嵌搜索框 + 下方筛选 chip 行；
/// - expanded：标题行（「图鉴」+ 计数）+ 搜索框 + 同一筛选行；
/// - 列表：网格（PokemonCard）/ 列表（PokemonListTile），
///   滚动近底部自动追加下一页，底部细进度条表达加载中。
class PokedexHomePage extends ConsumerWidget {
  const PokedexHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = windowSizeFor(MediaQuery.sizeOf(context).width);
    return switch (size) {
      WindowSize.compact || WindowSize.medium => const _CompactLayout(),
      WindowSize.expanded => const _ExpandedLayout(),
    };
  }
}

/// compact / medium：搜索框收进 AppBar，筛选行挂在其 bottom。
class _CompactLayout extends StatelessWidget {
  const _CompactLayout();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.search),
        title: const _SearchField(),
        bottom: const _FilterBar(),
      ),
      body: const _PokemonListBody(),
    );
  }
}

/// expanded：标题 + 计数、搜索框、筛选行自上而下，列表占据余下空间。
class _ExpandedLayout extends ConsumerWidget {
  const _ExpandedLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pad = pagePaddingFor(context);
    final total = ref.watch(
      pokemonListProvider.select((async) => async.valueOrNull?.total),
    );
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(pad, AppSpacing.m, pad, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('图鉴', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(width: AppSpacing.s),
                    if (total != null)
                      Text(
                        '共 $total 只',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w400),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                const _SearchField(showLeadingIcon: true),
                const SizedBox(height: AppSpacing.s),
                const _FilterBar(),
              ],
            ),
          ),
          const Expanded(child: _PokemonListBody()),
        ],
      ),
    );
  }
}

/// 搜索框：200ms 防抖写入 [filterProvider.query]；外部清空筛选时
/// （清除按钮 / 面板重置）反向同步回输入框。
class _SearchField extends ConsumerStatefulWidget {
  const _SearchField({this.showLeadingIcon = false});

  /// expanded 独立搜索框自带放大镜；compact 的放大镜由 AppBar.leading 承担。
  final bool showLeadingIcon;

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  static const Duration _debounceDuration = Duration(milliseconds: 200);

  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _applyingExternal = false;

  @override
  void initState() {
    super.initState();
    final query = ref.read(filterProvider).query;
    if (query.isNotEmpty) {
      _controller.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_applyingExternal) {
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      ref.read(filterProvider.notifier).updateQuery(_controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FilterState>(filterProvider, (_, next) {
      if (_controller.text == next.query) {
        return;
      }
      // 外部变更（清空筛选）：覆盖输入框且不触发防抖。
      _debounce?.cancel();
      _applyingExternal = true;
      _controller.value = TextEditingValue(
        text: next.query,
        selection: TextSelection.collapsed(offset: next.query.length),
      );
      _applyingExternal = false;
    });

    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: '搜索 名称 / 编号',
        prefixIcon: widget.showLeadingIcon ? const Icon(Icons.search) : null,
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }
}

/// 筛选 chip 行：分组 chips 打开筛选 BottomSheet（激活态 primary + 计数），
/// 行尾固定视图切换与「清除筛选」（有筛选时出现）。
class _FilterBar extends ConsumerWidget implements PreferredSizeWidget {
  const _FilterBar();

  static const double height = 48;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterProvider);
    final viewMode = ref.watch(listViewModeProvider);
    final hasActive = !filter.isEmpty;

    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: pagePaddingFor(context)),
              child: Row(
                children: [
                  _FilterGroupChip(
                    label: '世代',
                    activeCount: filter.generations.length,
                    onTap: () => _openFilterSheet(context),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  _FilterGroupChip(
                    label: '属性',
                    activeCount: filter.typeIds.length,
                    onTap: () => _openFilterSheet(context),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  _FilterGroupChip(
                    label: '地区',
                    activeCount: filter.pokedexIds.length,
                    onTap: () => _openFilterSheet(context),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  _FilterGroupChip(
                    label: '特殊',
                    activeCount: filter.tags.length,
                    onTap: () => _openFilterSheet(context),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  _FilterGroupChip(
                    label: '编号',
                    activeCount:
                        filter.dexMin != null || filter.dexMax != null ? 1 : 0,
                    onTap: () => _openFilterSheet(context),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('view_mode_toggle'),
            tooltip: viewMode == PokemonViewMode.grid ? '列表视图' : '网格视图',
            icon: Icon(
              viewMode == PokemonViewMode.grid
                  ? Icons.view_list_outlined
                  : Icons.grid_view_outlined,
            ),
            onPressed: () =>
                ref.read(listViewModeProvider.notifier).toggle(),
          ),
          if (hasActive)
            IconButton(
              key: const ValueKey('clear_filters'),
              tooltip: '清除筛选',
              icon: const Icon(Icons.filter_alt_off_outlined),
              onPressed: () => ref.read(filterProvider.notifier).clear(),
            )
          else
            const SizedBox(width: AppSpacing.xl),
        ],
      ),
    );
  }

  void _openFilterSheet(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const _FilterSheet(),
      ),
    );
  }
}

/// 分组筛选 chip（行内）：激活时「标签·数量」并高亮。
class _FilterGroupChip extends StatelessWidget {
  const _FilterGroupChip({
    required this.label,
    required this.activeCount,
    required this.onTap,
  });

  final String label;
  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = activeCount > 0;
    return VersionChip(
      label: active ? '$label·$activeCount' : label,
      selected: active,
      onTap: onTap,
    );
  }
}

/// 列表主体：首载骨架 / 加载失败重试 / 空结果指引 / 分页网格或列表。
class _PokemonListBody extends ConsumerStatefulWidget {
  const _PokemonListBody();

  @override
  ConsumerState<_PokemonListBody> createState() => _PokemonListBodyState();
}

class _PokemonListBodyState extends ConsumerState<_PokemonListBody> {
  static const double _loadMoreThreshold = 600;
  static const double _gridMaxCrossAxisExtent = 200;
  static const double _gridAspectRatio = 0.82;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < _loadMoreThreshold) {
      unawaited(ref.read(pokemonListProvider.notifier).loadMore());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(pokemonListProvider);
    final viewMode = ref.watch(listViewModeProvider);
    final favoriteIds = ref
            .watch(favoriteSpeciesIdsProvider)
            .valueOrNull
            ?.toSet() ??
        const <int>{};
    final loading = asyncList.isLoading;
    final page = asyncList.valueOrNull;

    if (loading && page == null) {
      return _firstLoadSkeleton(context, viewMode);
    }
    if (asyncList.hasError && page == null) {
      return EmptyState(
        title: '加载失败',
        message: '图鉴数据读取出现问题，请重试。',
        icon: Icons.error_outline,
        action: FilledButton(
          onPressed: () =>
              ref.invalidate(pokemonListProvider),
          child: const Text('重试'),
        ),
      );
    }
    if (page == null) {
      return const SizedBox.shrink();
    }
    if (page.items.isEmpty) {
      return EmptyState(
        title: '没有匹配的宝可梦',
        message: '试试更换关键词，或清除筛选条件。',
        action: FilledButton(
          onPressed: () => ref.read(filterProvider.notifier).clear(),
          child: const Text('清除筛选'),
        ),
      );
    }

    final pad = pagePaddingFor(context);
    final isGrid = viewMode == PokemonViewMode.grid;
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  pad,
                  AppSpacing.m,
                  pad,
                  AppSpacing.m,
                ),
                sliver: isGrid
                    ? SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: _gridMaxCrossAxisExtent,
                          mainAxisSpacing: AppSpacing.m,
                          crossAxisSpacing: AppSpacing.m,
                          childAspectRatio: _gridAspectRatio,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildItem(
                            page.items[index],
                            favoriteIds,
                            isGrid: true,
                          ),
                          childCount: page.items.length,
                          addAutomaticKeepAlives: false,
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildItem(
                            page.items[index],
                            favoriteIds,
                            isGrid: false,
                          ),
                          childCount: page.items.length,
                          addAutomaticKeepAlives: false,
                        ),
                      ),
              ),
            ],
          ),
        ),
        // 追加下一页 / 筛选重载中：底部细进度条（DESIGN.md §6 不用大转圈）。
        if (loading) const LinearProgressIndicator(minHeight: 2),
      ],
    );
  }

  Widget _firstLoadSkeleton(BuildContext context, PokemonViewMode viewMode) {
    if (viewMode == PokemonViewMode.list) {
      return SkeletonList(
        itemCount: 12,
        padding: EdgeInsets.symmetric(horizontal: pagePaddingFor(context)),
      );
    }
    final width = MediaQuery.sizeOf(context).width;
    final pad = pagePaddingFor(context);
    final crossAxisCount =
        ((width - pad * 2 + AppSpacing.m) / (_gridMaxCrossAxisExtent + AppSpacing.m))
            .ceil()
            .clamp(1, 8);
    return SkeletonGrid(itemCount: 12, crossAxisCount: crossAxisCount);
  }

  Widget _buildItem(
    PokemonSummary summary,
    Set<int> favoriteIds, {
    required bool isGrid,
  }) {
    final isFavorite = favoriteIds.contains(summary.speciesId);
    void onOpen() {
      unawaited(
        ref.read(favoritesRepositoryProvider).addRecent(summary.speciesId),
      );
      context.push('/pokemon/${summary.speciesId}');
    }

    if (isGrid) {
      return PokemonCard(
        nationalDex: summary.nationalDex,
        nameZh: summary.nameZh,
        nameEn: summary.nameEn,
        typeIds: summary.typeIds,
        artworkAsset: summary.thumbAsset,
        isFavorite: isFavorite,
        onFavoriteToggle: (_) => unawaited(
          ref
              .read(favoritesRepositoryProvider)
              .toggleFavorite(summary.speciesId),
        ),
        onTap: onOpen,
      );
    }
    return PokemonListTile(
      nationalDex: summary.nationalDex,
      nameZh: summary.nameZh,
      nameEn: summary.nameEn,
      typeIds: summary.typeIds,
      thumbAsset: summary.thumbAsset,
      isFavorite: isFavorite,
      onFavoriteToggle: (_) => unawaited(
        ref
            .read(favoritesRepositoryProvider)
            .toggleFavorite(summary.speciesId),
      ),
      onTap: onOpen,
    );
  }
}

/// 筛选面板（design-ui.md §7）：分区 chips 多选，变更即时写入
/// [filterProvider] 并反映到列表；编号用双端滑杆（拖动结束才提交，
/// 避免拖动过程查询风暴）；「应用（N 只）」仅展示计数并关闭面板。
class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  static const double _dexMin = 1;
  static const double _dexMax = 1025;

  late RangeValues _range;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(filterProvider);
    _range = RangeValues(
      (filter.dexMin ?? _dexMin).toDouble(),
      (filter.dexMax ?? _dexMax).toDouble(),
    );
  }

  void _commitRange(RangeValues values) {
    final full = values.start <= _dexMin && values.end >= _dexMax;
    ref.read(filterProvider.notifier).setDexRange(
          min: full ? null : values.start.round(),
          max: full ? null : values.end.round(),
        );
  }

  void _resetAll() {
    ref.read(filterProvider.notifier).clear();
    setState(() {
      _range = const RangeValues(_dexMin, _dexMax);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(filterProvider);
    final refsAsync = ref.watch(pokedexRefsProvider);
    final total = ref.watch(
      pokemonListProvider.select((async) => async.valueOrNull?.total),
    );
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            maxWidth: 560,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xs,
              AppSpacing.xl,
              AppSpacing.l,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('筛选', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.s),
                Flexible(
                  child: SingleChildScrollView(
                    child: refsAsync.when(
                      data: (refs) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _sections(refs, filter),
                      ),
                      loading: () => const _SheetLoadingSections(),
                      error: (_, __) => _SheetRefsError(
                        onRetry: () => ref.invalidate(pokedexRefsProvider),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                Row(
                  children: [
                    TextButton(
                      onPressed: _resetAll,
                      child: const Text('重置'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(total == null ? '应用' : '应用 $total 只'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _sections(PokedexRefs refs, FilterState filter) {
    final notifier = ref.read(filterProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    return [
      _sectionTitle('世代'),
      _chipWrap([
        for (final generation in refs.generations)
          VersionChip(
            label: _generationLabel(generation.id),
            selected: filter.generations.contains(generation.id),
            onTap: () => notifier.toggleGeneration(generation.id),
          ),
      ]),
      _sectionTitle('属性'),
      _chipWrap([
        for (final type in refs.types)
          VersionChip(
            label: type.nameZh,
            selected: filter.typeIds.contains(type.id),
            onTap: () => notifier.toggleType(type.id),
          ),
      ]),
      const SizedBox(height: AppSpacing.s),
      SegmentedButton<TypeMatchMode>(
        segments: const [
          ButtonSegment(value: TypeMatchMode.any, label: Text('任一')),
          ButtonSegment(value: TypeMatchMode.all, label: Text('兼具')),
        ],
        selected: {filter.typeMatchMode},
        onSelectionChanged: (selection) =>
            notifier.setTypeMatchMode(selection.first),
      ),
      _sectionTitle('地区'),
      _chipWrap([
        for (final pokedex in refs.pokedexes)
          VersionChip(
            label: pokedex.nameZh,
            selected: filter.pokedexIds.contains(pokedex.id),
            onTap: () => notifier.togglePokedex(pokedex.id),
          ),
      ]),
      _sectionTitle('特殊'),
      _chipWrap([
        for (final tag in SpecialTag.values)
          VersionChip(
            label: _specialTagLabel(tag),
            selected: filter.tags.contains(tag),
            onTap: () => notifier.toggleTag(tag),
          ),
      ]),
      _sectionTitle('编号'),
      Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              '${_range.start.round()}',
              textAlign: TextAlign.end,
              style: AppTypography.tabularFigures(
                textTheme.bodySmall ?? const TextStyle(),
              ),
            ),
          ),
          Expanded(
            child: RangeSlider(
              values: _range,
              min: _dexMin,
              max: _dexMax,
              divisions: (_dexMax - _dexMin).round(),
              labels: RangeLabels(
                '${_range.start.round()}',
                '${_range.end.round()}',
              ),
              onChanged: (values) => setState(() {
                _range = values;
              }),
              onChangeEnd: _commitRange,
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${_range.end.round()}',
              style: AppTypography.tabularFigures(
                textTheme.bodySmall ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.l,
        bottom: AppSpacing.s,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _chipWrap(List<Widget> chips) {
    return Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      children: chips,
    );
  }
}

/// 引用数据未就绪时面板分区的骨架占位。
class _SheetLoadingSections extends StatelessWidget {
  const _SheetLoadingSections();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 3; i++) ...[
          const SkeletonBox(height: 16, width: 48),
          const SizedBox(height: AppSpacing.s),
          const SkeletonBox(height: 32),
          const SizedBox(height: AppSpacing.m),
        ],
      ],
    );
  }
}

/// 引用数据加载失败的占位与重试。
class _SheetRefsError extends StatelessWidget {
  const _SheetRefsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Text(
            '筛选数据加载失败',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.s),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

const List<String> _generationLabels = [
  '一', '二', '三', '四', '五', '六', '七', '八', '九',
];

String _generationLabel(int id) {
  if (id >= 1 && id <= _generationLabels.length) {
    return _generationLabels[id - 1];
  }
  return '第$id世代';
}

const Map<SpecialTag, String> _specialTagLabels = {
  SpecialTag.legendary: '传说',
  SpecialTag.mythical: '幻之',
  SpecialTag.ultraBeast: '究极异兽',
  SpecialTag.mega: '超级进化',
  SpecialTag.gmax: '超极巨',
  SpecialTag.regional: '地区形态',
};

String _specialTagLabel(SpecialTag tag) => _specialTagLabels[tag] ?? tag.name;
