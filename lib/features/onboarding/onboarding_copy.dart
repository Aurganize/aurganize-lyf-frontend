/// The exact copy used on the onboarding screen — PDD §12.
abstract final class OnboardingCopy {
  OnboardingCopy._();

  static const String appName = 'Aurganize lyf';
  static const String tagline = 'Calm planning. No nagging.';

  static const String getStartedLabel = 'Get started';
  static const String signInOptions =
      'Sign in with Apple, Google, or email';

  // ── The three principles ───────────────────────────────────────────────────

  static const List<PrincipleBlock> principles = <PrincipleBlock>[
    PrincipleBlock(
      heading: 'Capture without friction',
      body: 'Text it as you would a note to yourself. We organize it later.',
    ),
    PrincipleBlock(
      heading: 'Every nudge has four answers',
      body: 'Done, on it, push, skip. None is wrong.',
    ),
    PrincipleBlock(
      heading: 'Checking in is what counts',
      body: 'Your streak rewards engagement, not perfection.',
    ),
  ];
}

class PrincipleBlock {
  const PrincipleBlock({required this.heading, required this.body});

  final String heading;
  final String body;
}