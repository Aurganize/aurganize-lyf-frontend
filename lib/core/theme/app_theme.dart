import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';


/// Composes the design tokens into a single [ThemeData].
///
/// **Light only for v1.0.** Dark mode is intentionally not in scope —
/// the PDD's calming palette and brand identity are designed for light
/// surfaces, and a half-built dark mode would weaken both. Adding dark
/// later requires only a `AppTheme.dark()` factory and a parallel
/// [AppColors] dark-token class.
abstract final class AppTheme {
  AppTheme._();


  static ThemeData light() {
    const ColorScheme colorScheme = _lightColorScheme;
    final TextTheme textTheme = _buildTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: AppColors.surfacePrimary,
      canvasColor: AppColors.surfacePrimary,
      splashFactory: InkRipple.splashFactory,

      // The brand color is the accent; everything else falls back to greyscale.
      primaryColor: AppColors.brandPrimary,

      // Disable the default platform tint — it darkens surfaces on scroll
      // and breaks our flat, calm aesthetic.
      appBarTheme: _appBarTheme(textTheme),
      bottomSheetTheme: _bottomSheetTheme,
      dividerTheme: _dividerTheme,
      iconTheme: _iconTheme,
      listTileTheme: _listTileTheme(textTheme),
      elevatedButtonTheme: _elevatedButtonTheme(textTheme),
      outlinedButtonTheme: _outlineInputBorder(textTheme),
      textButtonTheme: _textButtonTheme(textTheme),
      filledButtonTheme: _filledButtonTheme(textTheme),
      inputDecorationTheme: _inputDecorationTheme(textTheme),
      snackBarTheme: _snackBarTheme(textTheme),
      tooltipTheme: _tooltipTheme(textTheme),
      progressIndicatorTheme: _progressIndicatorTheme,
      dialogTheme: _dialogTheme(textTheme),

      // Material 3 ripple on touch is good UX; we keep it but tune the color
      // so it shows brand affinity rather than the default grey.
      highlightColor: AppColors.brandLight.withValues(alpha: 0.5),
      splashColor: AppColors.brandLight,

      // Force the same font family at the root for any widget that doesn't
      // consume the textTheme directly (rare, but it happens).
      fontFamily: 'Inter',

      // Material widgets that ask for a "surface" color should get our
      // primary surface, not the M3 default tinted grey.
      cardTheme: _cardTheme,

      visualDensity: VisualDensity.standard,

    );


  }

  // ---------------------------------------------------------------------------
  // ColorScheme
  // ---------------------------------------------------------------------------
  //
  // We hand-build the ColorScheme rather than using `fromSeed`. The seed
  // approach would generate a tonal palette around brandPrimary, but our
  // palette is intentional — most M3 widgets we care about already get
  // their colors from our token classes, and we want the few they DO get
  // from ColorScheme to be exactly the tokens we chose.

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.brandPrimary,
    onPrimary: AppColors.surfacePrimary,
    primaryContainer: AppColors.brandLight,
    onPrimaryContainer: AppColors.brandDark,
    secondary: AppColors.brandDark,
    onSecondary: AppColors.surfacePrimary,
    secondaryContainer: AppColors.brandLight,
    onSecondaryContainer: AppColors.brandDark,

    // We have no tertiary; map it to a neutral so any incidental use is calm.
    tertiary: AppColors.textSecondary,
    onTertiary: AppColors.surfacePrimary,
    tertiaryContainer: AppColors.surfaceSecondary,
    onTertiaryContainer: AppColors.textPrimary,

    // Error uses the hot temperature color — the only red in the system.
    error: AppColors.tempHot,
    onError: AppColors.surfacePrimary,
    errorContainer: AppColors.attentionCoralBackground,
    onErrorContainer: AppColors.attentionCoralForeground,
    surface: AppColors.surfacePrimary,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.surfaceSecondary,
    surfaceContainerHigh: AppColors.surfaceSecondary,
    surfaceContainer: AppColors.surfaceTertiary,
    surfaceContainerLow: AppColors.surfaceTertiary,
    surfaceContainerLowest: AppColors.surfaceTertiary,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.borderDefault,
    outlineVariant: AppColors.borderStrong,
    shadow: Color(0xFF000000),
    scrim: AppColors.scrim,
    inverseSurface: AppColors.textPrimary,
    onInverseSurface: AppColors.surfacePrimary,
    inversePrimary: AppColors.brandLight,
    surfaceTint: Color(0x00000000), // transparent — disables M3 elevation tint
  );

  // ---------------------------------------------------------------------------
  // TextTheme — map our [AppTypography] roles onto Material's role names
  // ---------------------------------------------------------------------------
  //
  // Material uses its own role names (headlineLarge, bodyMedium, etc.).
  // We map our PDD roles into the closest Material slot so widgets that
  // consume Theme.of(context).textTheme directly (e.g. AppBar, ListTile)
  // get the right style.

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge:  AppTypography.display,
      displayMedium: AppTypography.display,
      displaySmall: AppTypography.display,

      headlineLarge: AppTypography.title,
      headlineMedium: AppTypography.title,
      headlineSmall:  AppTypography.title,
      titleLarge: AppTypography.title,
      titleMedium: AppTypography.heading,
      titleSmall: AppTypography.heading,

      bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.body,
      bodySmall: AppTypography.body2,

      labelLarge: AppTypography.heading,
      labelMedium: AppTypography.caption,
      labelSmall: AppTypography.eyebrow,
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar — no shadow, no scroll tint, body text on white
  // ---------------------------------------------------------------------------

  static AppBarTheme _appBarTheme(TextTheme textTheme) {
    return AppBarTheme(
      backgroundColor: AppColors.surfacePrimary,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),
      actionsIconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    );
  }

  // ---------------------------------------------------------------------------
  // BottomSheet — for the disposition prompt and conversation panel
  // ---------------------------------------------------------------------------

  static const BottomSheetThemeData _bottomSheetTheme = BottomSheetThemeData(
    backgroundColor: AppColors.surfacePrimary,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    modalBackgroundColor: AppColors.surfacePrimary,
    modalElevation: 0,
    showDragHandle: true,
    dragHandleColor: AppColors.borderStrong,
    dragHandleSize: Size(36, 4),
    shape: RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusSheetTop,
    ),
    clipBehavior: Clip.antiAlias,
  );

  // ---------------------------------------------------------------------------
  // Divider — the 0.5px line at the bottom of plan-item rows
  // ---------------------------------------------------------------------------

  static const DividerThemeData _dividerTheme = DividerThemeData(
    color: AppColors.borderDefault,
    thickness: 0.5,
    space: 0,
  );

  // ---------------------------------------------------------------------------
  // Icons
  // ---------------------------------------------------------------------------

  static const IconThemeData _iconTheme = IconThemeData(
    color: AppColors.iconDefault,
    size: 18,
  );

  // ---------------------------------------------------------------------------
  // ListTile — used in settings
  // ---------------------------------------------------------------------------

  static ListTileThemeData _listTileTheme(TextTheme textTheme) {
    return ListTileThemeData(
      tileColor: AppColors.surfacePrimary,
      selectedTileColor: AppColors.brandLight,
      iconColor: AppColors.textPrimary,
      textColor: AppColors.textPrimary,
      titleTextStyle: textTheme.bodyLarge,
      subtitleTextStyle: AppTypography.caption,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMedium,
      ),
      minVerticalPadding: AppSpacing.sm,
    );
  }

  // ---------------------------------------------------------------------------
  // Buttons — these are uncommon in the actual UI (we mostly use custom widgets)
  // but they need theming so any built-in dialog or sheet looks right.
  // ---------------------------------------------------------------------------

  static ElevatedButtonThemeData _elevatedButtonTheme(TextTheme textTheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: AppColors.surfacePrimary,
        textStyle: textTheme.bodyLarge,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        minimumSize: const Size(0, AppSpacing.minTouchTarget),
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusPill,
        ),
      ),
    );
  }

  static FilledButtonThemeData _filledButtonTheme(TextTheme textTheme) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: AppColors.surfacePrimary,
        textStyle: textTheme.bodyLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        minimumSize: const Size(0, AppSpacing.minTouchTarget),
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusPill,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _outlineInputBorder(TextTheme textTheme) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: AppColors.surfacePrimary,
        textStyle: textTheme.bodyLarge,
        side: const BorderSide(color: AppColors.borderStrong, width: 1),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        minimumSize: const Size(0, AppSpacing.minTouchTarget),
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusPill,
        ),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme(TextTheme textTheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: AppColors.surfacePrimary,
        textStyle: textTheme.bodyLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusPill,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Input decoration
  // ---------------------------------------------------------------------------

  static InputDecorationTheme _inputDecorationTheme(TextTheme textTheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfacePrimary,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.textTertiary,
      ),
      labelStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
      ),
      border: const OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusPill,
        borderSide: BorderSide.none,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusPill,
        borderSide: BorderSide.none,
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusPill,
        borderSide: BorderSide(color: AppColors.brandPrimary, width: 1),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusPill,
        borderSide: BorderSide(color: AppColors.brandPrimary, width: 1),
      ),
    );
  }


  // ---------------------------------------------------------------------------
  // Tooltip
  // ---------------------------------------------------------------------------

  static TooltipThemeData _tooltipTheme(TextTheme textTheme) {
    return TooltipThemeData(
      decoration: const BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: AppSpacing.borderRadiusSmall,
      ),
      textStyle: textTheme.bodySmall?.copyWith(
        color: AppColors.surfacePrimary,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Progress indicator
  // ---------------------------------------------------------------------------

  static const ProgressIndicatorThemeData _progressIndicatorTheme =
    ProgressIndicatorThemeData(
      color: AppColors.brandPrimary,
      linearTrackColor: AppColors.surfaceSecondary,
      circularTrackColor: AppColors.surfaceSecondary,
      linearMinHeight: 4,
    );

  // ---------------------------------------------------------------------------
  // Snackbar — used for the "Marked done" / "Skipped — streak intact" toasts
  // ---------------------------------------------------------------------------

  static SnackBarThemeData _snackBarTheme(TextTheme textTheme) {
    return SnackBarThemeData(
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.surfacePrimary,
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMedium,
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dialog
  // ---------------------------------------------------------------------------

  static DialogThemeData _dialogTheme(TextTheme textTheme) {
    return DialogThemeData(
      backgroundColor: AppColors.surfacePrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusLarge,
      ),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    );
  }


  // ---------------------------------------------------------------------------
  // Card
  // ---------------------------------------------------------------------------

  static const CardThemeData _cardTheme = CardThemeData(
    color: AppColors.surfacePrimary,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMedium,
      side: BorderSide(color: AppColors.borderDefault, width: 0.5),
    )
  );

}