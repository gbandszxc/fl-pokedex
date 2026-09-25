import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../core/di.dart';
import '../../domain/models/move_detail.dart';
import '../../shared/widgets/widgets.dart';

/// 招式详情（moveId → 数据；图鉴里没有该招式返回 null）。
final moveDetailProvider =
    FutureProvider.autoDispose.family<MoveDetail?, int>((ref, moveId) {
  return ref.watch(pokedexRepositoryProvider).getMoveDetail(moveId);
});

/// 世代序号中文（generation_id 1..N）。
const List<String> _kGenerationZh = [
  '一', '二', '三', '四', '五', '六', '七', '八', '九', '十',
];

String _generationLabel(int generationId) =>
    generationId >= 1 && generationId <= _kGenerationZh.length
        ? '第${_kGenerationZh[generationId - 1]}世代'
        : '第$generationId 世代';

String? _damageClassLabel(String damageClass) => switch (damageClass) {
      'physical' => '物理',
      'special' => '特殊',
      'status' => '变化',
      _ => null,
    };

/// 效果英文文本：effectChance 替换 `$effect_chance` 占位（源文本通常
/// 写作 `$effect_chance%`，连同百分号一起替换避免出现 %%）；
/// 文本不含占位时前置拼接（诚实呈现，不做中文翻译）。
String _effectText(MoveDetail detail) {
  final raw = detail.effectEn;
  if (raw == null || raw.isEmpty) return '';
  final chance = detail.effectChance;
  if (chance == null) return raw;
  if (raw.contains(r'$effect_chance%')) {
    return raw.replaceAll(r'$effect_chance%', '$chance%');
  }
  if (raw.contains(r'$effect_chance')) {
    return raw.replaceAll(r'$effect_chance', '$chance%');
  }
  return '$chance% $raw';
}

/// 招式详情全页（design-ui.md §6：点击招式行进入）。
class MoveDetailPage extends ConsumerWidget {
  const MoveDetailPage({super.key, required this.moveId});

  /// 路由参数不是合法整数时的「未找到」态。
  const MoveDetailPage.notFound({super.key}) : moveId = null;

  /// 图鉴说明引用块的检索 key（测试 / 查找用）。
  static const flavorQuoteKey = ValueKey('move-flavor-quote');

  /// null 表示路由参数非法（渲染未找到空态）。
  final int? moveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = moveId;
    if (id == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          title: '未找到',
          message: '链接指向的招式不存在，请返回图鉴重新选择。',
          action: TextButton(
            onPressed: () => context.go('/'),
            child: const Text('返回图鉴'),
          ),
        ),
      );
    }
    final detailAsync = ref.watch(moveDetailProvider(id));
    return Scaffold(
      // valueOrNull：error 态下 value 会抛异常，标题回退占位。
      appBar:
          AppBar(title: Text(detailAsync.valueOrNull?.nameZh ?? '招式详情')),
      body: detailAsync.when(
        loading: () => const _MoveDetailSkeleton(),
        error: (error, stackTrace) => EmptyState(
          title: '加载失败',
          message: '数据读取出现问题，请检查本地数据后重试。',
          icon: Icons.error_outline,
          action: FilledButton(
            onPressed: () => ref.invalidate(moveDetailProvider(id)),
            child: const Text('重试'),
          ),
        ),
        data: (detail) => detail == null
            ? EmptyState(
                title: '未找到',
                message: '图鉴里没有这个招式，请返回重新选择。',
                action: TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('返回图鉴'),
                ),
              )
            : _MoveDetailBody(detail: detail),
      ),
    );
  }
}

/// 整页骨架（标题 + 徽章 + 数据网格结构的等价占位）。
class _MoveDetailSkeleton extends StatelessWidget {
  const _MoveDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: const [
          SkeletonBox(height: 28, width: 160),
          SizedBox(height: AppSpacing.s),
          SkeletonBox(height: 14, width: 220),
          SizedBox(height: AppSpacing.l),
          SkeletonBox(height: 26, width: 120),
          SizedBox(height: AppSpacing.xl),
          SkeletonBox(height: 56),
          SizedBox(height: AppSpacing.xl),
          SkeletonBox(height: 96),
        ],
      ),
    );
  }
}

class _MoveDetailBody extends StatelessWidget {
  const _MoveDetailBody({required this.detail});

  final MoveDetail detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pad = pagePaddingFor(context);
    final damageLabel = _damageClassLabel(detail.damageClass);
    final effect = _effectText(detail);

    return ListView(
      padding: EdgeInsets.fromLTRB(pad, AppSpacing.l, pad, AppSpacing.xxl),
      children: [
        Text(detail.nameZh, style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text('${detail.nameEn} · ${detail.nameJa}',
            style: textTheme.bodySmall),
        const SizedBox(height: AppSpacing.m),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            TypeBadge(type: detail.typeId),
            if (damageLabel != null) ConditionChip(label: damageLabel),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statCell(textTheme, '威力', detail.power),
            _statCell(textTheme, '命中', detail.accuracy),
            _statCell(textTheme, 'PP', detail.pp),
            _statCell(textTheme, '优先度', detail.priority),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        Text(_generationLabel(detail.generationId),
            style: textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xl),
        Text('效果', style: textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        if (effect.isEmpty)
          Text('—', style: textTheme.bodyMedium)
        else ...[
          // MoveDetail 只有英文效果字段，凡有说明一律提示缺简中。
          Text(
            '暂无简体中文说明',
            style: textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Text(
                effect,
                style: textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
            ),
          ),
        ],
        if (detail.flavorZh != null && detail.flavorZh!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          // 官方简中说明引用块：整块底色 + 圆角 12（不用侧边彩条）。
          Container(
            key: MoveDetailPage.flavorQuoteKey,
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: ShapeDecoration(
              color: scheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              detail.flavorZh!,
              style: textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _statCell(TextTheme textTheme, String label, int? value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.labelSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value?.toString() ?? '—',
            style: AppTypography.tabularFigures(
              textTheme.titleSmall ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}
