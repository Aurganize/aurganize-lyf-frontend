import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/logger.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/enums/plan_item_state.dart';
import '../../../domain/repositories/plan_item_repository.dart';
import '../presentation/disposition_action.dart';
import 'disposition_toast.dart';

part 'disposition_controller.g.dart';

/// Records a disposition for the supplied plan item.
///
/// Usage:
///
/// ```dart
/// final result = await ref.read(dispositionControllerProvider.notifier)
///   .dispose(
///     planItemId: id,
///     action: DispositionAction.done,
///     prompted: true,
///   );
/// ```
///
/// Returns the [PlanItemState] visible to consumers after the action
/// (e.g. `done` for done, `planned` for push-to-tomorrow).
///
/// Throws [StateError] if the repository rejects the disposition for
/// a stale `priorState` — generally because another tab or another
/// device beat us to the change. The screen should refresh and
/// optionally inform the user.
@riverpod
class DispositionController extends _$DispositionController {
  static final Logger _log = appLogger('Disposition');

  @override
  void build() {
    // Stateless notifier — see notes on QuestionRotator.
  }

  Future<PlanItemState> dispose({
    required String planItemId,
    required DispositionAction action,
    required bool prompted,
  }) async {
    final PlanItemRepository repo = ref.read(planItemRepositoryProvider);
    final PlanItemState priorState = await repo.currentStateFor(planItemId);

    final (PlanItemState newState, DateTime? rescheduleTo) = switch (action) {
      DispositionAction.done => (PlanItemState.done, null),
      DispositionAction.onIt => (PlanItemState.inProgress, null),
      DispositionAction.pushToTomorrow => (
      PlanItemState.rescheduled,
      DateTime.now().toUtc().add(const Duration(days: 1)),
      ),
      DispositionAction.pushToToday => (
      PlanItemState.rescheduled,
      DateTime.now().toUtc(),
      ),
      DispositionAction.skipIt => (PlanItemState.skipped, null),
    };

    try {
      final PlanItemState result = await repo.applyDisposition(
        planItemId: planItemId,
        priorState: priorState,
        newState: newState,
        prompted: prompted,
        rescheduleTo: rescheduleTo,
      );
      _log.info(
        'disposed $planItemId: ${action.name} '
            '(${priorState.name} → ${result.name})',
      );
      ref.read(dispositionToastsProvider.notifier).emit(action);
      return result;
    } on StateError catch (error, stack) {
      // Stale prior state — the item changed under us.
      _log.warning('stale disposition for $planItemId', error, stack);
      rethrow;
    }
  }

  Future<int> bulkSkip(List<String> planItemIds) async {
    final PlanItemRepository repo = ref.read(planItemRepositoryProvider);
    try {
      final int count = await repo.bulkSkip(
        planItemIds: planItemIds,
        prompted: true,
      );
      if (count > 0) {
        // Single toast for the whole bulk action.
        ref.read(dispositionToastsProvider.notifier).emit(
          DispositionAction.skipIt,
        );
      }
      return count;
    } on StateError catch (error, stack) {
      _log.warning('bulk-skip rejected', error, stack);
      rethrow;
    }
  }
}