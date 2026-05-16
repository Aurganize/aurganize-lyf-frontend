import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/plan_item_state.dart';

part 'disposition_event.freezed.dart';
part 'disposition_event.g.dart';

/// An append-only record of a single disposition decision — SRS FR-4.6.
///
/// **Never updated, never deleted.** The current state of the parent
/// plan item is derived from the most recent event (SRS FR-4.7).
///
/// This is the mechanism by which disposition conflicts during sync are
/// resolved without information loss (SRS FR-9.4). Two devices that
/// disposition the same item produce two events; the log keeps both,
/// and the latest by timestamp wins for the derived state.
@freezed
class DispositionEvent with _$DispositionEvent {
  const factory DispositionEvent({
    /// Client-generated UUID v4.
    required String id,

    /// The plan item this event applies to.
    required String planItemId,

    /// The state of the plan item immediately before this event.
    /// Stored for audit clarity even though it could be re-derived.
    required PlanItemState priorState,

    /// The state produced by this event.
    required PlanItemState newState,

    /// Whether the user took this action in response to a notification
    /// or other prompt (true) or proactively (false). Distinguished
    /// because gamification only rewards engagement on prompts the user
    /// dismissed — proactive completions are already self-rewarding.
    /// (See gamification logic in Phase 10.)
    required bool prompted,

    /// When the disposition happened (device clock).
    required DateTime occurredAt,

    /// If the new state is [PlanItemState.rescheduled], the new target
    /// time the user picked. Null for any other newState.
    DateTime? rescheduledTo,

    /// Optional free-text note the user attached. Not surfaced in v1.0
    /// UI but reserved in the schema for future use.
    String? note,
  }) = _DispositionEvent;

  factory DispositionEvent.fromJson(Map<String, Object?> json) =>
      _$DispositionEventFromJson(json);
}