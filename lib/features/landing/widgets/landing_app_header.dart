import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/streak_chip.dart';

/// Header strip at the top of the landing screen — PDD §13.
///
/// Stateless; the streak count is supplied by the host (a real provider
/// in Phase 10, a placeholder constant now). Tap handlers for the streak
/// chip and the menu icon are also supplied by the host so the header
/// itself stays free of routing concerns.
class LandingAppHeader extends StatelessWidget {
  const LandingAppHeader({
    super.key,
    required this.streak,
    required this.onStreakTap,
    required this.onMenuTap,
  });

  /// The current engagement streak (Phase 10 fills this; for now,
  /// the screen passes a placeholder).
  final int streak;

  final VoidCallback onStreakTap;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String weekdayLabel =
    DateFormat.EEEE().format(now).toUpperCase();
    final String dateTitle = DateFormat.MMMMd().format(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  weekdayLabel,
                  style: AppTypography.eyebrow.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(dateTitle, style: AppTypography.title),
              ],
            ),
          ),
          StreakChip(streak: streak, onTap: onStreakTap),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            button: true,
            label: 'Settings menu',
            excludeSemantics: true,
            child: SizedBox(
              width: AppSpacing.minTouchTarget,
              height: AppSpacing.minTouchTarget,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onMenuTap,
                  child: const Icon(
                    Icons.menu,
                    size: 22,
                    color: AppColors.iconDefault,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}