import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../core/di.dart';
import '../../domain/models/ability_ref.dart';
import '../../domain/models/form_summary.dart';
import '../../shared/responsive/breakpoints.dart';
import '../../shared/widgets/widgets.dart';
import 'detail_data.dart';
import 'evolution_section_placeholder.dart';
import 'moves_section_placeholder.dart';
import 'providers.dart';

/// 详情页立绘容器高（design-ui.md §3：expanded≈320；compact/medium 折叠
/// 头部内自适应展开）。
const double _kArtworkHeightExpanded = 320;

/// compact/medium 折叠头部展开后的目标高度（含工具栏）；
/// 超出可视高度时收窄，保证 pinned TabBar 之下始终留有内容空间。
const double _kHeaderExpandedHeight = 512;

/// 折叠头部的最小展开高度（矮视口兜底）。
const double _kHeaderMinHeight = 340;

/// 常驻 TabBar 高度附近值（折叠头部预留量计算用）。
const double _kTabBarExtent = 48;

/// 立绘解码参考宽（逻辑像素）：cacheWidth = 360 × dpr。
const int _kArtworkRefWidth = 360;

/// 说明正文最大宽（DESIGN.md §4：详情说明文本区 ≤ 640px）。
const double _kFlavorMaxWidth = 640;

/// 资料行标签列宽。
const double _kInfoLabelWidth = 56;

/// 种族值并排雷达图的最小区块宽（design-ui.md §4：宽 ≥840 右侧并排）。
const double _kStatsRadarBreakpoint = 840;

/// 世代序号中文（generation_id 1..N）。
const List<String> _kGenerationZh = [
  '一', '二', '三', '四', '五', '六', '七', '八', '九', '十',
];

String _generationLabel(int generationId) =>
    generationId >= 1 && generationId <= _kGenerationZh.length
        ? '第${_kGenerationZh[generationId - 1]}世代'
        : '第$generationId 世代';

/// 身高 / 体重显示：缺失或为 0 视为无数据（—），否则保留 1 位小数。
String _measureLabel(double? value, String unit) =>
    (value == null || value <= 0) ? '—' : '${value.toStringAsFixed(1)} $unit';

/// 宝可梦详情页（compact/medium 全页 Tab 布局；expanded 单页滚动分区；
/// 宽 ≥1080 的 master-detail 双栏由集成单元处理）。
class PokemonDetailPage extends ConsumerStatefulWidget {
  const PokemonDetailPage({
    super.key,
    required this.speciesId,
    this.showBackButton = true,
  });

  /// 路由参数不是合法整数时的「未找到」态。
  const PokemonDetailPage.notFound({super.key})
      : speciesId = null,
        showBackButton = true;

  /// null 表示路由参数非法（渲染未找到空态）。
  final int? speciesId;

  /// 是否展示返回入口（AppBar 自动 leading）。路由全页用默认 true；
  /// 嵌入双栏详情面板时传 false（面板无路由栈，不提供返回）。
  final bool showBackButton;

  @override
  ConsumerState<PokemonDetailPage> createState() =>
      _PokemonDetailPageState();
}

