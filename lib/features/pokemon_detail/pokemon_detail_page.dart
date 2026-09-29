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
import 'detail_section_rail.dart';
import 'evolution_section_placeholder.dart';
import 'moves_section_placeholder.dart';
import 'providers.dart';
import 'speak_button.dart';

/// 详情页立绘容器高（design-ui.md §3：expanded≈320；compact/medium 折叠
/// 头部内自适应展开）。
const double _kArtworkHeightExpanded = 320;

/// 宽屏双列瀑布的内容宽阈值（design-ui.md §2）：滚动区宽 ≥1100 时五段
/// 分左右两列——左列「档案」（图鉴说明/种族值/资料），右列「对局」（进化/
/// 招式）；以下回退单列 + 锚点轨。取 1100：两列各 ≥538，compact 招式
/// tile 与说明 ≤640 的阅读宽都成立，对应窗口 ≥1204（内容 + 边距 + 轨）。
const double _kTwoColumnBreakpoint = 1100;

/// 双列瀑布的横排头部：立绘收成 180 高（竖排 320 让位给两列的信息密度），
/// 槽宽 260 容纳立绘不裁主体。
const double _kArtworkHeightTwoColumn = 180;
const double _kArtworkWidthTwoColumn = 260;

/// 双列瀑布的列宽档：种族值区宽 ≥520 时雷达改叠放在条形下方（§4）——
/// 双列的列宽落在 840 以下，若无此档雷达会在窄列里整块消失。
const double _kStatsRadarStackedBreakpoint = 520;

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

/// AppBar actions 行尾留白：M3 的 actionsPadding 默认 EdgeInsets.zero（SDK
/// 源码里挂着的已知问题 #155747），收藏心的 48×48 命中区整块贴到面板右缘
/// （双栏下即锚点轨分隔线），实机观感「离右边太近」。补 m(12) 让命中区
/// 离开边缘，视觉间隙 = 12（IconButton 自带的 hit-target 内边距）+ 12。
const EdgeInsets _kActionsEndPadding = EdgeInsets.only(right: AppSpacing.m);

/// 种族值并排雷达图的最小区块宽（design-ui.md §4：宽 ≥840 右侧并排）。
const double _kStatsRadarBreakpoint = 840;

/// 滑动切换的位移阈值（逻辑像素）：单次手势累计 |dx| 超过即触发切换。
const double _kSwipeDistanceThreshold = 72;

/// 滑动切换的速度阈值（逻辑像素/秒）：位移不足但快甩（|primaryVelocity|
/// 超过）也触发，与移动系统列表的快甩手感对齐。
const double _kSwipeVelocityThreshold = 700;

/// 切换方向：经路由 extra 传给 /pokemon/:speciesId 的过渡动画——
/// next（下一只）新页自右滑入，prev（上一只）新页自左滑入，
/// 与左右滑动 / ←/→ 键的翻页方向一致。
enum SpeciesSwitchDirection { next, prev }

/// 世代序号中文（generation_id 1..N）。
const List<String> _kGenerationZh = [
  '一',
  '二',
  '三',
  '四',
  '五',
  '六',
  '七',
  '八',
  '九',
  '十',
];

String _generationLabel(int generationId) =>
    generationId >= 1 && generationId <= _kGenerationZh.length
        ? '第${_kGenerationZh[generationId - 1]}世代'
        : '第$generationId 世代';

/// 身高 / 体重显示：缺失或为 0 视为无数据（—），否则保留 1 位小数。
String _measureLabel(double? value, String unit) =>
    (value == null || value <= 0) ? '—' : '${value.toStringAsFixed(1)} $unit';

/// 宝可梦详情页（compact/medium 全页 Tab 布局；expanded 单页滚动分区；
/// 宽 ≥1080 的 master-detail 双栏由集成单元处理）。全页支持滑动 /
/// ←/→ 键切上一只 / 下一只；双栏嵌入态无切换交互（[_embeddedInPane]）。
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
  ConsumerState<PokemonDetailPage> createState() => _PokemonDetailPageState();
}

class _PokemonDetailPageState extends ConsumerState<PokemonDetailPage> {
  /// 是否嵌入双栏详情面板（showBackButton=false 即嵌入态）：面板无路由
  /// 栈，也不提供键盘 / 滑动切换——左右布局下 ←/→ 与列表焦点互相抢占
  /// 且生效条件不可见，顺序浏览职责交还左列表（见 adaptive_scaffold）。
  bool get _embeddedInPane => !widget.showBackButton;

