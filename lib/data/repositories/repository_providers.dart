import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/intention_repository.dart';
import '../../domain/repositories/plan_item_repository.dart';
import '../local/database_provider.dart';
import 'intention_repository_impl.dart';
import 'plan_item_repository_imp.dart';

final Provider<IntentionRepository> intentionRepositoryProvider =
Provider<IntentionRepository>(
      (Ref ref) {
    return DriftIntentionRepository(ref.watch(databaseProvider).intentionDao);
  },
  name: 'intentionRepository',
);

final Provider<PlanItemRepository> planItemRepositoryProvider =
Provider<PlanItemRepository>(
      (Ref ref) {
    final db = ref.watch(databaseProvider);
    return DriftPlanItemRepository(db, db.planItemDao, db.dispositionEventDao);
  },
  name: 'planItemRepository',
);