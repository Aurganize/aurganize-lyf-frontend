import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/confidence.dart';
import '../../features/capture/presentation/parsed_card_view_model.dart';
import 'confidence_chip.dart';

/// The peek confirmation card — PDD §14.
///
/// Renders above the floating island after a capture is parsed. Glanceable:
/// eyebrow, title, a horizontal chip row, a primary "Add to plan" pill.
///
/// ### Behaviors exposed
///
///   - [onConfirm]: tapping `Add to plan` (or the body, when the title is
///     confidently parsed) commits the plan item as-is.
///   - [onExpand]: tapping the title area drills into the detail view.
///   - [onChipTap]: tapping a chip opens the inline editor for that attribute.
///   - [onDismiss]: tapping the dismiss-x discards the structured item
///     (the raw intention is retained — the dismiss copy in PDD §25 covers this).
///
/// ### Compactness
///
/// The peek lives in a tight space (sitting above the 42-px island, with
/// the today peek visible behind it). We render a maximum of 3 chips to
/// keep the card under 130 logical pixels tall — beyond 3, the chip row
/// truncates with a "+N more" trailing chip.
class ConfirmationPeekCard extends StatelessWidget {
  const ConfirmationPeekCard({
    super.key,
    required this.viewModel,
    this.onConfirm,
    this.onExpand,
    this.onChipTap,
    this.onDismiss,
  });

  final ParsedCardViewModel viewModel;

  final VoidCallback? onConfirm;
  final VoidCallback? onExpand;
  final void Function(ParsedAttribute attribute)? onChipTap;
  final VoidCallback? onDismiss;

  static const int _maxVisibleChips = 3;

  @override
  Widget build(BuildContext context) {
    final List<ParsedAttribute> attrs = viewModel.attributes;
    final List<ParsedAttribute> visible =
    attrs.take(_maxVisibleChips).toList(growable: false);
    final int overflow = attrs.length - visible.length;

    return Material(
      color: AppColors.surfacePrimary,
      borderRadius: AppSpacing.borderRadiusLarge,
      clipBehavior: Clip.antiAlias,
      elevation: 6,
      shadowColor: AppColors.textPrimary.withValues(alpha: 0.12),
      surfaceTintColor: Colors.transparent,
      child: InkWell(
        onTap: onExpand,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm, // smaller right pad to host dismiss-x
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _eyebrowRow(),
              const SizedBox(height: AppSpacing.xs),
              _titleRow(),
              const SizedBox(height: AppSpacing.md),
              _chipRow(visible, overflow),
              const SizedBox(height: AppSpacing.md),
              _actionRow(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Subviews ─────────────────────────────────────────────────────────────

  Widget _eyebrowRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('PARSED · TAP TO CONFIRM', style: AppTypography.eyebrow),
        _DismissButton(onTap: onDismiss),
      ],
    );
  }

  Widget _titleRow() {
    final bool titleIsTentative = viewModel.titleConfidence.isTentative;
    return Text(
      viewModel.title,
      style: AppTypography.heading.copyWith(
        color: titleIsTentative
            ? AppColors.textSecondary
            : AppColors.textPrimary,
        fontStyle: titleIsTentative ? FontStyle.italic : FontStyle.normal,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _chipRow(List<ParsedAttribute> visible, int overflow) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final ParsedAttribute attr in visible)
          ConfidenceChip(
            label: attr.displayValue,
            leadingIcon: attr.icon,
            state: attr.confidence.isTentative
                ? ConfidenceChipState.tentative
                : ConfidenceChipState.confirmed,
            onTap: () => onChipTap?.call(attr),
          ),
        if (overflow > 0)
          ConfidenceChip(
            label: '+$overflow more',
            state: ConfidenceChipState.tentative,
            onTap: onExpand,
          ),
      ],
    );
  }

  Widget _actionRow() {
    return Align(
      alignment: Alignment.centerRight,
      child: _AddToPlanButton(onTap: onConfirm),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dismiss-x — top right corner
// ─────────────────────────────────────────────────────────────────────────────

class _DismissButton extends StatelessWidget {
  const _DismissButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Dismiss this card. Your raw text is kept.',
      excludeSemantics: true,
      child: SizedBox(
        // Visual size 24px, hit target 32px — slightly under the 48
        // minimum because it sits *inside* the larger card hit area.
        // The card itself takes the residual taps, so the user can't
        // accidentally not-tap something. The lower minimum is a
        // deliberate exception, not an oversight.
        width: 32,
        height: 32,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap?.call();
            },
            child: const Center(
              child: Icon(
                Icons.close,
                size: 18,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add-to-plan — the primary commit pill
// ─────────────────────────────────────────────────────────────────────────────

class _AddToPlanButton extends StatelessWidget {
  const _AddToPlanButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add to plan',
      excludeSemantics: true,
      child: Material(
        color: AppColors.brandPrimary,
        borderRadius: AppSpacing.borderRadiusPill,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap?.call();
          },
          splashColor: AppColors.brandDark.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Add to plan', style: AppTypography.bodyOnBrand),
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: AppColors.surfacePrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}