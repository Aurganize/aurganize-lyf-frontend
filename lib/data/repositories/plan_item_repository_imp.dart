import 'package:collection/collection.dart';

import '../../core/extensions/datetime_extensions.dart';
import '../../domain/enums/plan_item_state.dart';
import '../../domain/models/disposition_event.dart';
import '../../domain/models/plan_item.dart';
import '../../domain/repositories/plan_item_repository.dart';
import '../local/daos/disposition_event_dao.dart';
import '../local/daos/plan_item_dao.dart';
import '../local/database.dart';
import '../local/mappers.dart';
import '../local/tables/disposition_event_table.dart';
import '../local/tables/plan_items_table.dart';

import 'package:uuid/uuid.dart';


class DriftPlanItemRepository implements PlanItemRepository {
  DriftPlanItemRepository(
      this._db,
      this._planDao,
      this._eventDao,
      );

  final AurganizeDatabase _db;
  final PlanItemDao _planDao;
  final DispositionEventDao _eventDao;
  // Inside the class, add a field:
  final Uuid _uuid = const Uuid();

  // ───────────────────────────────────────────────────────────────────────────
  // Plan item CRUD
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Future<PlanItem> create(PlanItem item) async {
    final DateTime now = DateTime.now().toUtc();
    await _planDao.insertPlanItem(item.toCompanion(now: now));
    return item;
  }

  @override
  Future<void> createMany(List<PlanItem> items) async {
    final DateTime now = DateTime.now().toUtc();
    await _planDao.insertPlanItems(
      items.map((PlanItem i) => i.toCompanion(now: now)).toList(),
    );
  }

  @override
  Future<PlanItem?> findById(String id, {bool includeChildren = false}) async {
    if (!includeChildren) {
      final PlanItemRow? row = await _planDao.findById(id);
      return row?.toDomain();
    }
    final List<PlanItemRow> subtree = await _planDao.findSubtree(id);
    if (subtree.isEmpty) return null;
    return _assembleTree(subtree, rootId: id);
  }

  @override
  Future<List<PlanItem>> findByIntention(String intentionId) async {
    final List<PlanItemRow> rows = await _planDao.findByIntention(intentionId);
    return rows
        .map((PlanItemRow r) => r.toDomain())
        .toList(growable: false);
  }

  @override
  Future<PlanItem> update(PlanItem item) async {
    final DateTime now = DateTime.now().toUtc();
    await _planDao.updatePlanItem(item.toCompanion(now: now));
    return item.copyWith(updatedAt: now);
  }

  @override
  Future<void> delete(String id) => _planDao.deletePlanItem(id);

  // ───────────────────────────────────────────────────────────────────────────
  // Day views
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Stream<List<PlanItem>> watchForDay({
    required String userId,
    required DateTime date,
  }) {
    final int bucket = date.utcDayBucket;
    return _planDao
        .watchForDay(userId: userId, bucket: bucket)
        .map((List<PlanItemRow> rows) =>
        rows.map((PlanItemRow r) => r.toDomain()).toList(growable: false));
  }

  @override
  Stream<List<PlanItem>> watchLeftoversForDay({
    required String userId,
    required DateTime date,
  }) {
    final int bucket = date.utcDayBucket;
    return _planDao
        .watchLeftoversForDay(userId: userId, bucket: bucket)
        .map((List<PlanItemRow> rows) =>
        rows.map((PlanItemRow r) => r.toDomain()).toList(growable: false));
  }

