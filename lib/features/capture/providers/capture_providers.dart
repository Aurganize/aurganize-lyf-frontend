import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/repositories/repository_providers.dart';
import '../../../domain/enums/parse_status.dart';
import '../../../domain/models/intention.dart';
import '../../../domain/models/plan_item.dart';
import '../../../domain/repositories/intention_repository.dart';
import '../../../domain/repositories/plan_item_repository.dart';
import '../../auth/auth_providers.dart';

part 'capture_providers.g.dart';

/// Recent captures for the current user, newest first.
///
/// Feeds the conversation panel's history view (PDD §15). Currently a
/// `Future` (one-shot read); we'll upgrade to a stream when the
/// conversation panel actually needs live updates in Phase 07.
@riverpod
Future<List<Intention>> recentCaptures(
    RecentCapturesRef ref, {
      int limit = 50,
    }) async {
  final String userId = await ref.watch(currentUserIdProvider.future);
  final IntentionRepository repo = ref.watch(intentionRepositoryProvider);
  return repo.findRecentForUser(userId, limit: limit);
}

/// A single intention by id, for the confirmation card detail.
@riverpod
Future<Intention?> intentionById(
    IntentionByIdRef ref, {
      required String intentionId,
    }) {
  final IntentionRepository repo = ref.watch(intentionRepositoryProvider);
  return repo.findById(intentionId);
}

/// A single plan item by id.
@riverpod
Future<PlanItem?> planItemById(
    PlanItemByIdRef ref, {
      required String planItemId,
      bool includeChildren = false,
    }) {
  final PlanItemRepository repo = ref.watch(planItemRepositoryProvider);
  return repo.findById(planItemId, includeChildren: includeChildren);
}

/// All parsed plan items whose source intention is in
/// [ParseStatus.parsed] and which the user has not yet acted on
/// (confirmed or dismissed).
///
/// This is what the floating island's "N cards ready" binds to, and
/// what the peek-card stack on the landing screen renders.
///
/// Implemented by streaming the user's recent intentions and
/// filtering. For v1.0 the volume is small (a user's recent N captures);
/// we re-evaluate if usage forces it.
@riverpod
Stream<List<PendingCard>> pendingCards(PendingCardsRef ref) async* {
  final String userId = await ref.watch(currentUserIdProvider.future);
  final IntentionRepository intentionRepo =
  ref.watch(intentionRepositoryProvider);
  final PlanItemRepository planRepo = ref.watch(planItemRepositoryProvider);

  while (true) {
    final List<Intention> recent =
    await intentionRepo.findRecentForUser(userId, limit: 30);
    final List<PendingCard> cards = <PendingCard>[];

    for (final Intention i in recent) {
      if (i.parseStatus != ParseStatus.parsed) continue;

      final List<PlanItem> items = await planRepo.findByIntention(i.id);
      for (final PlanItem item in items) {
        if (item.confirmed) continue;
        if (await planRepo.hasAnyDisposition(item.id)) continue;
        cards.add(PendingCard(intention: i, planItem: item));
      }
    }

    yield cards;
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}

/// A peeking-card view model assembled from an intention + plan item.
class PendingCard {
  const PendingCard({required this.intention, required this.planItem});

  final Intention intention;
  final PlanItem planItem;
}