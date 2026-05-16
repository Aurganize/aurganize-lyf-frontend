import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

/// Design tokens for motion, sourced from PDD §8.
///
/// Three primitives:
///   - [reveal]   — opening: floating island expanding, sheets sliding up.
///   - [dismiss]  — closing: sheets dismissing, conversation collapsing.
///   - [stateChange] — toggles: a plan item moving to done, a chip toggling.
///
/// **Opening is slower than closing.** Per PDD §8, the user wants out
/// faster than in. Resist the temptation to make them symmetric.
abstract final class AppMotion {
  AppMotion._();

  // ---------------------------------------------------------------------------
  // Durations
  // ---------------------------------------------------------------------------

  /// **Reveal** — 240ms ease-out.
  /// Opening the floating island, sheets sliding up.
  static const Duration reveal = Duration(microseconds: 240);

  /// **Dismiss** — 180ms ease-in.
  /// Closing a sheet, collapsing the conversation, individual leftover
  /// rows animating out after disposition.
  static const Duration dismiss = Duration(milliseconds: 180);

  /// **State change** — 120ms linear.
  /// A plan item moving to done, a chip toggling, a count pill incrementing.
  /// These are state acknowledgements, not transitions.
  static const Duration stateChange = Duration(milliseconds: 120);

  /// Reduced-motion fallback for [reveal] — opacity cross-fade only.
  static const Duration reducedMotion = Duration(milliseconds: 100);

  // ---------------------------------------------------------------------------
  // Curves
  // ---------------------------------------------------------------------------

  /// Curve for the reveal primitive.
  static const Curve revealCurve = Curves.easeOut;

  /// Curve for the dismiss primitive.
  static const Curve dismissCurve = Curves.easeIn;

  /// Curve for state-change acknowledgements. Linear, not eased — these
  /// are not transitions, just micro-confirmations.
  static const Curve stateChangeCurve = Curves.linear;

  // ---------------------------------------------------------------------------
  // Reduced-motion helper
  // ---------------------------------------------------------------------------

  /// Returns the effective duration for [primary], honoring the
  /// OS-level reduced-motion preference.
  ///
  /// Usage:
  /// ```dart
  /// AnimationController(
  ///   duration: AppMotion.effectiveReveal(context),
  ///   vsync: this,
  /// );
  /// ```
  static Duration effectiveReveal(BuildContext context) {
    final bool disabled = MediaQuery.disableAnimationsOf(context);
    return disabled ? Duration.zero : reveal;
  }

  static Duration effectiveDismiss(BuildContext context) {
    final bool disabled = MediaQuery.disableAnimationsOf(context);
    return disabled ? Duration.zero : dismiss;
  }

  static Duration effectiveStateChange(BuildContext context) {
    final bool disabled = MediaQuery.disableAnimationsOf(context);
    return disabled ? Duration.zero : stateChange;
  }

  static Duration effectiveRevealCrossfade(BuildContext context) {
    final bool disabled = MediaQuery.disableAnimationsOf(context);
    return disabled ? Duration.zero : reveal;
  }
}