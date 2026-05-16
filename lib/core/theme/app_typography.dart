import 'package:flutter/cupertino.dart';
import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';


/// Design tokens for typography, sourced from PDD §5.
///
/// **Family:** Inter (via `google_fonts`), with the device system font
/// as fallback. The system fallback is automatic if Inter fails to
/// load — Flutter falls back to the platform default, which is
/// SF Pro on iOS and Roboto on Android. Both pair acceptably with
/// the visual system if a network hiccup prevents font download.
///
/// **Weights:** 400 (regular) and 500 (medium) only. Bold (700) is
/// never used — see PDD §5.
///
/// **Sizing:** logical pixels (Flutter's default unit). We do NOT
/// hard-code line heights as multiples — we set `height` explicitly
/// per role so that vertical rhythm is consistent across devices.
abstract final class AppTypography {
  AppTypography._();

  // The font family name. We could call `GoogleFonts.inter()` everywhere,
  // but resolving it once here gives us a single point of change and
  // avoids the (tiny) cost of building a TextStyle from scratch each call.
  static const String _fontFamily = 'Inter';

  // ---------------------------------------------------------------------------
  // Base style — every other style is derived from this.
  // ---------------------------------------------------------------------------

  static TextStyle _base({
    required double fontSize,
    required double height,
    required FontWeight fontWeight,
    Color color = AppColors.textPrimary,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      // `height` in Flutter is a multiplier on fontSize that yields line height.
      // We compute it from the PDD's explicit line-height values to keep them
      // legible at the call site.
      height: height / fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      // Helps render kerning the way the type was designed.
      textBaseline: TextBaseline.alphabetic,
    );
  }

  // ---------------------------------------------------------------------------
  // Roles — PDD §5
  // ---------------------------------------------------------------------------

  /// **Display** — 28/32/500. App title on onboarding only.
  ///
  /// Never use this elsewhere. The PDD §5 reserves it for the single
  /// instance of the product name on the onboarding screen.
  static TextStyle get display => _base(
      fontSize: 28,
      height: 32,
      fontWeight: FontWeight.w500,
  );

  /// **Title** — 22/28/500. Screen titles, project name on the project view.
  static TextStyle get title => _base(
      fontSize: 22,
      height: 28,
      fontWeight: FontWeight.w500,
  );

  /// **Heading** — 17/24/500. Section headings inline, the day eyebrow
  /// under the date train.
  static TextStyle get heading => _base(
      fontSize: 17,
      height: 24,
      fontWeight: FontWeight.w500,
  );

  /// **Body** — 14/20/400. Plan item titles, conversation bubbles,
  /// primary body. The workhorse text style.
  static TextStyle get body => _base(
    fontSize: 14,
    height: 20,
    fontWeight: FontWeight.w400,
  );

  /// **Body 2** — 13/18/400. Notification body, settings rows.
  /// One step quieter than [body].
  static TextStyle get body2 => _base(
    fontSize: 13,
    height: 18,
    fontWeight: FontWeight.w400,
  );

  /// **Caption** — 11/15/400. Sub-labels under plan items, helper text.
  static TextStyle get caption => _base(
    fontSize: 11,
    height: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// **Eyebrow** — 10/14/500, +0.5 letter spacing, uppercase.
  /// Section labels above lists ("TODAY", "PARSED", "CHILDREN").
  ///
  /// IMPORTANT: this style does NOT uppercase the text automatically.
  /// Always pass uppercase strings: `Text('TODAY', style: AppTypography.eyebrow)`.
  /// Uppercasing in the style would break screen-reader pronunciation.
  static TextStyle get eyebrow => _base(
    fontSize: 10,
    height: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textTertiary,
  );

  // ---------------------------------------------------------------------------
  // Convenience emphasis variants
  // ---------------------------------------------------------------------------
  //
  // These are common derivations from the seven core roles. They prevent
  // call sites from doing `AppTypography.body.copyWith(color: ...)`
  // which scatters semantic decisions throughout widget code.

  /// Body in [AppColors.textSecondary] — for the sub-explanation line
  /// under disposition button labels, time hints under plan-item titles.
  static TextStyle get bodyMuted =>
      body.copyWith(color: AppColors.textSecondary);

  /// Body in [AppColors.brandPrimary] — for the brand-colored
  /// action labels on the disposition buttons.
  static TextStyle get bodyBrand =>
      body.copyWith(color: AppColors.brandPrimary);

  /// Body in [AppColors.surfacePrimary] (white) — for text on brand-filled
  /// surfaces such as the floating island label.
  static TextStyle get bodyOnBrand =>
      body.copyWith(color: AppColors.surfacePrimary);

  /// Strikethrough body for completed children on the project view.
  static TextStyle get bodyStrikethrough => body.copyWith(
      color: AppColors.textSecondary,
      decoration: TextDecoration.lineThrough,
      decorationColor: AppColors.textTertiary,
      decorationThickness: 1,
    );

  /// Caption in [AppColors.attentionAmberForeground] — yesterday count pill.
  static TextStyle get captionAmber =>
      caption.copyWith(color: AppColors.attentionAmberForeground);

  /// Caption in [AppColors.attentionCoralForeground] — older-leftover count pill.
  static TextStyle get captionCoral =>
      caption.copyWith(color: AppColors.attentionCoralForeground);


}