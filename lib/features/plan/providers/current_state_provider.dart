import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aurganize_lyf/data/repositories/repository_providers.dart';
import 'package:aurganize_lyf/domain/enums/plan_item_state.dart';
import 'package:aurganize_lyf/domain/repositories/plan_item_repository.dart';

part 'current_state_provider.g.dart';

/// The derived current state of plan item [planItemId].
///
/// The state is a *function* of the disposition log (SRS FR-4.7).
/// Consumers should not store this — read it on demand, just before
/// they need it.
///
/// Note: this is a one-shot read, not a stream. The disposition
/// controller reads it inside its mutation to populate `priorState`;
/// widgets that need the live state subscribe to
/// [PlanItemRepository.watchHistoryFor] via a separate provider that
/// we'll add when there's a consumer.
@riverpod
Future<PlanItemState> currentStateFor(
    CurrentStateForRef ref, {
      required String planItemId,
    }) {
  final PlanItemRepository repo = ref.watch(planItemRepositoryProvider);
  return repo.currentStateFor(planItemId);
}