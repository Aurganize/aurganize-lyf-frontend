import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aurganize_lyf/core/extensions/datetime_extensions.dart';
import 'package:aurganize_lyf/data/repositories/repository_providers.dart';
import 'package:aurganize_lyf/domain/models/plan_item.dart';
import 'package:aurganize_lyf/domain/repositories/plan_item_repository.dart';
import 'package:aurganize_lyf/features/auth/auth_providers.dart';

part 'leftovers_provider.g.dart';

/// Plan items scheduled for [dayBucket] that have never been
/// dispositioned. Backs the leftover disposition view (PDD §20).
@riverpod
Stream<List<PlanItem>> leftoversForDate(
    LeftoversForDateRef ref, {
      required int dayBucket,
    }) async* {
  final String userId = await ref.watch(currentUserIdProvider.future);
  final PlanItemRepository repo = ref.watch(planItemRepositoryProvider);
  yield* repo.watchLeftoversForDay(
    userId: userId,
    date: DayBucket.asDateTime(dayBucket),
  );
}