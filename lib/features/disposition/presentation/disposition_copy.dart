import 'dart:math';

/// The exact words used in the disposition prompt — PDD §17, §23.
///
/// Centralized here so designers can change the voice without touching
/// the widget tree, and so typos don't survive code review.
abstract final class DispositionCopy {
  DispositionCopy._();

  // ── The four action labels — never changed ────────────────────────────────

  static const String doneLabel = 'Done';
  static const String doneSub = 'marked complete';

  static const String onItLabel = 'On it';
  static const String onItSub = "I'll keep nudging";

  static const String pushLabel = 'Push to tomorrow';
  static const String pushSub = 'return to plan';

  static const String skipLabel = 'Skip it';
  static const String skipSub = 'no penalty';

  // ── The reassurance — the single most important sentence in the product ──

  static const String reassurance = 'Whatever you choose is fine.';

  // ── The CHECK-IN eyebrow ──────────────────────────────────────────────────

  static const String eyebrow = 'CHECK-IN';

  // ── The question bank ─────────────────────────────────────────────────────

  /// The set of opening questions. `{title}` is replaced with the plan
  /// item's title before display. The bank is rotated by the providers
  /// in Phase 04 so the user does not see the same question twice in
  /// a session.
  static const List<String> questionBank = <String>[
    'Still planning to {title}?',
    '{title} — how would you like to handle it?',
    'Wanted to check in on {title}.',
    '{title} — what works?',
    'Checking in on {title}.',
  ];

  /// Picks a question template from [questionBank] and substitutes
  /// the plan item title. If [seed] is supplied the choice is
  /// deterministic — useful for tests and goldens.
  static String composeQuestion(String title, {int? seed}) {
    final Random rng = seed == null ? Random() : Random(seed);
    final String template = questionBank[rng.nextInt(questionBank.length)];
    return template.replaceAll('{title}', title);
  }
}