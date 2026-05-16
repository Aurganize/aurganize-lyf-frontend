/// Coarse classification of a plan item.
///
/// The parser produces one of these as part of its initial inference
/// (SRS FR-2.3). The type drives some default behaviors:
///   - [project] items render as a project view (PDD §19) and aggregate
///     their children's progress.
///   - [errand] vs [call] vs [task] are surface-level distinctions used
///     for notification phrasing variants (PDD §22).
///
/// **Not exhaustive.** New types can be added; the consumer code must
/// always handle the default case to remain forward-compatible.
enum PlanItemType {
  /// A generic single-action plan item.
  task,

  /// An out-of-house errand. "Pick up dry cleaning."
  errand,

  /// A phone or video call. "Call the dentist."
  call,

  /// A scheduled or to-be-scheduled appointment. "Dentist appointment."
  appointment,

  /// A medication or health-routine plan item.
  medication,

  /// A note or thought without a clear action verb.
  note,

  /// A multi-step plan item that contains children.
  project,

  /// The parser failed or had insufficient signal. The raw intention
  /// is preserved; the user can re-type or correct.
  unknown,

}