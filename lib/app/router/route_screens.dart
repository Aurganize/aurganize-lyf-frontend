import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions/datetime_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/enums/plan_item_type.dart';
import '../../domain/enums/temperature.dart';
import '../../domain/models/item_time.dart';
import '../../features/capture/presentation/editors/show_parent_picker.dart';
import '../../features/capture/presentation/editors/show_recurrence_editor.dart';
import '../../features/capture/presentation/editors/show_temperature_picker.dart';
import '../../features/capture/presentation/editors/show_time_editor.dart';
import '../../features/capture/presentation/editors/show_title_editor.dart';
import '../../features/capture/presentation/editors/show_type_picker.dart';
import '../../features/capture/presentation/parsed_card_view_model.dart';
import '../../features/capture/providers/plan_item_mutations.dart';
import '../../features/capture/services/card_action_service.dart';
import '../../features/capture/providers/capture_providers.dart';
import '../../features/disposition/presentation/disposition_action.dart';
import '../../shared/widgets/confirmation_detail_view.dart';

// ─────────────────────────────────────────────────────────────────────────────
// /confirm/:planItemId — the confirmation detail screen
// ─────────────────────────────────────────────────────────────────────────────

class ConfirmRouteScreen extends ConsumerWidget {
  const ConfirmRouteScreen({super.key, required this.planItemId});

  final String planItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Find the matching PendingCard by id. We pull from the pending
    // list because we have access to the source intention (for the
    // raw text quote block) and the plan item together.
    final AsyncValue<List<PendingCard>> pending =
    ref.watch(pendingCardsProvider);

    return pending.when(
      loading: () => const _ScreenWithSpinner(title: 'Confirm intention'),
      error: (Object e, _) =>
          _ScreenWithMessage(title: 'Confirm intention', message: 'Error: $e'),
      data: (List<PendingCard> cards) {
        final PendingCard? card = cards.firstWhereOrNull(
              (PendingCard c) => c.planItem.id == planItemId,
        );
        if (card == null) {
          // The plan item may have been confirmed / dismissed / dispositioned
          // between when the user tapped and when this builder ran.
          // Pop back gracefully.
          return _MissingPlanItemScreen(
            id: planItemId,
            onBack: () => GoRouter.of(context).pop(),
          );
        }
        return ConfirmationDetailView(
          viewModel: ParsedCardViewModelFactory.fromDomain(
            item: card.planItem,
            rawText: card.intention.rawText,
          ),
          onClose: () => GoRouter.of(context).pop(),
          onEditTitle: () async {
            final String? newTitle = await showTitleEditor(
              context: context,
              currentTitle: card.planItem.title,
            );
            if (newTitle != null) {
              await ref
                  .read(planItemMutationsProvider.notifier)
                  .updateTitle(card.planItem.id, newTitle);
            }
          },
          onEditAttribute: (ParsedAttribute attr) async {
            switch (attr.key) {
              case 'type':
                final PlanItemType? next = await showTypePicker(
                  context: context,
                  currentType: card.planItem.type,
                );
                if (next != null) {
                  await ref
                      .read(planItemMutationsProvider.notifier)
                      .updateType(card.planItem.id, next);
                }
              case 'time':
                final ItemTime? next = await showTimeEditor(
                  context: context,
                  currentTime: card.planItem.time,
                );
                if (next != null) {
                  await ref
                      .read(planItemMutationsProvider.notifier)
                      .updateTime(card.planItem.id, next);
                }
              case 'recurrence':
                final ItemTime? next = await showRecurrenceEditor(
                  context: context,
                  currentTime: card.planItem.time,
                );
                if (next != null) {
                  await ref
                      .read(planItemMutationsProvider.notifier)
                      .updateTime(card.planItem.id, next);
                }
              case 'parent':
                final result = await showParentPicker(
                  context: context,
                  excludeIds: <String>{card.planItem.id},
                );
                if (result != null && result.changed) {
                  await ref
                      .read(planItemMutationsProvider.notifier)
                      .updateParent(card.planItem.id, result.newParent?.id);
                }
              case 'temperature':
                final Temperature? next = await showTemperaturePicker(
                  context: context,
                  currentTemperature: card.planItem.temperature,
                );
                if (next != null) {
                  await ref
                      .read(planItemMutationsProvider.notifier)
                      .updateTemperature(card.planItem.id, next);
                }
            }
          },
          onConfirm: () async {
            await ref.read(cardActionServiceProvider).confirm(
              planItemId: card.planItem.id,
            );
            if (context.mounted) GoRouter.of(context).pop();
          },
          onDismiss: () async {
            await ref.read(cardActionServiceProvider).dismiss(
              planItemId: card.planItem.id,
              intentionId: card.intention.id,
            );
            if (context.mounted) GoRouter.of(context).pop();
          },
        );
      },
    );
  }
}

/// Tiny utility — Flutter's `firstWhere` throws when not found; we
/// re-implement the safe variant rather than depend on `collection`
/// at the route layer.
extension _FirstWhereOrNull<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E e) test) {
    for (final E e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

// ParsedCardViewModel _viewModelFor(PendingCard card) {
//   // Same adaption as in peek_card_stack.dart. Both files share this
//   // shape; in Phase 06 Part 01 we'll extract it into a single
//   // ParsedCardViewModel.fromDomain() factory.
//   return ParsedCardViewModel(
//     planItemId: card.planItem.id,
//     rawText: card.intention.rawText,
//     title: card.planItem.title,
//     titleConfidence: card.planItem.confidenceFor('title'),
//     attributes: const <ParsedAttribute>[],
//     // Empty for the stub — Phase 06 Part 01 fleshes out the
//     // attributes for the detail view. The peek-card stack already
//     // does this for its own purposes; we duplicate here only briefly.
//   );
// }

// ─────────────────────────────────────────────────────────────────────────────
// /plan/:rootId — project view stub
// ─────────────────────────────────────────────────────────────────────────────

class PlanRouteScreen extends StatelessWidget {
  const PlanRouteScreen({super.key, required this.rootId});

  final String rootId;

  @override
  Widget build(BuildContext context) {
    return _ScreenWithMessage(
      title: 'Project',
      message: 'Project view for $rootId — Phase 06 Part 03',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// /leftover/:bucket — leftover disposition stub
// ─────────────────────────────────────────────────────────────────────────────

class LeftoverRouteScreen extends StatelessWidget {
  const LeftoverRouteScreen({super.key, required this.dayBucket});

  final int dayBucket;

  @override
  Widget build(BuildContext context) {
    final DateTime date = DayBucket.asDateTime(dayBucket);
    return _ScreenWithMessage(
      title: 'Leftover',
      message:
      'Leftover view for ${date.year}-${date.month}-${date.day} — Phase 06 Part 04',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// /settings — settings screen stub
// ─────────────────────────────────────────────────────────────────────────────

class SettingsRouteScreen extends StatelessWidget {
  const SettingsRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ScreenWithMessage(
      title: 'Settings',
      message: 'Settings — Phase 06 Part 05',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared stub chrome
// ─────────────────────────────────────────────────────────────────────────────

class _ScreenWithSpinner extends StatelessWidget {
  const _ScreenWithSpinner({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ScreenWithMessage extends StatelessWidget {
  const _ScreenWithMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            message,
            style: AppTypography.bodyMuted,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _MissingPlanItemScreen extends StatelessWidget {
  const _MissingPlanItemScreen({required this.id, required this.onBack});

  final String id;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm intention')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'This card isn\'t available anymore. It may have been '
                  'confirmed or dismissed from another window.',
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: onBack,
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}