import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/logger.dart';
import '../../../data/local/database.dart';
import '../../../data/local/database_provider.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/repositories/intention_repository.dart';
import '../../../domain/repositories/plan_item_repository.dart';

part 'card_action_service.g.dart';

/// Orchestrates the two confirmation-card actions:
///   - [confirm]: marks the plan item as user-confirmed.
///   - [dismiss]: deletes the plan item and marks the source intention
///     as dismissed so the card stops being "pending."
///
/// Both actions run inside a database transaction so a crash mid-flight
/// can't leave the data in a half-confirmed state.
@Riverpod(keepAlive: true)
CardActionService cardActionService(CardActionServiceRef ref) {
  return CardActionService(
    db: ref.watch(databaseProvider),
    intentionRepo: ref.watch(intentionRepositoryProvider),
    planRepo: ref.watch(planItemRepositoryProvider),
  );
}

class CardActionService {
  CardActionService({
    required AurganizeDatabase db,
    required IntentionRepository intentionRepo,
    required PlanItemRepository planRepo,
  })  : _db = db,
        _intentionRepo = intentionRepo,
        _planRepo = planRepo;

  final AurganizeDatabase _db;
  final IntentionRepository _intentionRepo;
  final PlanItemRepository _planRepo;

  static final Logger _log = appLogger('CardActionService');

  /// Accepts the card. Single repo call but wrapped here so the action
  /// has a name in the feature layer.
  Future<void> confirm({required String planItemId}) async {
    await _planRepo.markConfirmed(planItemId);
    _log.info('confirmed plan item $planItemId');
  }

  /// Rejects the card.
  ///
  /// Deletes the plan item and any of its children (via FK cascade —
  /// see Phase 02 Part 02 schema). If this was the only plan item
  /// spawned by the source intention, marks the intention as
  /// dismissed. If the source intention spawned multiple plan items
  /// and only this one is being dismissed, the intention stays parsed
  /// — the remaining plan items are still valid.
  Future<void> dismiss({
    required String planItemId,
    required String intentionId,
  }) async {
    await _db.transaction<void>(() async {
      await _planRepo.delete(planItemId);

      final remaining = await _planRepo.findByIntention(intentionId);
      if (remaining.isEmpty) {
        await _intentionRepo.markDismissed(intentionId);
        _log.info(
          'dismissed plan item $planItemId; intention $intentionId '
              'fully dismissed (no remaining plan items)',
        );
      } else {
        _log.info(
          'dismissed plan item $planItemId; intention $intentionId '
              'retained (${remaining.length} plan item(s) remain)',
        );
      }
    });
  }
}