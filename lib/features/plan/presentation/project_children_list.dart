import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/enums/plan_item_state.dart';
import '../../../domain/models/item_time.dart';
import '../../../domain/models/plan_item.dart';
import '../../../shared/widgets/plan_item_row.dart';
import '../../disposition/presentation/dispose_from_ui.dart';
import '../providers/current_state_provider.dart';
import 'create_subitem_dialog.dart';

/// The CHILDREN section + add-sub-item row.
class ProjectChildrenList extends ConsumerWidget {
  const ProjectChildrenList({super.key, required this.project});

  final PlanItem project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<PlanItem> children = project.children;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('CHILDREN', style: AppTypography.eyebrow),
          const SizedBox(height: AppSpacing.sm),
          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                'No sub-items yet. Tap below to break this down.',
                style: AppTypography.bodyMuted,
              ),
            ),
          for (int i = 0; i < children.length; i++)
            _ChildRow(
              key: ValueKey<String>(children[i].id),
              child: children[i],
              showDivider: i < children.length - 1,
            ),
          const SizedBox(height: AppSpacing.sm),
          _AddSubItemRow(parentId: project.id),
        ],
      ),
    );
  }
}

class _ChildRow extends ConsumerWidget {
  const _ChildRow({
    super.key,
    required this.child,
    required this.showDivider,
  });

  final PlanItem child;
  final bool showDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PlanItemState> stateAsync =
    ref.watch(currentStateForProvider(planItemId: child.id));
    final PlanItemState state = stateAsync.maybeWhen(
      data: (PlanItemState s) => s,
      orElse: () => PlanItemState.planned,
    );

    return PlanItemRow(
      title: child.title,
      temperature: child.temperature,
      state: state,
      timeHint: _timeHintFor(child.time),
      showDivider: showDivider,
      onTap: () {
        if (child.children.isNotEmpty) {
          // Recurse into the sub-project.
          GoRouter.of(context).pushNamed(
            'plan',
            pathParameters: <String, String>{'rootId': child.id},
          );
        } else {
          // Drill into the confirmation detail.
          GoRouter.of(context).pushNamed(
            'confirm',
            pathParameters: <String, String>{'planItemId': child.id},
          );
        }
      },
      onDispositionTap: () async {
        await disposeFromUi(
          context: context,
          ref: ref,
          item: child,
          prompted: false,
        );
      },
    );
  }
}

class _AddSubItemRow extends StatelessWidget {
  const _AddSubItemRow({required this.parentId});

  final String parentId;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add a sub-item',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppSpacing.borderRadiusMedium,
          onTap: () async {
            await showCreateSubitemDialog(
              context: context,
              parentId: parentId,
            );
          },
          child: DottedBorder(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.add,
                      size: 18, color: AppColors.iconMuted),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Add a sub-item',
                    style: AppTypography.bodyMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Local dashed-border widget ──────────────────────────────────────────────
//
// We already wrote one for the ConfidenceChip's tentative state (Phase 03
// Part 02). Reusing that painter directly would couple two unrelated
// widgets. For the row's needs we instead apply a simple BoxDecoration
// with a manually-painted dashed border via a small CustomPainter.

class DottedBorder extends StatelessWidget {
  const DottedBorder({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(),
      child: child,
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  static const double _dash = 4;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = AppColors.borderStrong
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(AppSpacing.radiusMedium),
      ));
    final PathMetric metric = path.computeMetrics().first;
    double dist = 0.0;
    while (dist < metric.length) {
      final double end = (dist + _dash).clamp(0.0, metric.length);
      canvas.drawPath(metric.extractPath(dist, end), p);
      dist += _dash + _gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Time hint formatter (shared with TodayPeek; duplicated for now) ─────────

String? _timeHintFor(ItemTime time) {
  return time.when<String?>(
    hardTime: (DateTime at, _) {
      final DateTime local = at.toLocal();
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    },
    timeWindow: (DateTime? _, DateTime until) {
      final DateTime u = until.toLocal();
      return 'by ${u.month}/${u.day}';
    },
    recurring: (_, __, ___) => 'recurring',
    untimed: () => null,
  );
}