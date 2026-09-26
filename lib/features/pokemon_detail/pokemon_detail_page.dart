import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../core/di.dart';
import '../../domain/models/ability_ref.dart';
import '../../domain/models/flavor_entry.dart';
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

/// compact/medium 折叠头部展开后的目标高度（含工具栏）：
/// 实际取视口高 ×0.5（clamp 300–440），保证 pinned TabBar 之下首屏
/// 始终留有可感知的内容空间（无需先收起头部）。
const double _kHeaderExpandedHeight = 440;

/// 折叠头部的最小展开高度（矮视口兜底）。
const double _kHeaderMinHeight = 300;

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
    this.onSwitchSpecies,
  });

  /// 路由参数不是合法整数时的「未找到」态。
  const PokemonDetailPage.notFound({super.key})
      : speciesId = null,
        showBackButton = true,
        onSwitchSpecies = null;

  /// null 表示路由参数非法（渲染未找到空态）。
  final int? speciesId;

  /// 是否展示返回入口（AppBar 自动 leading）。路由全页用默认 true；
  /// 嵌入双栏详情面板时传 false（面板无路由栈，不提供返回）。
  final bool showBackButton;

  /// 「上一只 / 下一只」切换到目标 species 的动作。null = 全页路由模式
  /// （`context.go('/pokemon/$id')` 替换栈顶，返回键仍回列表页）；
  /// 双栏详情面板由壳层注入「写双栏选中态」回调（features 互不 import，
  /// 见 adaptive_scaffold），切换不导航、左列表选中态随之跟随。
  final ValueChanged<int>? onSwitchSpecies;

  @override
  ConsumerState<PokemonDetailPage> createState() =>
      _PokemonDetailPageState();
}

class _PokemonDetailPageState extends ConsumerState<PokemonDetailPage> {
  /// 页面键盘锚点：全页路由模式下自动持焦；←/→ 仅在锚点自身持焦时
  /// 切换上/下一只，焦点在 Tab / 按钮等控件上时放行给默认焦点遍历
  /// （TabBar 左右箭头切 tab 的行为不受影响）。
  final FocusNode _keyboardAnchor =
      FocusNode(debugLabel: 'pokemon_detail_keyboard_anchor');

  /// 编号序列解析出的相邻 speciesId（build 时刷新）；
  /// null = 边界禁用或序列未就绪。
  int? _prevSpeciesId;
  int? _nextSpeciesId;

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
  void dispose() {
    _keyboardAnchor.dispose();
    super.dispose();
  }

  /// 由编号序列取当前 species 的相邻项（顺序 = national_dex，见
  /// data-contract：species.id 与 national_dex 一致）。
  void _resolveNeighbors(List<int>? order, int speciesId) {
    if (order == null) {
      _prevSpeciesId = null;
      _nextSpeciesId = null;
      return;
    }
    final index = order.indexOf(speciesId);
    _prevSpeciesId = index > 0 ? order[index - 1] : null;
    _nextSpeciesId =
        index >= 0 && index < order.length - 1 ? order[index + 1] : null;
  }

  void _switchTo(int targetSpeciesId) {
    final onSwitch = widget.onSwitchSpecies;
    if (onSwitch != null) {
      onSwitch(targetSpeciesId);
      return;
    }
    // 全页路由：go 替换栈顶（/pokemon/1 → /pokemon/2 保留列表页在栈底，
    // 返回键仍回列表）；新路由页重建，滚动位置自然回到顶部。
    context.go('/pokemon/$targetSpeciesId');
  }

