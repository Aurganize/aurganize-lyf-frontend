import '../../../domain/enums/plan_item_state.dart';

/// The four actions the disposition prompt offers — PDD §17.
///
/// Each maps to a [PlanItemState] transition via [resultingState] /
/// [resultingStateAfterReturnToPlanned]. Note that [pushToTomorrow] is
/// the only action that produces a transient [PlanItemState.rescheduled]
/// state, which the repository immediately returns to
/// [PlanItemState.planned] (SRS FR-4.5).
enum DispositionAction {
  /// "Done — marked complete." Terminal.
  done,

  /// "On it — I'll keep nudging." Sets the item to in-progress; the
  /// notification engine continues to surface it.
  onIt,

  /// "Push to tomorrow — return to plan." Reschedules; immediately
  /// returns to planned with updated timing.
  pushToTomorrow,

  /// Move a leftover item from its original day to today's plan.
  /// Only ever used from the leftover view.
  pushToToday,

  /// "Skip it — no penalty." Terminal, but specifically not scored.
  skipIt,
}

extension DispositionActionMeta on DispositionAction {
  /// The lifecycle state recorded for this action's disposition event.
  PlanItemState get resultingState {
    return switch (this) {
      DispositionAction.done => PlanItemState.done,
      DispositionAction.onIt => PlanItemState.inProgress,
      DispositionAction.pushToTomorrow => PlanItemState.rescheduled,
      DispositionAction.pushToToday => PlanItemState.rescheduled,
      DispositionAction.skipIt => PlanItemState.skipped,
    };
  }
}