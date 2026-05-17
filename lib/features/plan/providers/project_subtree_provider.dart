import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:aurganize_lyf/data/repositories/repository_providers.dart';
import 'package:aurganize_lyf/domain/models/plan_item.dart';
import 'package:aurganize_lyf/domain/repositories/plan_item_repository.dart';

part 'project_subtree_provider.g.dart';

/// Live stream of a project subtree rooted at [rootId].
///
/// Returns `null` if the root is deleted. Re-emits whenever any
/// descendant changes — caller widgets are free to consume the new
/// snapshot or diff against the previous one.
@riverpod
Stream<PlanItem?> projectSubtree(
    ProjectSubtreeRef ref, {
      required String rootId,
    }) {
  final PlanItemRepository repo = ref.watch(planItemRepositoryProvider);
  return repo.watchProjectTree(rootId);
}