/// Status of the parsing pipeline for a given intention — SRS §9.1.
enum ParseStatus {
  /// Captured but not yet picked up by the parsing worker.
  pending,

  /// Currently being parsed.
  inProgress,

  /// Parsing complete; one or more [PlanItem]s were produced and
  /// confirmation cards are available.
  parsed,

  /// Parsing failed irrecoverably. The raw intention is retained
  /// (SRS FR-2.11) and surfaced as an unstructured item the user
  /// can edit directly.
  failed,

  /// The user dismissed the parsed result before confirming. The raw
  /// intention remains in history but produced no plan item.
  dismissed,
}