  /// 页面键盘锚点：全页路由模式下自动持焦；←/→ 仅在锚点自身持焦时
  /// 切换上/下一只，焦点在 Tab / 按钮等控件上时放行给默认焦点遍历
  /// （TabBar 左右箭头切 tab 的行为不受影响）。点按页面空白处会把焦点
  /// 收回锚点（见 build 里的 onTap），键盘切换因此不依赖初始 autofocus。
  final FocusNode _keyboardAnchor =
      FocusNode(debugLabel: 'pokemon_detail_keyboard_anchor');

  /// 编号序列解析出的相邻 speciesId（build 时刷新）；
  /// null = 边界禁用或序列未就绪。
  int? _prevSpeciesId;
  int? _nextSpeciesId;

  /// 当前水平手势的累计位移（onHorizontalDragUpdate 累加）。
  double _swipeDx = 0;

  /// 本次水平手势是否已触发过切换（一次手势最多切一只）。
  bool _swipeTriggered = false;

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

  /// 仅全页路由模式可达（双栏嵌入态不接键盘 / 拖拽切换）：
  /// pushReplacement 替换栈顶详情（列表页仍在栈底，返回键仍回列表；
  /// 不能 go——/pokemon/:id 是根级路由，go 会把栈重建成只剩详情，返回键
  /// 与底部导航随之消失）；新路由页重建，滚动位置自然回到顶部。
  /// extra 携带方向，路由侧据此播放自右 / 自左的方向性过渡。
  void _switchTo(
    int targetSpeciesId, {
    SpeciesSwitchDirection direction = SpeciesSwitchDirection.next,
  }) {
    context.pushReplacement('/pokemon/$targetSpeciesId', extra: direction);
  }

  /// 水平滑动切换（触摸设备）：向左滑 = 下一只，向右滑 = 上一只；
  /// 目标为 null（首尾边界）时原地不动。位移超阈值即触发；一次手势
  /// 最多触发一次（[_swipeTriggered] 防重），快甩由 dragEnd 兜底。
  void _handleSwipeUpdate(DragUpdateDetails details) {
    if (_swipeTriggered) {
      return;
    }
    _swipeDx += details.delta.dx;
    if (_swipeDx.abs() > _kSwipeDistanceThreshold) {
      _swipeTriggered = true;
      _switchToNeighbor(_swipeDx < 0);
    }
  }

  /// 快甩兜底：位移未达阈值但松手速度够快时同样切换。
  void _handleSwipeEnd(DragEndDetails details) {
    if (!_swipeTriggered) {
      final velocity = details.primaryVelocity;
      if (velocity != null && velocity.abs() > _kSwipeVelocityThreshold) {
        _swipeTriggered = true;
        _switchToNeighbor(velocity < 0);
      }
    }
    _resetSwipe();
  }

  void _resetSwipe() {
    _swipeDx = 0;
    _swipeTriggered = false;
  }

  /// [toNext] = 切下一只（滑动向左 / 快甩向左），否则切上一只。
  void _switchToNeighbor(bool toNext) {
    final target = toNext ? _nextSpeciesId : _prevSpeciesId;
    if (target != null) {
      _switchTo(
        target,
        direction:
            toNext ? SpeciesSwitchDirection.next : SpeciesSwitchDirection.prev,
      );
    }
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
    _switchTo(
      target,
      direction: event.logicalKey == LogicalKeyboardKey.arrowLeft
          ? SpeciesSwitchDirection.prev
          : SpeciesSwitchDirection.next,
    );
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
    // 双栏嵌入无切换交互，不解析相邻项。
    final dexOrder =
        _embeddedInPane ? null : ref.watch(speciesDexOrderProvider).valueOrNull;
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
              onPressed: () => ref.invalidate(pokemonDetailProvider(speciesId)),
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
    // 双栏嵌入：键盘 / 拖拽切换一概不接（见 [_embeddedInPane]），
    // 面板内空白点击也不再有收焦语义，直接渲染页面内容。
    if (_embeddedInPane) {
      return page;
    }
    // 全页路由：键盘锚点自动持焦；点在按钮 / Tab / 输入框上的 tap 被
    // 它们消费，其余空白处 tap 收回锚点，←/→ 随之恢复可用。
    return Focus(
      focusNode: _keyboardAnchor,
      autofocus: true,
      skipTraversal: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        // opaque：空白区域（非可点控件）也是命中目标，tap 收焦点与
        // 滑动切换在整个页面生效。
        behavior: HitTestBehavior.opaque,
        onTap: () => _keyboardAnchor.requestFocus(),
        onHorizontalDragUpdate: _handleSwipeUpdate,
        onHorizontalDragEnd: _handleSwipeEnd,
        onHorizontalDragCancel: _resetSwipe,
        child: page,
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
                height: isExpanded
                    ? _kArtworkHeightExpanded
                    : _kHeaderMinHeight - 80,
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
  });

