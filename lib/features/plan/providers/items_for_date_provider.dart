import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aurganize_lyf/core/extensions/datetime_extensions.dart';
import 'package:aurganize_lyf/data/repositories/repository_providers.dart';
import 'package:aurganize_lyf/domain/models/plan_item.dart';
import 'package:aurganize_lyf/domain/repositories/plan_item_repository.dart';
import 'package:aurganize_lyf/features/auth/auth_providers.dart';

part 'items_for_date_provider.g.dart';

/// Active plan items scheduled for the day represented by [dayBucket].
///
/// "Active" here means: scheduled for the day AND not yet in a terminal
/// disposition state (done / skipped). See [PlanItemRepository.watchForDay].
///
/// Parameterized by UTC day bucket — see the note in
/// `Phase_04_Part_03_Plan_Providers.md` about why we do not parameterize
/// by [DateTime].
@riverpod
Stream<List<PlanItem>> itemsForDate(
    ItemsForDateRef ref, {
      required int dayBucket,
    }) async* {
  final String userId = await ref.watch(currentUserIdProvider.future);
  final PlanItemRepository repo = ref.watch(planItemRepositoryProvider);
  yield* repo.watchForDay(
    userId: userId,
    date: DayBucket.asDateTime(dayBucket),
  );
}

/// Plan items scheduled for "today" — convenience wrapper over
/// [itemsForDateProvider]. Re-emits at the day boundary so a session
/// crossing midnight automatically advances.
@riverpod
Stream<List<PlanItem>> todayItems(TodayItemsRef ref) async* {
  while (true) {
    final int bucket = DayBucket.today();
    // Capture when this bucket will roll over.
    final DateTime nextMidnightUtc = DayBucket.asDateTime(bucket + 1);

    // Race the stream against the midnight tick. We forward everything
    // the stream yields, and break the outer loop when midnight arrives.
    final Stream<List<PlanItem>> underlying = ref.watch(
      itemsForDateProvider(dayBucket: bucket).stream,
    );

    final Completer<void> midnight = Completer<void>();
    final Timer timer = Timer(
      nextMidnightUtc.difference(DateTime.now().toUtc()),
          () => midnight.complete(),
    );

    try {
      // Pull from the stream until midnight completes.
      await for (final List<PlanItem> emit in underlying) {
        yield emit;
        if (midnight.isCompleted) break;
      }
    } finally {
      timer.cancel();
    }

    // Either the underlying stream closed (disposal) or midnight arrived.
    if (!midnight.isCompleted) {
      return; // disposed — exit the generator
    }
    // Loop and rebuild against the new bucket.
  }
}