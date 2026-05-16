import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';


/// Sugar that lets widgets access design tokens through context.
///
/// Both styles work — pick one and stick with it in any given file
/// for consistency:
///
/// ```dart
/// // Direct static access — fewer imports, slightly more typing:
/// padding: const EdgeInsets.all(AppSpacing.lg)
/// color: AppColors.brandPrimary
///
/// // Through context — more imports, slightly less typing:
/// padding: EdgeInsets.all(context.spacing.lg)
/// color: context.colors.brandPrimary
/// ```
///
/// Static access is preferred for `const` constructors (no context
/// available at compile time). Context access shines when overriding
/// tokens in tests or when we eventually add dark mode.
extension ContextExtensions on BuildContext {
  /// Color tokens — see [AppColors] for the full list.
  Type get colors => AppColors;

  /// Spacing and radius tokens — see [AppSpacing] for the full list.
  Type get spacing => AppSpacing;

  /// Typography tokens — see [AppTypography] for the full list.
  Type get type => AppTypography;

  /// Motion tokens — see [AppMotion] for the full list.
  Type get motion => AppMotion;

  /// MediaQuery convenience: viewport size minus safe areas and keyboard.
  Size get viewportSize => MediaQuery.sizeOf(this);

  /// Whether the device is in reduced-motion mode.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);

  /// The current platform text scale factor.
  double get textScale => MediaQuery.textScalerOf(this).scale(1);
}