  final PokemonDetailData detail;

  /// false = 嵌入双栏详情面板：SliverAppBar 不自动补返回按钮。
  final bool showBackButton;

  static const _tabLabels = ['图鉴说明', '种族值', '进化', '招式', '资料'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedFormIdProvider(detail.speciesId));
    final selectedForm = resolveSelectedForm(detail.forms, selectedId);

    final pad = pagePaddingFor(context);
    final isExpanded =
        windowSizeFor(MediaQuery.sizeOf(context).width) == WindowSize.expanded;

    // 返回键仅在真有路由栈时出现（与自动 leading 的 canPop 行为一致）；
    // 双栏面板（无路由栈）则无 leading。
    final canPop = showBackButton && Navigator.of(context).canPop();

    if (!isExpanded) {
      final header = _Header(
        detail: detail,
        selectedForm: selectedForm,
        artworkHeight: null,
      );
      final formChips = _FormChips(detail: detail, selectedForm: selectedForm);
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
                leading: canPop ? const BackButton() : null,
                actionsPadding: _kActionsEndPadding,
                actions: [
                  _FavoriteAction(speciesId: detail.speciesId),
                ],
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
                _tabPage(
                  pad,
                  EvolutionSectionPlaceholder(
                    speciesId: detail.speciesId,
                  ),
                ),
                _tabPage(
                  pad,
                  MovesSectionPlaceholder(speciesId: detail.speciesId),
                ),
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

    // expanded：单页滚动 + SectionTitle 分区 + 右侧锚点轨；twoPane 时本页
    // 嵌入右侧详情面板（showBackButton = false，无返回入口）。两种入口
    // 共用同一主体，锚点轨都常驻。
    return Scaffold(
      body: _ExpandedDetailBody(
        detail: detail,
        selectedForm: selectedForm,
        canPop: canPop,
        pad: pad,
      ),
    );
  }

  Widget _tabPage(double pad, Widget child) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(pad, AppSpacing.m, pad, AppSpacing.xl),
        child: child,
      );
}

/// expanded 单页滚动主体：pinned SliverAppBar + 五段分区（自上而下追加）
/// + 右侧常驻分区锚点轨。
///
/// 分区很长（招式段尤甚），锚点轨负责跳转与「现在在哪一段」的高亮；
/// 滚动几何见 [DetailSectionAnchorScroll]。
class _ExpandedDetailBody extends StatefulWidget {
  const _ExpandedDetailBody({
    required this.detail,
    required this.selectedForm,
    required this.canPop,
    required this.pad,
  });

  final PokemonDetailData detail;

  final FormSummary selectedForm;

  /// 是否展示返回入口（全页路由有栈为 true；双栏面板无栈）。
  final bool canPop;

  /// 页面水平留白（expanded = 24）。
  final double pad;

  @override
  State<_ExpandedDetailBody> createState() => _ExpandedDetailBodyState();
}

class _ExpandedDetailBodyState extends State<_ExpandedDetailBody> {
  final ScrollController _scrollController = ScrollController();
  final DetailSectionAnchorScroll _anchors = DetailSectionAnchorScroll();

  /// 当前激活段（锚点轨高亮 + 无障碍 selected）。
  var _activeIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // pinned header 高度随系统顶部 inset（状态栏 / 刘海）变化：跳转落点
    // 与高亮判定线都按它让位（见 [pinnedDetailHeaderHeight]）。
    _anchors.pinnedHeaderHeight = pinnedDetailHeaderHeight(context);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动经 [NotificationListener] 驱动而非 controller listener：钉定逻辑
  /// 要区分「用户拖拽」与「跳转动画的滚动」，通知的 dragDetails 与
  /// Start/End 活动边界才带活动来源（见
  /// [DetailSectionAnchorScroll.handleScrollNotification]）；判定同样推迟
  /// 到本帧布局完成，只在激活段变化时重建。
  bool _handleScrollNotification(ScrollNotification notification) => _anchors
      .handleScrollNotification(notification, _scrollController, _setActive);

