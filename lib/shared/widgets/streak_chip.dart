import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// The flame + number chip in the app header — PDD §13.
///
/// Independent of the actual streak engine — that ships in Phase 10
/// and feeds [streak] from a provider. For now the screen passes a
/// constant; the chip just renders.
///
/// Tapping the chip is a defined behavior in PDD §10 (it scrolls the
/// date train back to today and refocuses on the today peek). The
/// host of the chip wires that callback.
class StreakChip extends StatelessWidget {
  const StreakChip({
    super.key,
    required this.streak,
    this.onTap,
  });

  final int streak;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: streak == 1
          ? '1 day streak. Tap to focus today.'
          : '$streak day streak. Tap to focus today.',
      excludeSemantics: true,
      child: Material(
        color: AppColors.brandLight,
        borderRadius: AppSpacing.borderRadiusPill,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.local_fire_department,
                  size: 14,
                  color: AppColors.brandDark,
                ),
                const SizedBox(width: 4),
                Text(
                  '$streak',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.brandDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}