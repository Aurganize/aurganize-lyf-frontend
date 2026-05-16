import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A single action row inside the disposition prompt sheet — PDD §9.7.
///
/// Anatomy:
///
/// ```
/// ┌─────────────────────────────────────────────────────────────┐
/// │ ⌾ Done                                                    › │
/// │   marked complete                                            │
/// └─────────────────────────────────────────────────────────────┘
/// ```
///
///   - `⌾`            Brand-colored icon. Caller-supplied.
///   - `Done`         Action label (Body weight).
///   - `marked …`     Sub-explanation (Caption weight, muted).
///   - `›`            Chevron-right (muted).
class DispositionButton extends StatelessWidget {
  const DispositionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.subExplanation,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subExplanation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Screen reader reads as one full sentence — PDD §17.
    final String semanticsLabel = '$label, $subExplanation, button';

    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: AppColors.surfaceTertiary,
        borderRadius: AppSpacing.borderRadiusMedium,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // Mid-impact haptic — a disposition is a commit decision.
            // The user's confirmation that the action registered matters
            // more here than for any other gesture in the product.
            HapticFeedback.mediumImpact();
            onTap();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.dispositionButtonHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    icon,
                    size: 22,
                    color: AppColors.iconBrand,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          label,
                          style: AppTypography.body.copyWith(
                            color: AppColors.brandPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subExplanation,
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.iconMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}