import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Visual state of a [DayTile]. Drives color, border, and text color.
enum DayTileState {
  /// Today / the day the user has currently selected. Brand fill,
  /// white text. Exactly one tile in a date train is focused.
  focused,

  /// A regular day. Outlined card, dark text. The most common state.
  defaultState,

  /// A day with no items. No border, faded text. Communicates "nothing
  /// to see here" without removing the affordance.
  dim,
}

/// Specifies the count pill shown at the bottom of the tile.
///
/// Two flavors:
///   - [DayTilePill.total] for the focused tile — total items on that day,
///     drawn on a translucent white pill against the brand fill.
///   - [DayTilePill.leftover] for past days with un-dispositioned items —
///     amber (yesterday) or coral (older). Distinguished by [olderThanYesterday].
sealed class DayTilePill {
  const DayTilePill();

  /// The count shown inside the pill.
  int get count;

  const factory DayTilePill.total({required int count}) = _TotalPill;
  const factory DayTilePill.leftover({
    required int count,
    required bool olderThanYesterday,
  }) = _LeftoverPill;
}

class _TotalPill extends DayTilePill {
  const _TotalPill({required this.count});
  @override
  final int count;
}

class _LeftoverPill extends DayTilePill {
  const _LeftoverPill({required this.count, required this.olderThanYesterday});
  @override
  final int count;
  final bool olderThanYesterday;
}

/// A 40×52 day chip in the horizontal date train (PDD §9.1, §13).
///
/// Examples:
/// ```dart
/// DayTile(
///   weekdayLabel: 'TUE',
///   dayOfMonth: 16,
///   state: DayTileState.focused,
///   pill: const DayTilePill.total(count: 4),
///   fullDateForA11y: 'Tuesday, May 16, 2026',
///   onTap: () { ... },
/// )
/// ```
class DayTile extends StatelessWidget {
  const DayTile({
    super.key,
    required this.weekdayLabel,
    required this.dayOfMonth,
    required this.state,
    required this.fullDateForA11y,
    this.pill,
    this.onTap,
  });

  /// Three-letter uppercase weekday — "MON", "TUE", etc.
  /// Localized by the caller; the widget does not format dates itself.
  final String weekdayLabel;

  /// Numeric day of month, 1..31.
  final int dayOfMonth;

  final DayTileState state;

  /// The optional count pill. Null means no pill.
  final DayTilePill? pill;

  /// Full date string used as the screen-reader label. The caller
  /// composes the locale-correct string (e.g. "Tuesday, May 16, 2026").
  final String fullDateForA11y;

  final VoidCallback? onTap;

  // ── Color resolution ──────────────────────────────────────────────────────

  Color get _surfaceColor {
    return switch (state) {
      DayTileState.focused => AppColors.brandPrimary,
      DayTileState.defaultState => AppColors.surfacePrimary,
      DayTileState.dim => AppColors.surfacePrimary,
    };
  }

  Color get _textColor {
    return switch (state) {
      DayTileState.focused => AppColors.surfacePrimary,
      DayTileState.defaultState => AppColors.textPrimary,
      DayTileState.dim => AppColors.textTertiary,
    };
  }

  Border? get _border {
    return switch (state) {
      DayTileState.focused => null,
      DayTileState.defaultState =>
          Border.all(color: AppColors.borderDefault, width: 0.5),
      DayTileState.dim => null,
    };
  }

  // ── Semantics ─────────────────────────────────────────────────────────────

  String _composedSemanticsLabel() {
    final StringBuffer buf = StringBuffer(fullDateForA11y);
    final DayTilePill? p = pill;
    if (p != null) {
      buf.write(', ');
      switch (p) {
        case _TotalPill(:final int count):
          buf.write('$count ${count == 1 ? "item" : "items"} today');
        case _LeftoverPill(:final int count, :final bool olderThanYesterday):
          final String span = olderThanYesterday ? 'older' : 'yesterday';
          buf.write('$count leftover ${count == 1 ? "item" : "items"} from $span');
      }
    }
    if (state == DayTileState.focused) {
      buf.write(', currently selected');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      width: AppSpacing.dayTileWidth,
      height: AppSpacing.dayTileHeight,
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: _border,
        borderRadius: AppSpacing.borderRadiusMedium,
      ),
      // The tile has fixed dimensions, so the content layout is a
      // straightforward Column. The pill, when present, hugs the bottom.
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    weekdayLabel,
                    style: AppTypography.eyebrow.copyWith(
                      color: _textColor.withValues(
                        alpha: state == DayTileState.focused ? 0.85 : 1.0,
                      ),
                    ),
                  ),
                  Text(
                    '$dayOfMonth',
                    style: AppTypography.heading.copyWith(color: _textColor),
                  ),
                ],
              ),
            ),
          ),
          if (pill != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 4,
              child: Center(child: _PillView(pill: pill!, state: state)),
            ),
        ],
      ),
    );

    return Semantics(
      button: true,
      label: _composedSemanticsLabel(),
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.borderRadiusMedium,
          child: content,
        ),
      ),
    );
  }
}

/// Internal: the count pill at the bottom of the tile.
class _PillView extends StatelessWidget {
  const _PillView({required this.pill, required this.state});
  final DayTilePill pill;
  final DayTileState state;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, TextStyle style) = switch (pill) {
      _TotalPill() => (
      // Translucent white on the brand fill — PDD §9.1.
      AppColors.surfacePrimary.withValues(alpha: 0.22),
      AppColors.surfacePrimary,
      AppTypography.caption,
      ),
      _LeftoverPill(:final bool olderThanYesterday) => olderThanYesterday
          ? (
      AppColors.attentionCoralBackground,
      AppColors.attentionCoralForeground,
      AppTypography.captionCoral,
      )
          : (
      AppColors.attentionAmberBackground,
      AppColors.attentionAmberForeground,
      AppTypography.captionAmber,
      ),
    };

    return Container(
      // Pill horizontal padding kept small — the tile is only 40px wide.
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppSpacing.borderRadiusPill,
      ),
      child: Text('${pill.count}',
          style: style.copyWith(color: fg, height: 1.0)),
    );
  }
}