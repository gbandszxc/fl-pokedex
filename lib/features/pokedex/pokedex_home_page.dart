import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/tokens.dart';
import '../../core/di.dart';
import '../../domain/models/filters.dart';
import '../../domain/models/pokemon_summary.dart';
import '../../shared/responsive/breakpoints.dart';
import '../../shared/widgets/widgets.dart';
import '../settings/providers.dart';
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
    return _HomeKeyboardScope(
      builder: (context, searchController, searchFocus) => Scaffold(
        appBar: AppBar(
          leading: const Icon(Icons.search),
          title: _SearchField(
            controller: searchController,
            focusNode: searchFocus,
          ),
          bottom: const _FilterBar(),
        ),
        body: const _PokemonListBody(embeddedInPane: false),
      ),
    );
  }
}

/// expanded：标题 + 计数、搜索框、筛选行自上而下，列表占据余下空间。
class _ExpandedLayout extends StatelessWidget {
  const _ExpandedLayout();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PokedexHomeListContent(embeddedInPane: false),
    );
  }
}

/// 图鉴列表内容：标题行（「图鉴」+ 计数）+ 搜索框 + 筛选行 + 列表主体。
///
/// expanded 首页整页与 twoPane（宽 ≥1080）双栏的列表面板共用，
/// 保证搜索 / 筛选 / 网格 / 分页的单一代码路径；[embeddedInPane]
/// 决定点按卡片的去向——写入双栏选中态（不导航）或推入详情路由。
class PokedexHomeListContent extends ConsumerWidget {
  const PokedexHomeListContent({super.key, required this.embeddedInPane});

  final bool embeddedInPane;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pad = pagePaddingFor(context);
    final total = ref.watch(
      pokemonListProvider.select((async) => async.valueOrNull?.total),
    );
    return _HomeKeyboardScope(
      builder: (context, searchController, searchFocus) => Column(
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
                _SearchField(
                  controller: searchController,
                  focusNode: searchFocus,
                  showLeadingIcon: true,
                ),
                const SizedBox(height: AppSpacing.s),
                const _FilterBar(),
              ],
            ),
          ),
          Expanded(
            child: _PokemonListBody(embeddedInPane: embeddedInPane),
          ),
        ],
      ),
    );
  }
}

/// 首页键盘作用域（桌面）：`/` 聚焦搜索框，Esc 清空搜索并失焦。
///
/// 拥有搜索框的 [TextEditingController] 与 [FocusNode]；输入变更的
/// 防抖与外部同步逻辑仍留在 [_SearchField]。内部的 Focus(autofocus)
/// 是键盘锚点：无控件持有焦点时按键也能沿焦点链命中上面的 Shortcuts。
class _HomeKeyboardScope extends ConsumerStatefulWidget {
  const _HomeKeyboardScope({required this.builder});

  final Widget Function(
    BuildContext context,
    TextEditingController searchController,
    FocusNode searchFocus,
  ) builder;

  @override
  ConsumerState<_HomeKeyboardScope> createState() =>
      _HomeKeyboardScopeState();
}

class _HomeKeyboardScopeState extends ConsumerState<_HomeKeyboardScope> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _focusSearch() {
    _searchFocus.requestFocus();
  }

  void _clearSearch() {
    // 直接写 provider：立即触发列表重载（不等输入框 200ms 防抖）；
    // 未提交的防抖词被下面 clear() 触发的重排取消。
    ref.read(filterProvider.notifier).updateQuery('');
    _searchController.clear();
    _searchFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.slash): _FocusSearchIntent(),
        SingleActivator(LogicalKeyboardKey.escape): _ClearSearchIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(
            onInvoke: (_) {
              _focusSearch();
              return null;
            },
          ),
          _ClearSearchIntent: CallbackAction<_ClearSearchIntent>(
            onInvoke: (_) {
              _clearSearch();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          skipTraversal: true,
          child: widget.builder(context, _searchController, _searchFocus),
        ),
      ),
    );
  }
}

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class _ClearSearchIntent extends Intent {
  const _ClearSearchIntent();
}

