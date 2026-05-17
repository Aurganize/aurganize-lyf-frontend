import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/repositories/repository_providers.dart';
import '../../../../domain/models/plan_item.dart';
import '../../../auth/auth_providers.dart';

/// Opens a picker for the parent of a plan item. Returns:
///   - A [PlanItem?] (null means "no parent" — top-level item).
///   - A sentinel `_NoChange` is NOT used; sheet dismissal returns null
///     too, which is fine: callers check whether the value differs
///     from the current parent.
///
/// The picker excludes [excludeIds] from the result list. Always pass
/// the item itself to prevent self-parenting; pass any of its descendants
/// to prevent cycles.
Future<({bool changed, PlanItem? newParent})?> showParentPicker({
  required BuildContext context,
  required Set<String> excludeIds,
}) {
  return showModalBottomSheet<({bool changed, PlanItem? newParent})?>(
    context: context,
    backgroundColor: AppColors.surfacePrimary,
    barrierColor: AppColors.scrim,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetCtx) {
      return _ParentPickerSheet(excludeIds: excludeIds);
    },
  );
}

class _ParentPickerSheet extends ConsumerWidget {
  const _ParentPickerSheet({required this.excludeIds});

  final Set<String> excludeIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (BuildContext _, ScrollController controller) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Text('PARENT', style: AppTypography.eyebrow),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: ListView(
                    controller: controller,
                    children: <Widget>[
                      _ParentOptionRow(
                        title: 'No parent (top-level)',
                        subtitle: 'Stand-alone item on your plan.',
                        onTap: () => Navigator.of(context).pop(
                          (changed: true, newParent: null),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('RECENT', style: AppTypography.eyebrow),
                      const SizedBox(height: AppSpacing.sm),
                      _RecentParentList(
                        excludeIds: excludeIds,
                        onPick: (PlanItem p) {
                          Navigator.of(context).pop(
                            (changed: true, newParent: p),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RecentParentList extends ConsumerWidget {
  const _RecentParentList({
    required this.excludeIds,
    required this.onPick,
  });

  final Set<String> excludeIds;
  final void Function(PlanItem) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pull from the user's recent intentions and unwrap to plan items.
    return FutureBuilder<List<PlanItem>>(
      future: _resolveRecentRoots(ref),
      builder: (BuildContext context, AsyncSnapshot<List<PlanItem>> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 80,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
          );
        }
        if (snap.hasError) {
          return Text('Couldn\'t load: ${snap.error}',
              style: AppTypography.bodyMuted);
        }
        final List<PlanItem> items = (snap.data ?? <PlanItem>[])
            .where((PlanItem p) => !excludeIds.contains(p.id))
            .toList(growable: false);
        if (items.isEmpty) {
          return Text(
            'You don\'t have any other items yet.',
            style: AppTypography.bodyMuted,
          );
        }
        return Column(
          children: <Widget>[
            for (int i = 0; i < items.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              _ParentOptionRow(
                title: items[i].title,
                subtitle: 'Tap to choose.',
                onTap: () => onPick(items[i]),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<List<PlanItem>> _resolveRecentRoots(WidgetRef ref) async {
    final String userId =
    await ref.read(currentUserIdProvider.future);
    final intentions = await ref
        .read(intentionRepositoryProvider)
        .findRecentForUser(userId, limit: 30);
    final List<PlanItem> roots = <PlanItem>[];
    for (final i in intentions) {
      final List<PlanItem> items = await ref
          .read(planItemRepositoryProvider)
          .findByIntention(i.id);
      for (final p in items) {
        if (p.parentId == null) roots.add(p);
      }
    }
    return roots;
  }
}

class _ParentOptionRow extends StatelessWidget {
  const _ParentOptionRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceTertiary,
      borderRadius: AppSpacing.borderRadiusMedium,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: AppTypography.body),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 20, color: AppColors.iconMuted),
            ],
          ),
        ),
      ),
    );
  }
}