  @override
  Future<Map<DateTime, int>> leftoverCountsByDay({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    final Map<int, int> bucketCounts = await _planDao.leftoverCountsByDay(
      userId: userId,
      fromBucket: from.utcDayBucket,
      toBucket: to.utcDayBucket,
    );
    return bucketCounts.map<DateTime, int>(
          (int bucket, int count) => MapEntry<DateTime, int>(
        DayBucket.asDateTime(bucket),
        count,
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Project tree
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Stream<PlanItem?> watchProjectTree(String rootId) {
    return _planDao.watchSubtree(rootId).map((List<PlanItemRow> rows) {
      if (rows.isEmpty) return null;
      return _assembleTree(rows, rootId: rootId);
    });
  }

  /// Assembles a flat BFS-ordered list of rows into a [PlanItem] tree.
  ///
  /// The CTE returns rows ordered by level ascending, so the root is
  /// always first. We index by id, then walk a second time attaching
  /// each row to its parent's `children` list.
  PlanItem _assembleTree(List<PlanItemRow> rows, {required String rootId}) {
    // First pass: convert rows to mutable domain entries with empty children.
    final Map<String, _MutableNode> nodes = <String, _MutableNode>{
      for (final PlanItemRow row in rows) row.id: _MutableNode(row.toDomain()),
    };

    // Second pass: link children to parents.
    for (final PlanItemRow row in rows) {
      final String? parentId = row.parentId;
      if (parentId == null || parentId == rootId && row.id == rootId) continue;
      if (parentId == rootId || nodes.containsKey(parentId)) {
        final _MutableNode? parent = nodes[parentId];
        final _MutableNode? self = nodes[row.id];
        if (parent != null && self != null) {
          parent.children.add(self);
        }
      }
    }

    // Finalize: walk from the root, freezing children at each level.
    final _MutableNode root = nodes[rootId]!;
    return _freeze(root);
  }

  PlanItem _freeze(_MutableNode node) {
    final List<PlanItem> children =
    node.children.map(_freeze).toList(growable: false);
    return node.item.copyWith(children: children);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Disposition
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Future<DispositionEvent> recordDisposition({
    required DispositionEvent event,
  }) async {
    // Wrap in a transaction so the prior-state check and the append are
    // atomic — otherwise two simultaneous dispositions could both pass
    // the check and append conflicting events.
    return _db.transaction<DispositionEvent>(() async {
      final PlanItemState currentState = await currentStateFor(event.planItemId);
      if (currentState != event.priorState) {
        throw StateError(
          'Stale disposition: caller expected priorState=${event.priorState.name}, '
              'but the current state is ${currentState.name}.',
        );
      }
      await _eventDao.append(event.toCompanion());
      return event;
    });
  }

  @override
  Future<List<DispositionEvent>> historyFor(String planItemId) async {
    final List<DispositionEventRow> rows = await _eventDao.history(planItemId);
    return rows
        .map((DispositionEventRow r) => r.toDomain())
        .toList(growable: false);
  }

  @override
  Stream<List<DispositionEvent>> watchHistoryFor(String planItemId) {
    return _eventDao.watchHistory(planItemId).map(
          (List<DispositionEventRow> rows) => rows
          .map((DispositionEventRow r) => r.toDomain())
          .toList(growable: false),
    );
  }

  @override
  Future<PlanItemState> currentStateFor(String planItemId) async {
    final DispositionEventRow? latest = await _eventDao.latestFor(planItemId);
    if (latest == null) return PlanItemState.planned;
    if (latest.newState == PlanItemState.rescheduled) {
      // SRS FR-4.5: rescheduled returns the item to planned.
      return PlanItemState.planned;
    }
    return latest.newState;
  }

  @override
  Future<PlanItemState> applyDisposition({
    required String planItemId,
    required PlanItemState priorState,
    required PlanItemState newState,
    required bool prompted,
    DateTime? rescheduleTo,
  }) async {
    if (newState == PlanItemState.rescheduled && rescheduleTo == null) {
      throw ArgumentError(
        'rescheduleTo is required when newState is PlanItemState.rescheduled',
      );
    }

    return _db.transaction<PlanItemState>(() async {
      final DateTime now = DateTime.now().toUtc();

      // 1. Always append the primary event.
      await recordDisposition(
        event: DispositionEvent(
          id: _uuid.v4(),
          planItemId: planItemId,
          priorState: priorState,
          newState: newState,
          prompted: prompted,
          occurredAt: now,
          rescheduledTo: newState == PlanItemState.rescheduled
              ? rescheduleTo
              : null,
        ),
      );

      if (newState != PlanItemState.rescheduled) {
        return newState;
      }

      // 2. Reschedule: append the auto-collapse event AND move the row.
      //
      // The collapse event records the "rescheduled → planned" transition
      // for audit completeness. Without it, the latest event in the log
      // would forever show "rescheduled", which is misleading.
      await recordDisposition(
        event: DispositionEvent(
          id: _uuid.v4(),
          planItemId: planItemId,
          priorState: PlanItemState.rescheduled,
          newState: PlanItemState.planned,
          prompted: false,
          occurredAt: now.add(const Duration(milliseconds: 1)),
        ),
      );

      await _planDao.updateScheduledForDay(
        planItemId,
        rescheduleTo!.utcDayBucket,
      );

      return PlanItemState.planned;
    });
  }

}

/// Internal mutable scaffold for tree assembly. Discarded after [_freeze].
class _MutableNode {
  _MutableNode(this.item);
  final PlanItem item;
  final List<_MutableNode> children = <_MutableNode>[];
}