/// 搜索框：200ms 防抖写入 [filterProvider.query]；外部清空筛选时
/// （清除按钮 / 面板重置 / Esc）反向同步回输入框。
class _SearchField extends ConsumerStatefulWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    this.showLeadingIcon = false,
  });

  /// 由 [_HomeKeyboardScope] 持有（Esc 清空 / `/` 聚焦共用）。
  final TextEditingController controller;

  /// 由 [_HomeKeyboardScope] 持有。
  final FocusNode focusNode;

  /// expanded 独立搜索框自带放大镜；compact 的放大镜由 AppBar.leading 承担。
  final bool showLeadingIcon;

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  static const Duration _debounceDuration = Duration(milliseconds: 200);

  Timer? _debounce;
  bool _applyingExternal = false;

  @override
  void initState() {
    super.initState();
    final query = ref.read(filterProvider).query;
    if (query.isNotEmpty) {
      widget.controller.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_applyingExternal) {
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      ref
          .read(filterProvider.notifier)
          .updateQuery(widget.controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FilterState>(filterProvider, (_, next) {
      if (widget.controller.text == next.query) {
        return;
      }
      // 外部变更（清空筛选）：覆盖输入框且不触发防抖。
      _debounce?.cancel();
      _applyingExternal = true;
      widget.controller.value = TextEditingValue(
        text: next.query,
        selection: TextSelection.collapsed(offset: next.query.length),
      );
      _applyingExternal = false;
    });

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
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
    widget.controller.removeListener(_onTextChanged);
    // controller / focusNode 归 [_HomeKeyboardScope] 所有，不在此释放。
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
    // 「地区」入口计数=选中的地区组数；引用未就绪时退化为「有无选中」，
    // 避免把卡洛斯 3 条子图鉴 id 误计成 3。
    final regionRefs = ref.watch(pokedexRefsProvider).valueOrNull;
    final regionActiveCount = regionRefs == null
        ? (filter.pokedexIds.isEmpty ? 0 : 1)
        : regionRefs.regionGroups
            .where((group) => group.isSelected(filter))
            .length;

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
                    activeCount: regionActiveCount,
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
///
/// [embeddedInPane] 为 true 时运行在双栏列表面板内：点卡片写入
/// [paneSelectionProvider]（不导航），并为选中项绘制 primary 描边。
class _PokemonListBody extends ConsumerStatefulWidget {
  const _PokemonListBody({required this.embeddedInPane});

  final bool embeddedInPane;

  @override
  ConsumerState<_PokemonListBody> createState() => _PokemonListBodyState();
}

class _PokemonListBodyState extends ConsumerState<_PokemonListBody> {
  static const double _loadMoreThreshold = 600;

  /// 网格卡片最大宽——舒适档（DESIGN.md §3）。
  static const double _gridComfortableExtent = 200;

  /// 网格卡片最大宽——紧凑档（设置「桌面卡片密度」）。
  static const double _gridCompactExtent = 156;

  /// 网格卡片固定高——舒适档：等价于 200 宽 × 0.82 比例的自然高。
  /// 两档密度均弃用宽高比改用固定高：列宽随窗口浮动，比例高会小于
  /// 卡片内容最小高（PokemonCard ≈190）导致纵向溢出（小屏必现）。
  static const double _gridComfortableMainAxisExtent = 244;

  /// 网格卡片固定高——紧凑档（卡片更窄，同理必须固定高）。
  static const double _gridCompactMainAxisExtent = 200;

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
    final density = ref.watch(cardDensityProvider);
    // 桌面卡片密度（design-ui.md §8）：舒适 200 / 紧凑 156；列表模式不受影响。
    final gridMaxExtent = density == CardDensity.compact
        ? _gridCompactExtent
        : _gridComfortableExtent;
    final selectedSpeciesId =
        widget.embeddedInPane ? ref.watch(paneSelectionProvider) : null;
    final favoriteIds = ref
            .watch(favoriteSpeciesIdsProvider)
            .valueOrNull
            ?.toSet() ??
        const <int>{};
    final loading = asyncList.isLoading;
    final page = asyncList.valueOrNull;

    if (loading && page == null) {
      return _firstLoadSkeleton(context, viewMode, gridMaxExtent);
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
    final compactDensity = density == CardDensity.compact;
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
                            SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: gridMaxExtent,
                          mainAxisSpacing: AppSpacing.m,
                          crossAxisSpacing: AppSpacing.m,
                          // 固定卡高（见 _gridComfortableMainAxisExtent
                          // 注释），任意列宽下不再纵向溢出。
                          mainAxisExtent: compactDensity
                              ? _gridCompactMainAxisExtent
                              : _gridComfortableMainAxisExtent,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildItem(
                            page.items[index],
                            favoriteIds,
                            isGrid: true,
                            selectedSpeciesId: selectedSpeciesId,
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
                            selectedSpeciesId: selectedSpeciesId,
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

  Widget _firstLoadSkeleton(
    BuildContext context,
    PokemonViewMode viewMode,
    double gridMaxExtent,
  ) {
    if (viewMode == PokemonViewMode.list) {
      return SkeletonList(
        itemCount: 12,
        padding: EdgeInsets.symmetric(horizontal: pagePaddingFor(context)),
      );
    }
    final width = MediaQuery.sizeOf(context).width;
    final pad = pagePaddingFor(context);
    final crossAxisCount =
        ((width - pad * 2 + AppSpacing.m) / (gridMaxExtent + AppSpacing.m))
            .ceil()
            .clamp(1, 8);
    return SkeletonGrid(itemCount: 12, crossAxisCount: crossAxisCount);
  }

  Widget _buildItem(
    PokemonSummary summary,
    Set<int> favoriteIds, {
    required bool isGrid,
    required int? selectedSpeciesId,
  }) {
    final isFavorite = favoriteIds.contains(summary.speciesId);
    void onOpen() {
      unawaited(
        ref.read(favoritesRepositoryProvider).addRecent(summary.speciesId),
      );
      if (widget.embeddedInPane) {
        // 双栏列表面板：写选中态，详情在右侧面板内联渲染。
        ref.read(paneSelectionProvider.notifier).state = summary.speciesId;
        return;
      }
      context.push('/pokemon/${summary.speciesId}');
    }

    final Widget item;
    if (isGrid) {
      item = PokemonCard(
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
    } else {
      item = PokemonListTile(
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

    if (selectedSpeciesId != summary.speciesId) {
      return item;
    }
    // 双栏选中描边（DESIGN.md §2：细线 accent ≤2px）画在前景，避免被
    // 卡片底色盖住。
    return Container(
      foregroundDecoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.card)),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      child: item,
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
        for (final group in refs.regionGroups)
          VersionChip(
            label: group.labelZh,
            selected: group.isSelected(filter),
            onTap: () => notifier.togglePokedexGroup(group.ids),
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