class _PokemonDetailPageState extends ConsumerState<PokemonDetailPage> {
  @override
  void initState() {
    super.initState();
    final speciesId = widget.speciesId;
    if (speciesId != null) {
      // 打开即记入最近浏览（仓储侧幂等：去重取最新）。放在微任务里，
      // 避免构建期间触发仓储状态变更。
      Future<void>.microtask(() {
        if (mounted) {
          ref.read(favoritesRepositoryProvider).addRecent(speciesId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final speciesId = widget.speciesId;
    if (speciesId == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          title: '未找到',
          message: '链接指向的宝可梦不存在，请返回图鉴重新选择。',
          action: TextButton(
            onPressed: () => context.go('/'),
            child: const Text('返回图鉴'),
          ),
        ),
      );
    }
    final detailAsync = ref.watch(pokemonDetailProvider(speciesId));
    return detailAsync.when(
      loading: () => const _DetailSkeleton(),
      error: (error, stackTrace) {
        if (error is SpeciesNotFoundException) {
          return Scaffold(
            appBar: AppBar(),
            body: EmptyState(
              title: '未找到',
              message: '图鉴里没有这只宝可梦，请返回图鉴重新选择。',
              action: TextButton(
                onPressed: () => context.go('/'),
                child: const Text('返回图鉴'),
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(),
          body: EmptyState(
            title: '加载失败',
            message: '数据读取出现问题，请检查本地数据后重试。',
            icon: Icons.error_outline,
            action: FilledButton(
              onPressed: () =>
                  ref.invalidate(pokemonDetailProvider(speciesId)),
              child: const Text('重试'),
            ),
          ),
        );
      },
      data: (detail) => _DetailScaffold(
        detail: detail,
        showBackButton: widget.showBackButton,
      ),
    );
  }
}

/// 整页骨架（头部结构等价的加载占位）。
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final pad = pagePaddingFor(context);
    final isExpanded =
        windowSizeFor(MediaQuery.sizeOf(context).width) == WindowSize.expanded;
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(pad, AppSpacing.s, pad, AppSpacing.xl),
        child: Skeleton(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(
                height:
                    isExpanded ? _kArtworkHeightExpanded : _kHeaderMinHeight - 80,
                borderRadius:
                    const BorderRadius.all(Radius.circular(AppRadius.card)),
              ),
              const SizedBox(height: AppSpacing.m),
              const SkeletonBox(height: 32, width: 96),
              const SizedBox(height: AppSpacing.s),
              const SkeletonBox(height: 22, width: 160),
              const SizedBox(height: AppSpacing.s),
              const SkeletonBox(height: 14, width: 200),
              const SizedBox(height: AppSpacing.m),
              const Row(
                children: [
                  SkeletonBox(width: 64, height: 26),
                  SizedBox(width: AppSpacing.s),
                  SkeletonBox(width: 64, height: 26),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const SkeletonBox(height: 160),
            ],
          ),
        ),
      ),
    );
  }
}

/// 详情页主体：解析选中形态并组织布局。
class _DetailScaffold extends ConsumerWidget {
  const _DetailScaffold({required this.detail, required this.showBackButton});

  final PokemonDetailData detail;

  /// false = 嵌入双栏详情面板：SliverAppBar 不自动补返回按钮。
  final bool showBackButton;

  static const _tabLabels = ['图鉴说明', '种族值', '进化', '招式', '资料'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId =
        ref.watch(selectedFormIdProvider(detail.speciesId));
    final selectedForm = resolveSelectedForm(detail.forms, selectedId);

    final pad = pagePaddingFor(context);
    final isExpanded =
        windowSizeFor(MediaQuery.sizeOf(context).width) == WindowSize.expanded;

    final header = _Header(
      detail: detail,
      selectedForm: selectedForm,
      artworkHeight: isExpanded ? _kArtworkHeightExpanded : null,
    );
    final formChips = _FormChips(detail: detail, selectedForm: selectedForm);
    final favoriteAction = _FavoriteAction(speciesId: detail.speciesId);

    if (!isExpanded) {
      // compact / medium：头部收进折叠式 SliverAppBar（滚动收起），
      // pinned TabBar + TabBarView 始终保有视口剩余空间。
      final expandedHeight = (MediaQuery.sizeOf(context).height - _kTabBarExtent)
          .clamp(_kHeaderMinHeight, _kHeaderExpandedHeight);
      return Scaffold(
        body: DefaultTabController(
          length: _tabLabels.length,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                pinned: true,
                expandedHeight: expandedHeight,
                automaticallyImplyLeading: showBackButton,
                actions: [favoriteAction],
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: EdgeInsets.fromLTRB(
                      pad,
                      kToolbarHeight,
                      pad,
                      AppSpacing.s,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: header),
                        formChips,
                      ],
                    ),
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(_tabLabels),
              ),
            ],
            body: TabBarView(
              children: [
                _tabPage(pad, _FlavorSection(speciesId: detail.speciesId)),
                _tabPage(pad, _StatsSection(selectedForm: selectedForm)),
                _tabPage(pad, const EvolutionSectionPlaceholder()),
                _tabPage(pad, const MovesSectionPlaceholder()),
                _tabPage(
                  pad,
                  _InfoSection(detail: detail, selectedForm: selectedForm),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // expanded：单页滚动 + SectionTitle 分区；twoPane 时本页嵌入
    // 右侧详情面板（showBackButton = false，无返回入口）。
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: showBackButton,
            actions: [favoriteAction],
          ),
          SliverPadding(
            padding:
                EdgeInsets.fromLTRB(pad, AppSpacing.s, pad, AppSpacing.xxl),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  formChips,
                  const SizedBox(height: AppSpacing.xl),
                  _FlavorSection(
                    speciesId: detail.speciesId,
                    showTitle: true,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _StatsSection(selectedForm: selectedForm),
                  const SizedBox(height: AppSpacing.xxl),
                  const EvolutionSectionPlaceholder(),
                  const SizedBox(height: AppSpacing.xxl),
                  const MovesSectionPlaceholder(),
                  const SizedBox(height: AppSpacing.xxl),
                  _InfoSection(
                    detail: detail,
                    selectedForm: selectedForm,
                    showTitle: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabPage(double pad, Widget child) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(pad, AppSpacing.m, pad, AppSpacing.xl),
        child: child,
      );
}

/// 常驻收藏心（AppBar action）。
///
/// 详情页是收藏主入口（FavoriteHeartButton 的触屏隐藏语义用于卡片/列表行，
/// 不适用于此），故未收藏时也常显描边心形。
class _FavoriteAction extends ConsumerWidget {
  const _FavoriteAction({required this.speciesId});

  final int speciesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoriteIdsProvider).value ?? const <int>[];
    final isFavorite = ids.contains(speciesId);
    return IconButton(
      tooltip: isFavorite ? '取消收藏' : '收藏',
      onPressed: () =>
          ref.read(favoritesRepositoryProvider).toggleFavorite(speciesId),
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite
            ? AppBrand.favoriteOf(context)
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// 头部：立绘 + 编号 + 中文名 + 英日文名 + 属性徽章 + 分类。
class _Header extends StatelessWidget {
  const _Header({
    required this.detail,
    required this.selectedForm,
    required this.artworkHeight,
  });

  final PokemonDetailData detail;
  final FormSummary selectedForm;

  /// 立绘容器固定高；null 表示在父级弹性空间内自适应填满
  /// （compact/medium 折叠头部场景）。
  final double? artworkHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 立绘回退：选中形态缺失时用默认形态的图（data-contract 的
    // missingArtwork 约定）；仍缺失则渲染占位图标。
    String? defaultFormArtwork;
    for (final form in detail.forms) {
      if (form.isDefault) {
        defaultFormArtwork = form.artworkAsset;
        break;
      }
    }
    final artworkPath = selectedForm.artworkAsset ?? defaultFormArtwork;
    final artwork = _Artwork(
      key: ValueKey(artworkPath),
      path: artworkPath,
      height: artworkHeight,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (artworkHeight == null) Expanded(child: artwork) else artwork,
        const SizedBox(height: AppSpacing.s),
        Text(
          formatDexNumber(detail.nationalDex),
          style: AppTypography.tabularFigures(
            textTheme.displaySmall ?? const TextStyle(),
          ).copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(detail.nameZhHans, style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${detail.nameEn} · ${detail.nameJa}',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.s),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            for (final typeId in selectedForm.typeIds)
              TypeBadge(type: typeId),
          ],
        ),
        if (detail.genusZh != null || detail.genusEn != null) ...[
          const SizedBox(height: AppSpacing.xs),
          // 分类 caption：简中优先，缺简中回退英文。
          Text(
            (detail.genusZh ?? detail.genusEn)!,
            style: textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

/// 立绘：150ms 淡入 + 8px 上移一次性动效（DESIGN.md §5），
/// 资产缺失时回退占位图标。
class _Artwork extends StatefulWidget {
  const _Artwork({
    super.key,
    required this.path,
    required this.height,
  });

  final String? path;

  /// 固定容器高；null 表示由父级（Expanded 等）决定。
  final double? height;

  @override
  State<_Artwork> createState() => _ArtworkState();
}

class _ArtworkState extends State<_Artwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
  );

  late final CurvedAnimation _curve =
      CurvedAnimation(parent: _controller, curve: AppMotion.curve);

  var _introPlayed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_introPlayed) {
      _introPlayed = true;
      _playIntro();
    }
  }

  @override
  void didUpdateWidget(covariant _Artwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _playIntro();
    }
  }

  void _playIntro() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Icon(
      Icons.image_not_supported_outlined,
      size: 48,
      color: scheme.onSurfaceVariant,
    );
    return Container(
      height: widget.height,
      width: double.infinity,
      alignment: Alignment.center,      child: widget.path == null
          ? placeholder
          : AnimatedBuilder(
              animation: _curve,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, 8 * (1 - _curve.value)),
                child: FadeTransition(opacity: _curve, child: child),
              ),
              child: Image.asset(
                widget.path!,
                cacheWidth: (_kArtworkRefWidth *
                        MediaQuery.devicePixelRatioOf(context))
                    .round(),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => placeholder,
              ),
            ),
    );
  }
}

/// 形态切换 chips：存在非默认形态时展示，VersionChip 样式横滚行。
class _FormChips extends ConsumerWidget {
  const _FormChips({required this.detail, required this.selectedForm});

  final PokemonDetailData detail;
  final FormSummary selectedForm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAltForms = detail.forms.any((form) => !form.isDefault);
    if (!hasAltForms) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        children: [
          for (final (index, form) in detail.forms.indexed) ...[
            VersionChip(
              label: form.formNameZh,
              selected: form.formId == selectedForm.formId,
              onTap: () => ref
                  .read(selectedFormIdProvider(detail.speciesId).notifier)
                  .state = form.formId,
            ),
            if (index != detail.forms.length - 1)
              const SizedBox(width: AppSpacing.s),
          ],
        ],
      ),
    );
  }
}

