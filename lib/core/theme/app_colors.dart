import 'package:flutter/painting.dart';

/// Design tokens for color, sourced from the Design Document
///
/// **Do not user hex literals directly in widget code.**
/// If a color is missing from this class, add it here first
/// - never inline it at the call site.
///
/// The palette is deliberately small: greyscale for structure,
/// a singe brand teal for the user's actions and confirmations,
/// and three temperature dots for urgency. Warning states use warm
/// coral and amber - never red, except for the [tempHot] dot where
/// a red signals a hard-time medical/safety context.
abstract final class AppColors {
  AppColors._();
  //-------------------------------------------------
  // Brand Design Template
  //-------------------------------------------------

  /// `brand.primary` — primary actions, send button, focused day tile,
  /// sparkle in the floating island, brand-filled disposition button.
  ///
  /// Passes WCAG AA for body text on white (#FFFFFF) and AAA for large
  /// text. Safe for ≥14pt text on [surfacePrimary] or [surfaceSecondary].
  static const Color brandPrimary = Color(0xFF0F6E56);

  static const Color brandDark = Color(0xFF0A4D3C);

  static const Color brandLight = Color(0xFFE1F5EE);

  // ---------------------------------------------------------------------------
  // Surface and text — PDD §4.2
  // ---------------------------------------------------------------------------

  /// `surface.primary` — default page and card background.
  static const Color surfacePrimary = Color(0xFFFFFFFF);

  /// `surface.secondary` — inline raised areas: quote blocks (e.g. the
  /// "you typed" block in the confirmation detail), past-day pills,
  /// sheet rows.
  static const Color surfaceSecondary = Color(0xFFF7F5F0);

  /// `surface.tertiary` — disposition action rows, secondary buttons.
  /// Sits very close to [surfacePrimary]; the difference is intentionally
  /// subtle so it does not draw attention.
  static const Color surfaceTertiary = Color(0xFFFAFAFA);

  /// `text.primary` — headings and primary body. NOT pure black, because
  /// pure black on pure white is unnecessarily harsh.
  static const Color textPrimary = Color(0xFF1A1A1A);

  /// `text.secondary` — subtitles, helper text, captions.
  /// Passes AA for ≥18pt or ≥14pt-bold on [surfacePrimary]. For body
  /// text smaller than that, use [textPrimary].
  static const Color textSecondary = Color(0xFF6B6B6B);

  /// `text.tertiary` — eyebrow labels, timestamps, low-emphasis text.
  /// Only AA-compliant for incidental text per WCAG 1.4.3 — never for
  /// content the user must read.
  static const Color textTertiary = Color(0xFFA0A0A0);

  /// `border.default` — card edges, dividers, separators (the 0.5px line
  /// at the bottom of plan-item rows).
  static const Color borderDefault = Color(0xFFE5E5E5);

  /// `border.strong` — hover and focus edges, slightly more present than
  /// [borderDefault]. Use when the edge needs to be noticed.
  static const Color borderStrong = Color(0xFFD1D5D8);


  // ---------------------------------------------------------------------------
  // Temperature dots — PDD §4.3
  // ---------------------------------------------------------------------------
  //
  // Temperature is the per-item value that governs how assertively a
  // plan item surfaces (SRS FR-3.4, FR-5.1). Visualized as a 7px dot
  // on every plan-item row.
  //
  // Red as a fill is reserved entirely for [tempHot] — medication and
  // safety. It never appears as a background, never as a border, never
  // as an alert chrome.

  /// `temp.hot` — hard-time items: medication, appointments, alarms.
  static const Color tempHot = Color(0xFFE24B4A);

  /// `temp.warm` — soft-deadline items: "this week", "before Friday".
  static const Color tempWarm = Color(0xFFEF9F27);

  /// `temp.cool` — drifting items: "sometime", "whenever".
  static const Color tempCool = Color(0xFF97C459);

  // ---------------------------------------------------------------------------
  // Soft-attention pills — PDD §4.3
  // ---------------------------------------------------------------------------
  //
  // These are the colors used on past-day count pills in the date train.
  // Coral for older leftovers, amber for yesterday. NEVER use red here.
  // The product principle is "counts, not red urgency" (PDD §2 principle 05).

  /// Background of the past-day count pill for older leftovers (two days
  /// or more in the past).
  static const Color attentionCoralBackground = Color(0xFFFAECE7);

  /// Foreground (text) of the past-day count pill for older leftovers.
  /// AA-compliant on [attentionCoralBackground].
  static const Color attentionCoralForeground = Color(0xFF993C1D);

  /// Background of the yesterday count pill.
  static const Color attentionAmberBackground = Color(0xFFFAEEDA);

  /// Foreground (text) of the yesterday count pill.
  /// AA-compliant on [attentionAmberBackground].
  static const Color attentionAmberForeground = Color(0xFF854F0B);

  // ---------------------------------------------------------------------------
  // Functional / state colors derived from the above
  // ---------------------------------------------------------------------------
  //
  // These are NOT new colors — they are named pointers to the tokens
  // above for specific UI states. Centralizing them here means a change
  // to brand or text colors propagates automatically.

  /// Color for icons rendered against [surfacePrimary] at default emphasis.
  static const Color iconDefault = textPrimary;

  /// Color for muted icons (e.g. inactive tab, dismissed chip).
  static const Color iconMuted = textTertiary;

  /// Color for icons that anchor a brand action (e.g. the check icon
  /// at the start of a disposition button row).
  static const Color iconBrand = brandPrimary;

  /// Background of an editable-but-tentative confidence chip (dashed border, no fill).
  static const Color chipTentativeBackground = Color(0x00000000); // transparent
  static const Color chipTentativeBorder = borderStrong;

  /// Background of a confirmed confidence chip.
  static const Color chipConfirmedBackground = surfaceSecondary;
  static const Color chipConfirmedText = textPrimary;

  /// Background of a currently-edited confidence chip.
  static const Color chipSelectedBackground = brandLight;
  static const Color chipSelectedText = brandDark;

  // ---------------------------------------------------------------------------
  // Overlays
  // ---------------------------------------------------------------------------

  /// Used when the conversation panel is raised over the landing screen.
  /// The plan behind dims to 35% opacity per PDD §15.
  static const Color scrim = Color(0x59000000); // 0x59 = ~35% alpha
}