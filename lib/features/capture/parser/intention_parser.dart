import '../../../domain/models/plan_item.dart';

/// Produces structured [PlanItem]s from a raw intention text.
///
/// The signature is intentionally narrow. Inputs are the user id, the
/// intention id (so plan items can reference their source), and the raw
/// text. Output is one or more plan items — never zero, because the
/// parser falls back to a single low-confidence "task" with the raw
/// text as title rather than refusing.
///
/// If parsing genuinely cannot proceed (network error against the real
/// backend, malformed model output that even the fallback can't recover
/// from), implementations throw a [ParserFailure]. The caller — the
/// parse worker — translates that into a [ParseStatus.failed] update
/// on the intention.
abstract interface class IntentionParser {
  /// Parses [rawText] for the given user/intention.
  ///
  /// Implementations MUST:
  ///   - Return at least one plan item.
  ///   - Tag every plan item with `intentionId = intentionId`.
  ///   - Use [userId] for the plan items' `userId`.
  ///   - Generate fresh UUIDs for plan item IDs.
  ///   - Populate confidences for every inferred attribute.
  ///
  /// Implementations MUST NOT:
  ///   - Touch the database.
  ///   - Modify the source intention.
  Future<List<PlanItem>> parse({
    required String userId,
    required String intentionId,
    required String rawText,
  });
}

/// Thrown by an [IntentionParser] when parsing cannot proceed at all.
class ParserFailure implements Exception {
  ParserFailure(this.message, [this.cause, this.stackTrace]);

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'ParserFailure: $message';
}