/// 常驻 TabBar（NestedScrollView pinned 头）。
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.labels);

  final List<String> labels;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  TabBar get _tabBar => TabBar(
        isScrollable: true,
        tabs: [for (final label in labels) Tab(text: label)],
      );

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // 底色遮住下方滚过的头部内容。
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) =>
      !const ListEquality<String>().equals(labels, oldDelegate.labels);
}

/// 图鉴说明分区：版本 chips（按世代分组，新→旧）+ 语言回退正文。
class _FlavorSection extends ConsumerWidget {
  const _FlavorSection({required this.speciesId, this.showTitle = false});

  final int speciesId;

  final bool showTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(flavorTextsProvider(speciesId));
    final selectedVersionId =
        ref.watch(flavorSelectionProvider(speciesId));
    final content = entriesAsync.when(
      loading: () => const Skeleton(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 14, width: 88),
            SizedBox(height: AppSpacing.m),
            SkeletonBox(height: 16, width: 120),
            SizedBox(height: AppSpacing.m),
            SkeletonBox(height: 14),
            SizedBox(height: AppSpacing.s),
            SkeletonBox(height: 14),
            SizedBox(height: AppSpacing.s),
            SkeletonBox(height: 14, width: 220),
          ],
        ),
      ),
      error: (error, stackTrace) => _SectionLoadError(
        onRetry: () => ref.invalidate(flavorTextsProvider(speciesId)),
      ),
      data: (entries) {
        final selection = resolveFlavorSelection(entries, selectedVersionId);
        final selected = selection.selected;
        if (selected == null) {
          // 皮卡丘在朱/紫等收录缺口之外的极端场景：整只无任何语言文本。
          return const EmptyState(
            title: '暂无图鉴说明',
            message: '这只宝可梦在已收录的游戏版本中没有图鉴说明文本。',
            icon: Icons.menu_book_outlined,
          );
        }
        return _FlavorContent(
          speciesId: speciesId,
          groups: selection.groups,
          selected: selected,
        );
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          const SectionTitle(title: '图鉴说明'),
          const SizedBox(height: AppSpacing.m),
        ],
        content,
      ],
    );
  }
}

