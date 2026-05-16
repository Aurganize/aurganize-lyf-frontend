import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Visual state of a [ConfidenceChip] — PDD §9.3.
enum ConfidenceChipState {
  /// System is sure — solid fill, dark text.
  confirmed,

  /// System is unsure — dashed border, no fill, "Tap to confirm or change".
  tentative,

  /// User is currently editing this chip — brand-light fill, brand-dark text.
  selected,
}

/// An editable inline pill that surfaces a parsed plan-item attribute.
///
/// Appears in:
///   - The confirmation card detail (PDD §16) as one row per attribute.
///   - Conversation bubbles containing parsed inferences (PDD §15).
///   - The peek card on the landing screen (PDD §14) as a horizontal chip row.
///
/// ### Usage
///
/// ```dart
/// ConfidenceChip(
///   label: 'This week',
///   leadingIcon: Icons.calendar_today_outlined,
///   state: ConfidenceChipState.tentative,
///   onTap: () => openEditor(),
/// )
/// ```
///
/// ### Tentative behavior
///
/// In the tentative state, tapping the chip opens an editor — this is
/// the user's path to correct a low-confidence inference. Tapping a
/// confirmed chip ALSO opens the editor (re-editing a confirmed value),
/// so the gesture is the same. The state difference is purely visual.
class ConfidenceChip extends StatelessWidget {
  const ConfidenceChip({
    super.key,
    required this.label,
    required this.state,
    this.leadingIcon,
    this.onTap,
  });

  final String label;
  final IconData? leadingIcon;
  final ConfidenceChipState state;
  final VoidCallback? onTap;

  // ── Color resolution ─────────────────────────────────────────────────────

  Color get _backgroundColor {
    return switch (state) {
      ConfidenceChipState.confirmed => AppColors.chipConfirmedBackground,
      ConfidenceChipState.tentative => Colors.transparent,
      ConfidenceChipState.selected => AppColors.chipSelectedBackground,
    };
  }

  Color get _foregroundColor {
    return switch (state) {
      ConfidenceChipState.confirmed => AppColors.chipConfirmedText,
      ConfidenceChipState.tentative => AppColors.textSecondary,
      ConfidenceChipState.selected => AppColors.chipSelectedText,
    };
  }

  TextStyle get _textStyle {
    final TextStyle base = AppTypography.body2.copyWith(
      color: _foregroundColor,
      fontWeight: state == ConfidenceChipState.selected
          ? FontWeight.w500
          : FontWeight.w400,
    );
    return base;
  }

  String _semanticsLabel() {
    return switch (state) {
      ConfidenceChipState.confirmed => '$label, confirmed, tap to edit',
      ConfidenceChipState.tentative =>
      '$label, tentative, tap to confirm or change',
      ConfidenceChipState.selected => '$label, editing',
    };
  }

  @override
  Widget build(BuildContext context) {
    // The chip is either a solid pill (confirmed/selected) or a dashed
    // outline (tentative). We dispatch on state at the decoration layer
    // so the inner content code stays a single Row.
    final Widget content = AnimatedContainer(
      duration: AppMotion.effectiveStateChange(context),
      curve: AppMotion.stateChangeCurve,
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: state == ConfidenceChipState.tentative
          ? null // dashed border painted by _DashedBorder below
          : BoxDecoration(
        color: _backgroundColor,
        borderRadius: AppSpacing.borderRadiusSmall,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (leadingIcon != null) ...<Widget>[
            Icon(leadingIcon, size: 14, color: _foregroundColor),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              style: _textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    final Widget painted = state == ConfidenceChipState.tentative
        ? CustomPaint(
      painter: _DashedBorderPainter(color: AppColors.borderStrong),
      child: content,
    )
        : content;

    return Semantics(
      button: true,
      label: _semanticsLabel(),
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.borderRadiusSmall,
          child: painted,
        ),
      ),
    );
  }
}

/// Paints a 6px-rounded dashed border. Used for the tentative chip
/// state — PDD §9.3.
///
/// We could pull in a dashed-border package, but the implementation is
/// ~20 lines and avoids a transitive dep.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1,
    this.dashLength = 3,
    this.gapLength = 3,
    this.radius = AppSpacing.radiusSmall,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final RRect rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final Path path = Path()..addRRect(rrect);
    final PathMetric metric = path.computeMetrics().first;
    double dist = 0.0;
    final double total = metric.length;
    final double stride = dashLength + gapLength;
    while (dist < total) {
      final double end = (dist + dashLength).clamp(0.0, total);
      canvas.drawPath(
        metric.extractPath(dist, end),
        paint,
      );
      dist += stride;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color ||
          old.strokeWidth != strokeWidth ||
          old.dashLength != dashLength ||
          old.gapLength != gapLength ||
          old.radius != radius;
}