/// Lifecycle states of a plan item — SRS FR-4.1.
///
/// The current state is **derived** from the plan item's disposition
/// history (SRS FR-4.7). This enum is the set of values the latest
/// disposition can produce.
enum PlanItemState {
  /// The plan item exists and is awaiting action. Default state after
  /// creation or after [rescheduled] (SRS FR-4.5).
  planned,

  /// The user has acknowledged the item and signaled they are working on
  /// it but it is not yet [done]. Maps to the "On it" disposition button
  /// in PDD §17.
  inProgress,

  /// Terminal state. The user marked the item complete.
  done,

  /// Terminal state. The user explicitly chose to skip — a valid,
  /// non-penalized decision. SRS FR-4.4: skipped is terminal AND
  /// carries no negative scoring consequence.
  skipped,

  /// A short-lived intermediate state recorded when the user reschedules.
  /// Almost immediately followed by a return to [planned] with updated
  /// timing (SRS FR-4.5). Kept in the log as a distinct state so the
  /// audit trail is complete; the active state of the item is [planned].
  rescheduled,
}