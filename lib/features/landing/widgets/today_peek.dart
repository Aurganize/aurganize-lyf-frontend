import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/datetime_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/enums/plan_item_state.dart';
import '../../../domain/models/item_time.dart';
import '../../../domain/models/plan_item.dart';
import '../../../shared/widgets/plan_item_row.dart';
import '../../disposition/presentation/dispose_from_ui.dart';
import '../../disposition/presentation/disposition_action.dart';
import '../../disposition/presentation/show_disposition_sheet.dart';
import '../../disposition/providers/disposition_controller.dart';
import '../../disposition/providers/question_rotator.dart';
import '../../plan/providers/items_for_date_provider.dart';

/// The "today peek" section of the landing screen — PDD §13.
///
/// Stateless from the outside: the date to display is the bucket of the
/// currently-selected day train tile, supplied via [dayBucket]. The
/// peek subscribes to [itemsForDateProvider] internally.
///
/// ### State machine
///
///   - Loading       → 3 skeleton rows
///   - data, empty   → empty-state copy (varies by whether it's today and
///                     whether the user has ever had items)
///   - data, with    → up to 4 [PlanItemRow]s. Beyond 4, the 4th becomes
///       items        a "+N more" row.
///   - error         → small inline error message, never blocks capture
///
/// The peek does NOT navigate on its own. Row taps fire [onRowTap] which
/// is the host's hook into the future "/detail/:planItemId" route
/// (defined in Phase 05 Part 05). Check-icon taps fire the disposition
/// sheet directly — this is the supportive enforcer's hot path and we
/// don't want a routing layer in the way.
class TodayPeek extends ConsumerWidget {
  const TodayPeek({
    super.key,
    required this.dayBucket,
    required this.onRowTap,
    this.maxRows = 4,
  });

  /// UTC day bucket of the day to display. Passed in (rather than
  /// internally read from `selectedDayProvider`) so the peek can be
  /// rendered against any day in tests.
  final int dayBucket;

  /// Called when the user taps a row's title region.
  final void Function(PlanItem item) onRowTap;

  /// Maximum number of rows rendered inline before collapsing to
  /// "+N more". Defaults to 4 per PDD §13.
  final int maxRows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PlanItem>> async =
    ref.watch(itemsForDateProvider(dayBucket: dayBucket));
    final int todayBucket = DayBucket.today();
    final bool isToday = dayBucket == todayBucket;
    final bool isPast = dayBucket < todayBucket;