  /// 页面级按键：仅锚点自身持焦时消费 ←/→；其余情况 ignored 让事件
  /// 继续冒泡（焦点在 Tab 上时由 WidgetsApp 默认快捷键走方向遍历）。
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (FocusManager.instance.primaryFocus != node) {
      return KeyEventResult.ignored;
    }
    final target = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => _prevSpeciesId,
      LogicalKeyboardKey.arrowRight => _nextSpeciesId,
      _ => null,
    };
    if (target == null) {
      // 边界禁用：按键原地吞掉（锚点是跳过遍历的叶子，无邻居可交给遍历）。
      return KeyEventResult.handled;
    }
    _switchTo(target);
    return KeyEventResult.handled;
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
    final dexOrder = ref.watch(speciesDexOrderProvider).valueOrNull;
    _resolveNeighbors(dexOrder, speciesId);
    final detailAsync = ref.watch(pokemonDetailProvider(speciesId));
    final page = detailAsync.when(
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
        prevSpeciesId: _prevSpeciesId,
        nextSpeciesId: _nextSpeciesId,
        onSwitchSpecies: _switchTo,
      ),
    );
    // 双栏嵌入不 autofocus：避免抢走列表面板搜索框的初始焦点；
    // 此时锚点不持焦，键盘切换自然由全页路由模式独占。
    return Focus(
      focusNode: _keyboardAnchor,
      autofocus: widget.showBackButton,
      skipTraversal: true,
      onKeyEvent: _handleKeyEvent,
      child: page,
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
  const _DetailScaffold({
    required this.detail,
    required this.showBackButton,
    required this.prevSpeciesId,
    required this.nextSpeciesId,
    required this.onSwitchSpecies,
  });

  final PokemonDetailData detail;

  /// false = 嵌入双栏详情面板：SliverAppBar 不自动补返回按钮。
  final bool showBackButton;

  /// 上一只 / 下一只的 speciesId（null = 边界禁用或序列未就绪）。
  final int? prevSpeciesId;
  final int? nextSpeciesId;

  final ValueChanged<int> onSwitchSpecies;

  static const _tabLabels = ['图鉴说明', '种族值', '进化', '招式', '资料'];

  /// 「上一只 / 下一只」两端对齐地挂在工具栏行：‹ 与返回键同排（leading），
  /// › 与收藏键同排（actions 首位），对应设计基线
  /// `← ‹ …… › ⭐`。
  List<Widget> _toolbarActions() => [
        _SpeciesSwitchButton(
          isPrevious: false,
          targetSpeciesId: nextSpeciesId,
          onSwitchSpecies: onSwitchSpecies,
        ),
        _FavoriteAction(speciesId: detail.speciesId),
      ];

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

    // 返回键仅在真有路由栈时出现（与自动 leading 的 canPop 行为一致）；
    // leadingWidth 装下「返回键 + 上一只」并排（48×2 + 余量），否则只装上一只。
    final canPop = showBackButton && Navigator.of(context).canPop();
    final leading = _DetailLeading(
      showBackButton: canPop,
      prevSpeciesId: prevSpeciesId,
      onSwitchSpecies: onSwitchSpecies,
    );

    if (!isExpanded) {
      // compact / medium：头部收进折叠式 SliverAppBar（滚动收起），
      // pinned TabBar + TabBarView 始终保有视口剩余空间。
      final expandedHeight = (MediaQuery.sizeOf(context).height * 0.5)
          .clamp(_kHeaderMinHeight, _kHeaderExpandedHeight);
      return Scaffold(
        body: DefaultTabController(
          length: _tabLabels.length,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                pinned: true,
                expandedHeight: expandedHeight,
                automaticallyImplyLeading: false,
                leading: leading,
                leadingWidth: canPop ? 104 : 48,
                actions: _toolbarActions(),
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
                _tabPage(
                  pad,
                  _FlavorSection(
                    speciesId: detail.speciesId,
                    selectedForm: selectedForm,
                  ),
                ),
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
            automaticallyImplyLeading: false,
            leading: leading,
            leadingWidth: canPop ? 104 : 48,
            actions: _toolbarActions(),
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
                    selectedForm: selectedForm,
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

/// AppBar leading：返回键（有路由栈时）+「上一只」并排，
/// 两端对齐基线的左端（`← ‹`）；SliverAppBar 的 leadingWidth 按是否
/// 带返回键给足 104 / 48。
class _DetailLeading extends StatelessWidget {
  const _DetailLeading({
    required this.showBackButton,
    required this.prevSpeciesId,
    required this.onSwitchSpecies,
  });

  /// 是否带返回键（Navigator.canPop，与自动 leading 行为一致）。
  final bool showBackButton;

  final int? prevSpeciesId;

  final ValueChanged<int> onSwitchSpecies;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // BackButton 默认行为即 Navigator.maybePop。
        if (showBackButton) const BackButton(),
        _SpeciesSwitchButton(
          isPrevious: true,
          targetSpeciesId: prevSpeciesId,
          onSwitchSpecies: onSwitchSpecies,
        ),
      ],
    );
  }
}

/// 「上一只 / 下一只」切换按钮：无目标（首尾边界 / 序列未就绪）时
/// 禁用置灰（onPressed null，走 Material 主题的 disabled 前景色）。
/// tooltip 即屏幕阅读器朗读的语义名称。
class _SpeciesSwitchButton extends StatelessWidget {
  const _SpeciesSwitchButton({
    required this.isPrevious,
    required this.targetSpeciesId,
    required this.onSwitchSpecies,
  });

  final bool isPrevious;

  final int? targetSpeciesId;

  final ValueChanged<int> onSwitchSpecies;

  @override
  Widget build(BuildContext context) {
    final target = targetSpeciesId;
    return IconButton(
      tooltip: isPrevious ? '上一只' : '下一只',
      onPressed: target == null ? null : () => onSwitchSpecies(target),
      icon: Icon(isPrevious ? Icons.chevron_left : Icons.chevron_right),
    );
  }
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
        // Row 而非 Wrap：Wrap 给子项的是有界松约束，TypeBadge 内部的
        // alignment 容器会据此撑满整行（P1-b 全宽色带根因）；Flex 对
        // 非弹性子项宽度无界，徽章收缩为内容宽。属性最多 2 枚，无溢出。
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final typeId in selectedForm.typeIds) ...[
              if (typeId != selectedForm.typeIds.first)
                const SizedBox(width: AppSpacing.s),
              TypeBadge(type: typeId),
            ],
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
///
/// 文本按形态归属（data-contract §6）：地区形态 → form 专属文本
/// （空则回退 species 级）；默认 / 其他形态 → species 级文本。
class _FlavorSection extends ConsumerWidget {
  const _FlavorSection({
    required this.speciesId,
    required this.selectedForm,
    this.showTitle = false,
  });

  final int speciesId;

  final FormSummary selectedForm;

  final bool showTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speciesAsync = ref.watch(flavorTextsProvider(speciesId));
    // 地区形态 watch 专属 provider：family 按 formId 区分，切换形态
    // 天然进入 loading，不会残留上一形态的旧文本。
    final AsyncValue<List<FlavorEntry>>? formAsync = selectedForm.isRegional
        ? ref.watch(formFlavorTextsProvider(selectedForm.formId))
        : null;
    final AsyncValue<List<FlavorEntry>> entriesAsync;
    if (formAsync == null) {
      entriesAsync = speciesAsync;
    } else {
      entriesAsync = switch (formAsync) {
        AsyncData(:final value) when value.isNotEmpty => formAsync,
        AsyncData() => speciesAsync, // 该形态无归属文本 → 回退 species 级
        _ => formAsync, // loading / error 保持当前形态自身状态
      };
    }
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
        onRetry: () {
          // 归属态下错误可能来自任一 provider，一并失效重试（幂等）。
          ref.invalidate(flavorTextsProvider(speciesId));
          if (formAsync != null) {
            ref.invalidate(formFlavorTextsProvider(selectedForm.formId));
          }
        },
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