  void _setActive(int index) {
    if (mounted && index != _activeIndex) {
      setState(() => _activeIndex = index);
    }
  }

  void _handleAnchorSelected(int index) =>
      _anchors.jumpTo(context, _scrollController, index, _setActive);

  /// 分区外包一层挂载点：锚点跳转 / 高亮都按分区顶部定位。
  Widget _section(int index, Widget child) =>
      KeyedSubtree(key: _anchors.sectionKeys[index], child: child);

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final selectedForm = widget.selectedForm;
    return Row(
      // stretch：锚点轨的分隔线与底色要贯穿整个面板高度。
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  automaticallyImplyLeading: false,
                  leading: widget.canPop ? const BackButton() : null,
                  actionsPadding: _kActionsEndPadding,
                  actions: [
                    _FavoriteAction(speciesId: detail.speciesId),
                  ],
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    widget.pad,
                    AppSpacing.s,
                    widget.pad,
                    AppSpacing.xxl,
                  ),
                  sliver: SliverToBoxAdapter(
                    // LayoutBuilder 取滚动区真实宽（面板宽 - 锚点轨 - 页边距）：
                    // 双列瀑布与单列共用同一组分段组件与锚点 key，只差排布。
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumn =
                            constraints.maxWidth >= _kTwoColumnBreakpoint;
                        // 锚点跟随口径随布局切换（twoColumn 取「最近过线段」
                        // 口径，见 rail 内注释）；写普通字段即可，无需重建。
                        _anchors.twoColumn = twoColumn;
                        return twoColumn
                            ? _TwoColumnDetail(
                                detail: detail,
                                selectedForm: selectedForm,
                                section: _section,
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _Header(
                                    detail: detail,
                                    selectedForm: selectedForm,
                                    artworkHeight: _kArtworkHeightExpanded,
                                  ),
                                  _FormChips(
                                    detail: detail,
                                    selectedForm: selectedForm,
                                  ),
                                  const SizedBox(height: AppSpacing.xl),
                                  _section(
                                    0,
                                    _FlavorSection(
                                      speciesId: detail.speciesId,
                                      selectedForm: selectedForm,
                                      showTitle: true,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xxl),
                                  _section(
                                    1,
                                    _StatsSection(selectedForm: selectedForm),
                                  ),
                                  const SizedBox(height: AppSpacing.xxl),
                                  _section(
                                    2,
                                    EvolutionSectionPlaceholder(
                                      speciesId: detail.speciesId,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xxl),
                                  _section(
                                    3,
                                    MovesSectionPlaceholder(
                                      speciesId: detail.speciesId,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xxl),
                                  _section(
                                    4,
                                    _InfoSection(
                                      detail: detail,
                                      selectedForm: selectedForm,
                                      showTitle: true,
                                    ),
                                  ),
                                ],
                              );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        DetailSectionRail(
          activeIndex: _activeIndex,
          onSelected: _handleAnchorSelected,
        ),
      ],
    );
  }
}

/// 宽屏双列瀑布（design-ui.md §2）：横排头部 + 左右两列，仅在滚动区宽
/// ≥ [_kTwoColumnBreakpoint] 时使用。
///
/// 列按信息聚类：左列「档案」（图鉴说明 / 种族值 / 资料），右列「对局」
/// （进化 / 招式）——招式折叠后两列高度接近，一屏即可总览。分区组件
/// 与单列分支完全同源，仍经 [section] 包锚点挂载点：跳转与高亮在
/// 双列下照常工作。
class _TwoColumnDetail extends StatelessWidget {
  const _TwoColumnDetail({
    required this.detail,
    required this.selectedForm,
    required this.section,
  });

  final PokemonDetailData detail;

  final FormSummary selectedForm;