class _FlavorContent extends ConsumerWidget {
  const _FlavorContent({
    required this.speciesId,
    required this.groups,
    required this.selected,
  });

  final int speciesId;
  final List<FlavorVersionGroup> groups;
  final FlavorVersion selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final displayEntry = selected.entryForDisplay();
    final fallbackLabel = flavorFallbackLanguageLabel(selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in groups) ...[
          Text(_generationLabel(group.generationId),
              style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              for (final version in group.versions)
                VersionChip(
                  label: version.label,
                  selected: version.versionId == selected.versionId,
                  onTap: () => ref
                      .read(flavorSelectionProvider(speciesId).notifier)
                      .state = version.versionId,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
        ],
        if (fallbackLabel != null) ...[
          Text(
            '该版本暂无简体中文资料 · 显示 $fallbackLabel',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.s),
        ],
        if (displayEntry != null)
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: _kFlavorMaxWidth,
              ),
              child: Text(
                displayEntry.text,
                style: textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
            ),
          ),
      ],
    );
  }
}

/// 种族值分区：StatBars（含总和徽章）；区块宽 ≥840 时右侧并排 StatRadar。
class _StatsSection extends ConsumerWidget {
  const _StatsSection({required this.selectedForm});

  final FormSummary selectedForm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDetailAsync = ref.watch(formDetailProvider(selectedForm));
    return formDetailAsync.when(
      loading: () => const Skeleton(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 20, width: 120),
            SizedBox(height: AppSpacing.m),
            SkeletonBox(height: 14),
            SizedBox(height: AppSpacing.s),
            SkeletonBox(height: 14),
            SizedBox(height: AppSpacing.s),
            SkeletonBox(height: 14),
            SizedBox(height: AppSpacing.s),
            SkeletonBox(height: 14),
            SizedBox(height: AppSpacing.s),
            SkeletonBox(height: 14),
            SizedBox(height: AppSpacing.s),
            SkeletonBox(height: 14),
          ],
        ),
      ),
      error: (error, stackTrace) => _SectionLoadError(
        onRetry: () => ref.invalidate(formDetailProvider(selectedForm)),
      ),
      data: (formDetail) => LayoutBuilder(
        builder: (context, constraints) {
          final bars = StatBars(stats: formDetail.stats);
          if (constraints.maxWidth < _kStatsRadarBreakpoint) {
            return bars;
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: bars),
              const SizedBox(width: AppSpacing.xl),
              StatRadar(stats: formDetail.stats, showValues: true),
            ],
          );
        },
      ),
    );
  }
}

