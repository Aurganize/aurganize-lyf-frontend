import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/enums/plan_item_state.dart';
import '../../domain/enums/temperature.dart';
import 'temperature_dot.dart';

/// A single actionable row in the today peek, leftover view, and the
/// project-view children stack — PDD §9.4.
///
/// ### Anatomy
///
/// ```
///  ╭───────────────────────────────────────────────────────────╮
///  │ • ▎ Pick up the dry cleaning                           ✓ │
///  │   ▎ this week                                            │
///  ╰───────────────────────────────────────────────────────────╯
/// ```
///
///   - `•`        Temperature dot
///   - Title      Body weight, single line, ellipsized on overflow
///   - Time hint  Caption weight, single line, muted
///   - `✓`        Check icon — tappable target that fires the disposition
///                prompt. Always 48px touch target, painted at 18px.
///
/// ### States
///
///   - [PlanItemState.planned], [PlanItemState.inProgress] — default look.
///   - [PlanItemState.done] — title is strikethrough+muted, dot dimmed,
///     check icon is brand-filled.
///   - [PlanItemState.skipped] — title is muted, dot dimmed,
///     check icon is hidden (it's terminal, nothing to disposition).
///   - [PlanItemState.rescheduled] — treated like [PlanItemState.planned]
///     for rendering purposes (it transitions back to planned immediately).
class PlanItemRow extends StatelessWidget {
  const PlanItemRow({
    super.key,
    required this.title,
    required this.temperature,
    required this.state,
    this.timeHint,
    this.showDivider = true,
    this.onTap,
    this.onDispositionTap,
  });

  final String title;
  final Temperature temperature;
  final PlanItemState state;

  /// Optional second-line caption. Examples: "9:00 AM · daily",
  /// "this week", "Friday", "whenever". When null, the row is 1-line
  /// tall (still 38px overall — the title is vertically centered).
  final String? timeHint;

  /// Whether to paint the bottom divider. Callers pass `false` for the
  /// last row in a section.
  final bool showDivider;

  /// Tapping the title region — opens detail / project view.
  final VoidCallback? onTap;

  /// Tapping the check icon — fires the disposition prompt.
  final VoidCallback? onDispositionTap;

  // ── Derived appearance ───────────────────────────────────────────────────

  bool get _isCompleted => state == PlanItemState.done;
  bool get _isSkipped => state == PlanItemState.skipped;
  bool get _isMuted => _isCompleted || _isSkipped;

  TextStyle get _titleStyle {
    if (_isCompleted) return AppTypography.bodyStrikethrough;
    if (_isSkipped) return AppTypography.bodyMuted;
    return AppTypography.body;
  }

  String _composedSemanticsLabel() {
    final StringBuffer buf = StringBuffer(title);
    if (timeHint != null) {
      buf.write(', ');
      buf.write(timeHint);
    }
    buf.write(', ');
    buf.write(switch (temperature) {
      Temperature.hot => 'hot temperature',
      Temperature.warm => 'warm temperature',
      Temperature.cool => 'cool temperature',
    });
    if (_isCompleted) buf.write(', completed');
    if (_isSkipped) buf.write(', skipped');
    return buf.toString();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.planItemRowHeight),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Body — left of the check. Single semantics node combining
              // title, time hint, temperature label.
              Expanded(
                child: MergeSemantics(
                  child: Semantics(
                    button: true,
                    label: _composedSemanticsLabel(),
                    excludeSemantics: true,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Opacity(
                                opacity: _isMuted ? 0.45 : 1,
                                child: TemperatureDot(temperature: temperature),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      title,
                                      style: _titleStyle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (timeHint != null) ...<Widget>[
                                      const SizedBox(height: 2),
                                      Text(
                                        timeHint!,
                                        style: AppTypography.caption,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Check icon — separate hit area, distinct semantics.
              // Hidden when the item is skipped (no disposition to do).
              if (!_isSkipped)
                _CheckIconHitTarget(
                  done: _isCompleted,
                  onTap: onDispositionTap,
                ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            color: AppColors.borderDefault,
            thickness: 0.5,
            height: 0,
          ),
      ],
    );
  }
}

/// The right-edge check icon and its enlarged tap zone.
class _CheckIconHitTarget extends StatelessWidget {
  const _CheckIconHitTarget({required this.done, this.onTap});

  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final IconData icon =
    done ? Icons.check_circle : Icons.radio_button_unchecked;
    final Color color =
    done ? AppColors.brandPrimary : AppColors.textTertiary;

    return Semantics(
      button: true,
      label: done ? 'Mark as not done' : 'Disposition this item',
      excludeSemantics: true,
      child: SizedBox(
        width: AppSpacing.minTouchTarget,
        height: AppSpacing.minTouchTarget,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: Icon(icon, size: 22, color: color),
            ),
          ),
        ),
      ),
    );
  }
}