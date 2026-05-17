import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aurganize_lyf/core/extensions/datetime_extensions.dart';
import 'package:aurganize_lyf/data/repositories/repository_providers.dart';
import 'package:aurganize_lyf/domain/repositories/plan_item_repository.dart';
import 'package:aurganize_lyf/shared/widgets/date_train.dart';
import 'package:aurganize_lyf/shared/widgets/day_tile.dart';
import 'package:aurganize_lyf/features/auth/auth_providers.dart';
import 'items_for_date_provider.dart';
import 'plan_window.dart';

part 'date_train_provider.g.dart';

/// Selected day on the date train. Persists across rebuilds, defaults
/// to today.
///
/// Held in a [Notifier] so it can be set by tile taps from the
/// landing screen and read by other providers without prop-drilling.
@Riverpod(keepAlive: true)
class SelectedDay extends _$SelectedDay {
  @override
  int build() => DayBucket.today();

  /// Set the focused day to [dayBucket]. Idempotent.
  void select(int dayBucket) {
    if (state != dayBucket) state = dayBucket;
  }

  /// Reset the focused day to today. Called when the user pulls down
  /// on the date train, taps the streak chip, or otherwise indicates
  /// "take me home".
  void resetToToday() => select(DayBucket.today());
}

/// Prepared date-train entries for the default rolling window.
///
/// Composes:
///   - The window from [DayWindow.defaultTrain].
///   - Leftover counts per past day from the repository.
///   - Active item counts for today from [itemsForDateProvider].
///   - The focus state derived from [selectedDayProvider].
///
/// Returns an [AsyncValue] because resolving the leftover counts is
/// a one-shot future. The list re-emits whenever any underlying
/// stream changes — leftover counts when a disposition happens,
/// today count when items are added/removed.
@riverpod
Future<List<DateTrainEntry>> dateTrainEntries(
    DateTrainEntriesRef ref,
    ) async {
  final String userId = await ref.watch(currentUserIdProvider.future);
  final PlanItemRepository repo = ref.watch(planItemRepositoryProvider);
  final int selected = ref.watch(selectedDayProvider);
  final int todayBucket = DayBucket.today();
  final DayWindow window = DayWindow.defaultTrain();

  // Leftover counts for the *past* portion of the window.
  final Map<DateTime, int> leftoverCounts = await repo.leftoverCountsByDay(
    userId: userId,
    from: DayBucket.asDateTime(window.startBucket),
    to: DayBucket.asDateTime(todayBucket - 1),
  );

  // Today's active item count. We need this once for the focused
  // tile's total pill; watching itemsForDateProvider here would
  // cause the entire date-train rebuild on every per-item change.
  // We accept that — it's a few entries — but mark the consideration
  // so any future "this is expensive" complaint has context.
  final int todayCount =
      (await ref.watch(itemsForDateProvider(dayBucket: todayBucket).future))
          .length;

  // Compose each entry.
  final List<DateTrainEntry> out = <DateTrainEntry>[];
  for (final int bucket in window.buckets()) {
    final DateTime date = DayBucket.asDateTime(bucket);
    final DateTime localDate = date.toLocal();
    final String weekdayLabel = _weekdayLabel(localDate);
    final String fullA11y = _fullDateLabel(localDate);
    final bool isFocused = bucket == selected;
    final bool isToday = bucket == todayBucket;
    final bool isPast = bucket < todayBucket;
    final bool isFuture = bucket > todayBucket;

    DayTileState tileState;
    if (isFocused) {
      tileState = DayTileState.focused;
    } else if (isFuture && /* arbitrary "no items" hint */ true) {
      // We don't fetch future-day item counts in v1.0; future tiles
      // start dim and the user is invited to investigate. If they tap
      // a future day, the today peek swaps to that day and the user
      // sees its content; we'll mark this future tile non-dim in
      // a follow-up when item counts are cheap to aggregate.
      tileState = DayTileState.dim;
    } else {
      tileState = DayTileState.defaultState;
    }

    DayTilePill? pill;
    if (isToday) {
      pill = DayTilePill.total(count: todayCount);
    } else if (isPast) {
      final int? n = leftoverCounts[date];
      if (n != null && n > 0) {
        pill = DayTilePill.leftover(
          count: n,
          olderThanYesterday: bucket < todayBucket - 1,
        );
      }
    }

    out.add(DateTrainEntry(
      date: date,
      weekdayLabel: weekdayLabel,
      fullDateForA11y: fullA11y,
      state: tileState,
      pill: pill,
    ));
  }

  return out;
}

// ── Date formatting helpers ─────────────────────────────────────────────────

String _weekdayLabel(DateTime localDate) {
  // intl produces locale-correct three-letter abbreviations: 'TUE', 'MAR' etc.
  // We uppercase explicitly so locales whose intl returns 'Tue' still meet
  // the PDD's uppercase eyebrow style.
  return DateFormat.E().format(localDate).toUpperCase();
}

String _fullDateLabel(DateTime localDate) {
  // 'EEEE, MMMM d, y' → "Tuesday, May 16, 2026"
  return DateFormat.yMMMMEEEEd().format(localDate);
}