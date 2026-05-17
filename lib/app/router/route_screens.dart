import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions/datetime_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/enums/plan_item_type.dart';
import '../../domain/enums/temperature.dart';
import '../../domain/models/intention.dart';
import '../../domain/models/item_time.dart';
import '../../domain/models/plan_item.dart';
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
import '../../features/disposition/presentation/dispose_from_ui.dart';
import '../../features/disposition/presentation/disposition_action.dart';
import '../../features/plan/presentation/project_screen.dart';
import '../../shared/widgets/confirmation_detail_view.dart';

// ─────────────────────────────────────────────────────────────────────────────
// /confirm/:planItemId — the confirmation detail screen
// ─────────────────────────────────────────────────────────────────────────────

class ConfirmRouteScreen extends ConsumerWidget {
  const ConfirmRouteScreen({super.key, required this.planItemId});

  final String planItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // First, try the pending cards (the most common case after parsing).
    final AsyncValue<List<PendingCard>> pending =
    ref.watch(pendingCardsProvider);

    return pending.when(
      loading: () => const _ScreenWithSpinner(title: 'Confirm intention'),
      error: (Object e, _) =>
          _ScreenWithMessage(title: 'Confirm intention', message: 'Error: $e'),
      data: (List<PendingCard> cards) {
        final PendingCard? pendingCard = cards.firstWhereOrNull(
              (PendingCard c) => c.planItem.id == planItemId,
        );
        if (pendingCard != null) {
          // Unconfirmed (pending) card — full edit + confirm/dismiss flow.
          return _ConfirmDetailContent(card: pendingCard, isPending: true);
        }
        // Fallback — already confirmed or otherwise not in the pending set.
        // Load directly.
        return _LoadFromDb(planItemId: planItemId);
      },
    );
  }
}

/// Loads a plan item directly and renders the detail with "check in"
/// instead of confirm/dismiss.
class _LoadFromDb extends ConsumerWidget {
  const _LoadFromDb({required this.planItemId});

  final String planItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PlanItem?> item =
    ref.watch(planItemByIdProvider(planItemId: planItemId));
    return item.when(
      loading: () => const _ScreenWithSpinner(title: 'Plan item'),
      error: (Object e, _) =>
          _ScreenWithMessage(title: 'Plan item', message: 'Error: $e'),
      data: (PlanItem? p) {
        if (p == null) {
          return _MissingPlanItemScreen(
            id: planItemId,
            onBack: () => GoRouter.of(context).pop(),
          );
        }
        // Look up the intention so we can show the raw text.
        return Consumer(
          builder: (BuildContext context, WidgetRef ref, _) {
            final AsyncValue<Intention?> intention = ref.watch(
              intentionByIdProvider(intentionId: p.intentionId),
            );
            return intention.when(
              loading: () => const _ScreenWithSpinner(title: 'Plan item'),
              error: (Object e, _) =>
                  _ScreenWithMessage(title: 'Plan item', message: 'Error: $e'),
              data: (Intention? i) {
                if (i == null) {
                  // Intention was deleted (e.g. via Settings → wipe);
                  // the plan item should have been too via FK cascade.
                  // Defensive: show missing.
                  return _MissingPlanItemScreen(
                    id: planItemId,
                    onBack: () => GoRouter.of(context).pop(),
                  );
                }
                final card = PendingCard(intention: i, planItem: p);
                return _ConfirmDetailContent(card: card, isPending: false);
              },
            );
          },
        );
      },
    );
  }
}

/// The shared body — knows how to render the detail view both for
/// pending cards and for already-confirmed items.
class _ConfirmDetailContent extends ConsumerWidget {
  const _ConfirmDetailContent({
    required this.card,
    required this.isPending,
  });

  final PendingCard card;
  final bool isPending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        // ... same body as before — Phase 06 Part 01 ...
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
            break;
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
            break;
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
            break;
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
            break;
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
            break;
        }
      },
      onConfirm: isPending
          ? () async {
        await ref.read(cardActionServiceProvider).confirm(
          planItemId: card.planItem.id,
        );
        if (context.mounted) GoRouter.of(context).pop();
      }
          : () => GoRouter.of(context).pop(), // already confirmed; just close
      onDismiss: isPending
          ? () async {
        await ref.read(cardActionServiceProvider).dismiss(
          planItemId: card.planItem.id,
          intentionId: card.intention.id,
        );
        if (context.mounted) GoRouter.of(context).pop();
      }
          : () => GoRouter.of(context).pop(), // already confirmed; just close
      onCheckIn: isPending
          ? null
          : () async {
        await disposeFromUi(
          context: context,
          ref: ref,
          item: card.planItem,
          prompted: false,
        );
      },
      confirmLabel: isPending ? 'Add to plan' : 'Done',
      dismissLabel: isPending ? 'Dismiss' : 'Close',
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
    return ProjectScreen(rootId: rootId);
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