    return async.when(
      loading: _SkeletonRows.new,
      error: (Object error, _) => _PeekError(error: error),
      data: (List<PlanItem> items) {
        if (items.isEmpty) {
          return _EmptyOrAllCleared(isToday: isToday, isPast: isPast);
        }
        return _RealRows(
          items: items,
          maxRows: maxRows,
          onRowTap: onRowTap,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Eyebrow + content composer
// ─────────────────────────────────────────────────────────────────────────────

class _PeekFrame extends StatelessWidget {
  const _PeekFrame({required this.eyebrow, required this.child});

  final String eyebrow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(eyebrow, style: AppTypography.eyebrow),
          ),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonRows extends StatelessWidget {
  const _SkeletonRows();

  @override
  Widget build(BuildContext context) {
    return _PeekFrame(
      eyebrow: 'TODAY',
      child: Column(
        children: <Widget>[
          for (int i = 0; i < 3; i++)
            const _SkeletonRow(),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.planItemRowHeight,
      child: Row(
        children: <Widget>[
          const SizedBox(width: AppSpacing.lg),
          Container(
            width: AppSpacing.temperatureDotSize,
            height: AppSpacing.temperatureDotSize,
            decoration: const BoxDecoration(
              color: AppColors.surfaceSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 12,
                  width: 180,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 90,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty / all-cleared state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyOrAllCleared extends StatelessWidget {
  const _EmptyOrAllCleared({required this.isToday, required this.isPast});

  final bool isToday;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    // PDD §13: when today's items are all cleared, "You've checked in
    // with everything today. Nice." When the day legitimately has no
    // items, "Nothing on your plate yet. Tap below to add anything on
    // your mind."
    //
    // We can't tell from the absence of items whether the user has ever
    // had items today — both states surface as `items.isEmpty`. For the
    // initial implementation we always use the new-user copy for today;
    // Phase 10 (gamification) wires the engagement-counted variant and
    // we'll swap based on whether disposition events exist for the day.
    final String message = switch ((isToday, isPast)) {
      (true, _) => 'Nothing on your plate yet. Tap below to add anything '
          'on your mind.',
      (_, true) => 'This day is closed out. You\'re square.',
      (_, _) => 'Nothing on this day. A clean slate is fine.',
    };

    return _PeekFrame(
      eyebrow: isToday ? 'TODAY' : 'THIS DAY',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(message, style: AppTypography.body),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error inline (small)
// ─────────────────────────────────────────────────────────────────────────────

class _PeekError extends StatelessWidget {
  const _PeekError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return _PeekFrame(
      eyebrow: 'TODAY',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          'Couldn\'t load today. $error',
          style: AppTypography.bodyMuted,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Real rows
// ─────────────────────────────────────────────────────────────────────────────

class _RealRows extends ConsumerWidget {
  const _RealRows({
    required this.items,
    required this.maxRows,
    required this.onRowTap,
  });

  final List<PlanItem> items;
  final int maxRows;
  final void Function(PlanItem item) onRowTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int total = items.length;
    final int overflow = total - maxRows;
    final List<PlanItem> visible =
    items.take(overflow > 0 ? maxRows - 1 : maxRows).toList(growable: false);

    return _PeekFrame(
      eyebrow: 'TODAY · $total ${total == 1 ? "ITEM" : "ITEMS"}',
      child: Column(
        children: <Widget>[
          for (int i = 0; i < visible.length; i++)
            PlanItemRow(
              key: ValueKey<String>(visible[i].id),
              title: visible[i].title,
              temperature: visible[i].temperature,
              state: PlanItemState.planned, // active items only
              timeHint: _timeHintFor(visible[i].time),
              showDivider: i < visible.length - 1 || overflow > 0,
              onTap: () {
                if (visible[i].isProject) {
                  // Project items → project view.
                  onRowTap(visible[i]); // host decides; landing routes appropriately
                } else {
                  onRowTap(visible[i]);
                }
              },
              onDispositionTap: () async {
                await disposeFromUi(
                  context: context,
                  ref: ref,
                  item: visible[i],
                  prompted: true,
                );
              },
            ),
          if (overflow > 0) _SeeAllRow(remaining: overflow + 1),
        ],
      ),
    );
  }
}

class _SeeAllRow extends StatelessWidget {
  const _SeeAllRow({required this.remaining});

  final int remaining;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open all $remaining items',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // The host will route this to a "full day" view in a future
            // phase. For now we no-op — surfaced as a TODO so we don't
            // ship a misleading row.
          },
          child: SizedBox(
            height: AppSpacing.planItemRowHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.expand_more, size: 18, color: AppColors.iconMuted),
                  const SizedBox(width: AppSpacing.md),
                  Text('Open all $remaining items', style: AppTypography.bodyMuted),
                  // The text content is supplied dynamically below.
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Renders the per-row time hint, e.g. "9:00 AM · daily", "this week",
/// "whenever".
///
/// Pulled out into a function rather than baked into the row so the
/// formatting rules are testable in isolation.
String? _timeHintFor(ItemTime time) {
  return time.when<String?>(
    hardTime: (DateTime at, _) {
      final DateFormat fmt = DateFormat.jm(); // e.g. 9:00 AM
      return fmt.format(at.toLocal());
    },
    timeWindow: (DateTime? from, DateTime until) {
      final DateTime localUntil = until.toLocal();
      final DateTime now = DateTime.now();
      final Duration diff = localUntil.difference(now);
      if (diff.inDays < 1) return 'today';
      if (diff.inDays < 7) {
        return 'by ${DateFormat.EEEE().format(localUntil)}';
      }
      return 'by ${DateFormat.MMMd().format(localUntil)}';
    },
    recurring: (String rrule, _, __) {
      if (rrule == 'FREQ=DAILY') return 'daily';
      if (rrule.startsWith('FREQ=WEEKLY;BYDAY=')) {
        final String byday = rrule.substring('FREQ=WEEKLY;BYDAY='.length);
        return 'every ${_dayName(byday)}';
      }
      if (rrule == 'FREQ=WEEKLY') return 'weekly';
      return 'recurring';
    },
    untimed: () => 'whenever',
  );
}

String _dayName(String byday) {
  return switch (byday) {
    'MO' => 'Monday',
    'TU' => 'Tuesday',
    'WE' => 'Wednesday',
    'TH' => 'Thursday',
    'FR' => 'Friday',
    'SA' => 'Saturday',
    'SU' => 'Sunday',
    _ => byday,
  };
}