  /// 页面状态提供的挂载点：给分区包锚点 key。
  final Widget Function(int index, Widget child) section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderHorizontal(detail: detail, selectedForm: selectedForm),
        const SizedBox(height: AppSpacing.l),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  section(
                    0,
                    _FlavorSection(
                      speciesId: detail.speciesId,
                      selectedForm: selectedForm,
                      showTitle: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  section(1, _StatsSection(selectedForm: selectedForm)),
                  const SizedBox(height: AppSpacing.xxl),
                  section(
                    4,
                    _InfoSection(
                      detail: detail,
                      selectedForm: selectedForm,
                      showTitle: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  section(
                    2,
                    EvolutionSectionPlaceholder(
                      speciesId: detail.speciesId,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  section(
                    3,
                    MovesSectionPlaceholder(speciesId: detail.speciesId),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 双列模式的横排头部：立绘居左，编号 / 名称 / 类型 / 分类与形态 chips
/// 居右。类型徽章行与竖排头部共用 [_TypeBadgesRow]。
class _HeaderHorizontal extends StatelessWidget {
  const _HeaderHorizontal({
    required this.detail,
    required this.selectedForm,
  });

  final PokemonDetailData detail;

  final FormSummary selectedForm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // 立绘回退：与 _Header 一致（选中形态缺失时用默认形态的图）。
    String? defaultFormArtwork;
    for (final form in detail.forms) {
      if (form.isDefault) {
        defaultFormArtwork = form.artworkAsset;
        break;
      }
    }
    final artworkPath = selectedForm.artworkAsset ?? defaultFormArtwork;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _kArtworkWidthTwoColumn,
          child: _Artwork(
            key: ValueKey(artworkPath),
            path: artworkPath,
            height: _kArtworkHeightTwoColumn,
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatDexNumber(detail.nationalDex),
                style: AppTypography.tabularFigures(
                  textTheme.headlineSmall ?? const TextStyle(),
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
              _TypeBadgesRow(selectedForm: selectedForm),
              if (detail.genusZh != null || detail.genusEn != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  (detail.genusZh ?? detail.genusEn)!,
                  style: textTheme.bodySmall,
                ),
              ],
              _FormChips(detail: detail, selectedForm: selectedForm),
            ],
          ),
        ),
      ],
    );
  }
}

/// 类型徽章行：Row 而非 Wrap——Wrap 给子项的是有界松约束，TypeBadge 内部
/// 的 alignment 容器会据此撑满整行（P1-b 全宽色带根因）；Flex 对非弹性
/// 子项宽度无界，徽章收缩为内容宽。属性最多 2 枚，无溢出。
class _TypeBadgesRow extends StatelessWidget {
  const _TypeBadgesRow({required this.selectedForm});

  final FormSummary selectedForm;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final typeId in selectedForm.typeIds) ...[
          if (typeId != selectedForm.typeIds.first)
            const SizedBox(width: AppSpacing.s),
          TypeBadge(type: typeId),
        ],
      ],
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
        _TypeBadgesRow(selectedForm: selectedForm),
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
      alignment: Alignment.center,
      child: widget.path == null
          ? placeholder
          : AnimatedBuilder(
              animation: _curve,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, 8 * (1 - _curve.value)),
                child: FadeTransition(opacity: _curve, child: child),
              ),
              child: Image.asset(
                widget.path!,
                cacheWidth:
                    (_kArtworkRefWidth * MediaQuery.devicePixelRatioOf(context))
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
    final selectedVersionId = ref.watch(flavorSelectionProvider(speciesId));
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
    // 朗读语言码：null = 不支持的文本语言（不渲染朗读按钮）。
    final ttsLanguage =
        displayEntry == null ? null : ttsLanguageCode(displayEntry.language);

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
        if (displayEntry != null) ...[
          // 版本标题行 + 行尾朗读按钮（与正文同宽 ≤640）。
          if (ttsLanguage != null) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: _kFlavorMaxWidth,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(selected.label, style: textTheme.bodySmall),
                  ),
                  SpeakButton(
                    text: displayEntry.text,
                    language: displayEntry.language,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
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
          final width = constraints.maxWidth;
          if (width < _kStatsRadarStackedBreakpoint) {
            return bars;
          }
          if (width < _kStatsRadarBreakpoint) {
            // 窄列档（双列瀑布的列宽）：雷达叠放在条形下方——信息不因
            // 列宽不足 840 而整块消失（design-ui.md §4）。
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bars,
                const SizedBox(height: AppSpacing.l),
                StatRadar(stats: formDetail.stats, showValues: true),
              ],
            );
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
        // 基线对齐而非顶部对齐：标签 labelMedium 与值 bodyMedium 字号不同，
        // 顶部对齐会让两侧首行文字基线错开（实机圈注「没对齐」）。「特性」
        // 行的值是 Column（多枚 _AbilityTile），Column 取首行文本的基线，
        // 标签恰与第一个特性名同线。
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: _kInfoLabelWidth,
            child: Text(label, style: textTheme.labelMedium),
          ),
          Expanded(
            child: child ?? Text(value ?? '—', style: textTheme.bodyMedium),
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
