import 'package:flutter/painting.dart';


abstract final class AppSpacing {
  AppSpacing._();

  // ---------------------------------------------------------------------------
  // Spacing scale — PDD §6
  // ---------------------------------------------------------------------------

  /// **xs · 4px** — inside dense pills, between icon and text in small chips.
  static const double xs = 4;

  /// **sm · 8px** — between adjacent buttons, within a plan item row.
  static const double sm = 8;

  /// **md · 12px** — between cards in a stack, between sections in a card.
  static const double md = 12;

  /// **lg · 16px** — screen horizontal padding, between major rows.
  static const double lg = 16;

  /// **xl · 24px** — between major sections (date train → today peek).
  static const double xl = 24;

  /// **xxl · 32px** — around the floating island, top of screen below status bar.
  static const double xxl = 32;


  // ---------------------------------------------------------------------------
  // Radius scale — PDD §6
  // ---------------------------------------------------------------------------

  /// **6px** — inline chips, small inputs.
  static const double radiusSmall = 6;

  /// **10px** — cards, action rows.
  static const double radiusMedium = 10;

  /// **16px** — sheets, larger cards.
  static const double radiusLarge = 16;

  /// **999px** — buttons, the floating island, segmented chips.
  /// (Effectively a stadium / pill shape.)
  static const double radiusPill = 999;

  // ---------------------------------------------------------------------------
  // BorderRadius helpers — most common compositions
  // ---------------------------------------------------------------------------

  static const BorderRadius borderRadiusSmall =
      BorderRadius.all(Radius.circular(radiusSmall));

  static const BorderRadius borderRadiusMedium =
      BorderRadius.all(Radius.circular(radiusMedium));

  static const BorderRadius borderRadiusLarge =
      BorderRadius.all(Radius.circular(radiusLarge));
  
  static const BorderRadius borderRadiusPill =
      BorderRadius.all(Radius.circular(radiusPill));

  /// Top-only large radius — used on bottom sheets per PDD §17 (disposition
  /// sheet) and §15 (conversation panel).
  static const BorderRadius borderRadiusSheetTop = BorderRadius.only(
    topLeft: Radius.circular(radiusLarge),
    topRight: Radius.circular(radiusLarge),
  );


  // ---------------------------------------------------------------------------
  // Common EdgeInsets — saves verbose code at call sites
  // ---------------------------------------------------------------------------

  /// Standard horizontal screen padding (16px each side).
  static const EdgeInsets screenHorizontal =
      EdgeInsets.symmetric(horizontal: lg);

  /// Card interior padding (20px all around, per PDD §6).
  static const EdgeInsets cardPadding = EdgeInsets.all(20);

  /// Section gap — used as a `SizedBox(height: AppSpacing.xl)`.
  static const SizedBox sectionGap = SizedBox(height: xl);

  /// Row gap inside a section.
  static const SizedBox rowGap = SizedBox(height: sm);

  // ---------------------------------------------------------------------------
  // Fixed component dimensions — PDD §9
  // ---------------------------------------------------------------------------

  /// Day tile width (PDD §9.1).
  static const double dayTileWidth = 40;

  /// Day tile height (PDD §9.1).
  static const double dayTileHeight = 52;

  /// Temperature dot diameter (PDD §9.2).
  static const double temperatureDotSize = 7;

  /// Plan item row height (PDD §9.4).
  static const double planItemRowHeight = 38;

  /// Floating island width and height (PDD §9.5).
  static const double floatingIslandWidth = 280;
  static const double floatingIslandHeight = 42;

  /// Disposition button row height (PDD §9.7).
  static const double dispositionButtonHeight = 48;

  /// Minimum tappable target — platform-mandated minimums.
  /// PDD §27: 44 on iOS, 48 on Android. We use 48 as a safe minimum
  /// for both, since being too large is never an accessibility violation.
  static const double minTouchTarget = 48;
}