/// 资料分区：身高 / 体重 / 世代 / 分类 / 特性。
class _InfoSection extends ConsumerWidget {
  const _InfoSection({
    required this.detail,
    required this.selectedForm,
    this.showTitle = false,
  });

  final PokemonDetailData detail;
  final FormSummary selectedForm;
  final bool showTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDetailAsync = ref.watch(formDetailProvider(selectedForm));
    final content = formDetailAsync.when(
      loading: () => const Skeleton(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 14),
            SizedBox(height: AppSpacing.s),
            SkeletonBox(height: 14),
            SizedBox(height: AppSpacing.s),
            SkeletonBox(height: 14),
          ],
        ),
      ),
      error: (error, stackTrace) => _SectionLoadError(
        onRetry: () => ref.invalidate(formDetailProvider(selectedForm)),
      ),
      data: (formDetail) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            label: '身高',
            value: _measureLabel(formDetail.heightM, 'm'),
          ),
          _InfoRow(
            label: '体重',
            value: _measureLabel(formDetail.weightKg, 'kg'),
          ),
          _InfoRow(label: '世代', value: _generationLabel(detail.generationId)),
          if (detail.genusZh != null || detail.genusEn != null)
            _InfoRow(
              label: '分类',
              value: (detail.genusZh ?? detail.genusEn)!,
            ),
          _InfoRow(
            label: '特性',
            value: null,
            child: formDetail.abilities.isEmpty
                ? const Text('—')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final ability in formDetail.abilities)
                        _AbilityTile(ability: ability),
                    ],
                  ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          const SectionTitle(title: '资料'),
          const SizedBox(height: AppSpacing.m),
        ],
        content,
      ],
    );
  }
}

/// 资料行：标签列 + 取值（[value] 文本或自定义 [child]；均缺省显示 —）。
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, this.value, this.child});

  final String label;

  final String? value;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _kInfoLabelWidth,
            child: Text(label, style: textTheme.labelMedium),
          ),
          Expanded(
            child: child ??
                Text(value ?? '—', style: textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// 特性行：有说明文本时可点按展开；仅英文说明时上方加 caption 提示。
class _AbilityTile extends StatefulWidget {
  const _AbilityTile({required this.ability});

  final AbilityRef ability;

  @override
  State<_AbilityTile> createState() => _AbilityTileState();
}

class _AbilityTileState extends State<_AbilityTile> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final ability = widget.ability;
    final description = ability.descriptionZh ?? ability.descriptionEn;

    final head = Row(
      children: [
        Text(ability.nameZh, style: textTheme.bodyMedium),
        if (ability.isHidden) ...[
          const SizedBox(width: AppSpacing.xs),
          const ConditionChip(label: '隐藏'),
        ],
        if (description != null) ...[
          const Spacer(),
          AnimatedRotation(
            turns: _expanded ? 0.5 : 0,
            duration: AppMotion.fast,
            curve: AppMotion.curve,
            child: Icon(
              Icons.expand_more,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    if (description == null) {
      // 无任何说明：仅名称，不可展开。
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: head,
      );
    }
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            head,
            if (_expanded) ...[
              const SizedBox(height: AppSpacing.xs),
              if (ability.descriptionZh == null) ...[
                Text('暂无简体中文说明', style: textTheme.bodySmall),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(
                description,
                style: textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 分区级加载失败：轻量文案 + 重试（整页失败走 EmptyState）。
class _SectionLoadError extends StatelessWidget {
  const _SectionLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '加载失败',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.s),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
