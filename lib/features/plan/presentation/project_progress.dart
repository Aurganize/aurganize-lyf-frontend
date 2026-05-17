import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/repositories/repository_providers.dart';
import '../../../domain/enums/plan_item_state.dart';
import '../../../domain/models/plan_item.dart';
import '../../../domain/repositories/plan_item_repository.dart';

part 'project_progress.g.dart';

/// Aggregated progress for a project subtree.
///
/// "Done" is counted on the **leaf** plan items — items without children.
/// A parent with two done children and two pending children is itself
/// 50% done in this calculation. The intermediate parent is not counted
/// as a separate unit; it's a container.
class ProjectProgress {
  const ProjectProgress({required this.done, required this.total});

  final int done;
  final int total;

  bool get isEmpty => total == 0;

  /// 0.0 → 1.0. Returns 1.0 when [isEmpty] so a no-children project
  /// reads as "complete" rather than "0%" — empty projects don't have
  /// pending work.
  double get fraction => total == 0 ? 1 : done / total;

  String get label {
    if (isEmpty) return 'No sub-items';
    return '$done of $total done';
  }
}

/// Live progress for the project rooted at [rootId]. Re-emits whenever
/// any descendant's disposition state changes.
///
/// Implementation note: we walk the assembled tree from
/// [projectSubtreeProvider], collect leaf IDs, and ask the repository
/// for each leaf's current state. There's a brute-force concern at
/// scale (N round-trips for N leaves) but for typical v1.0 projects —
/// 3–20 children, occasionally with grandchildren — the cost is well
/// under 50 ms. The repository's `currentStateFor` reads a single
/// indexed row each call.
@riverpod
Future<ProjectProgress> projectProgress(
    ProjectProgressRef ref, {
      required String rootId,
    }) async {
  final PlanItemRepository repo = ref.watch(planItemRepositoryProvider);
  final PlanItem? root = await repo.findById(rootId, includeChildren: true);
  if (root == null) {
    return const ProjectProgress(done: 0, total: 0);
  }

  final List<String> leafIds = <String>[];
  void collect(PlanItem node) {
    if (node.children.isEmpty) {
      // Don't count the root itself unless the project is leaf-only
      // (a project with zero children — rare; show as empty).
      leafIds.add(node.id);
      return;
    }
    for (final PlanItem c in node.children) {
      collect(c);
    }
  }

  for (final PlanItem c in root.children) {
    collect(c);
  }
  // If the root has no children, the calculator returns the root's own
  // count (0 or 1). That keeps "single-item project" sensible.
  if (leafIds.isEmpty) {
    leafIds.add(root.id);
  }

  int done = 0;
  for (final String id in leafIds) {
    final PlanItemState s = await repo.currentStateFor(id);
    if (s == PlanItemState.done) done++;
  }
  return ProjectProgress(done: done, total: leafIds.length);
}