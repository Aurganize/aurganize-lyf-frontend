import 'package:drift/drift.dart';

import '../../../core/extensions/datetime_extensions.dart';
import '../database.dart';
import '../tables/disposition_event_table.dart';
import '../tables/plan_items_table.dart';

part 'plan_item_dao.g.dart';

/// Data-access methods for the [PlanItems] table, including the
/// recursive-tree query used to load a project with all descendants.
@DriftAccessor(tables: <Type>[PlanItems, DispositionEvents])
class PlanItemDao extends DatabaseAccessor<AurganizeDatabase>
    with _$PlanItemDaoMixin {
  PlanItemDao(super.db);

  // ---------------------------------------------------------------------------
  // Single-item reads
  // ---------------------------------------------------------------------------

  Future<PlanItemRow?> findById(String id) {
    return (select(planItems)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<PlanItemRow>> findChildren(String parentId) {
    return (select(planItems)
      ..where((tbl) => tbl.parentId.equals(parentId))
      ..orderBy(<OrderClauseGenerator<PlanItems>>[
            (tbl) => OrderingTerm.asc(tbl.createdAt),
      ]))
        .get();
  }

  Future<List<PlanItemRow>> findByIntention(String intentionId) {
    return (select(planItems)
      ..where((tbl) => tbl.intentionId.equals(intentionId)))
        .get();
  }

  // ---------------------------------------------------------------------------
  // Day-view queries — the landing screen's lifeline
  // ---------------------------------------------------------------------------

  /// All scored plan items scheduled for [bucket] (a UTC day), excluding
  /// any whose latest disposition is a terminal state ([done] / [skipped]).
  ///
  /// "Latest disposition" is derived by joining against the disposition
  /// events table with a per-item correlated subquery.
  Stream<List<PlanItemRow>> watchForDay({
    required String userId,
    required int bucket,
  }) {
    // Drift's typed-select form for filtered, ordered reads. The
    // `customSelect` form for the not-in-terminal subquery keeps the
    // generated stream change-aware (it observes the disposition
    // events table too).
    return customSelect(
      r'''
      SELECT pi.* FROM plan_items pi
      WHERE pi.user_id = ?1
        AND pi.scheduled_for_day = ?2
        AND NOT EXISTS (
          SELECT 1 FROM disposition_events de
          WHERE de.plan_item_id = pi.id
            AND de.new_state IN ('done', 'skipped')
            AND de.occurred_at = (
              SELECT MAX(occurred_at) FROM disposition_events
              WHERE plan_item_id = pi.id
            )
        )
      ORDER BY pi.created_at ASC
      ''',
      variables: <Variable<Object>>[
        Variable<String>(userId),
        Variable<int>(bucket),
      ],
      readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
        planItems,
        dispositionEvents,
      },
    ).watch().map((List<QueryRow> rows) {
      return rows.map((row) => planItems.map(row.data)).toList();
    });
  }

  /// Items scheduled for [bucket] that the user never dispositioned —
  /// neither completed, nor skipped, nor put in progress. The leftover
  /// view (PDD §20) calls this for the past-day pills.
  Stream<List<PlanItemRow>> watchLeftoversForDay({
    required String userId,
    required int bucket,
  }) {
    return customSelect(
      r'''
      SELECT pi.* FROM plan_items pi
      WHERE pi.user_id = ?1
        AND pi.scheduled_for_day = ?2
        AND NOT EXISTS (
          SELECT 1 FROM disposition_events de
          WHERE de.plan_item_id = pi.id
        )
      ORDER BY pi.created_at ASC
      ''',
      variables: <Variable<Object>>[
        Variable<String>(userId),
        Variable<int>(bucket),
      ],
      readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
        planItems,
        dispositionEvents,
      },
    ).watch().map((List<QueryRow> rows) {
      return rows.map((row) => planItems.map(row.data)).toList();
    });
  }

  /// Count of leftover (never-dispositioned) items per past-day bucket
  /// within a window. Backs the count pills on date-train tiles.
  /// Returns a map of `dayBucket -> count`.
  Future<Map<int, int>> leftoverCountsByDay({
    required String userId,
    required int fromBucket,
    required int toBucket,
  }) async {
    final List<QueryRow> rows = await customSelect(
      r'''
      SELECT pi.scheduled_for_day AS day, COUNT(*) AS n
      FROM plan_items pi
      WHERE pi.user_id = ?1
        AND pi.scheduled_for_day BETWEEN ?2 AND ?3
        AND NOT EXISTS (
          SELECT 1 FROM disposition_events de WHERE de.plan_item_id = pi.id
        )
      GROUP BY pi.scheduled_for_day
      ''',
      variables: <Variable<Object>>[
        Variable<String>(userId),
        Variable<int>(fromBucket),
        Variable<int>(toBucket),
      ],
      readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
        planItems,
        dispositionEvents,
      },
    ).get();
    return <int, int>{
      for (final QueryRow row in rows) row.read<int>('day'): row.read<int>('n'),
    };
  }

  // ---------------------------------------------------------------------------
  // Recursive tree — project view
  // ---------------------------------------------------------------------------

  /// Returns all descendants of [rootId], breadth-first, **including
  /// the root**. The caller assembles the tree (see
  /// `PlanItemRepository.findById(..., includeChildren: true)`).
  ///
  /// Uses SQLite's WITH RECURSIVE CTE — O(depth × breadth) rather than
  /// O(depth) round-trips.
  Future<List<PlanItemRow>> findSubtree(String rootId) async {
    final List<QueryRow> rows = await customSelect(
      r'''
      WITH RECURSIVE descendants(level) AS (
        SELECT plan_items.*, 0 AS level FROM plan_items WHERE id = ?1
        UNION ALL
        SELECT pi.*, d.level + 1 FROM plan_items pi
        INNER JOIN descendants d ON pi.parent_id = d.id
      )
      SELECT * FROM descendants ORDER BY level ASC, created_at ASC
      ''',
      variables: <Variable<Object>>[Variable<String>(rootId)],
      readsFrom: <ResultSetImplementation<dynamic, dynamic>>{planItems},
    ).get();
    return rows.map((row) => planItems.map(row.data)).toList();
  }

  /// Stream variant of [findSubtree]. The stream emits whenever the
  /// plan_items table changes — fine-grained subtree change detection
  /// would require row-level triggers, which is overkill for v1.0.
  Stream<List<PlanItemRow>> watchSubtree(String rootId) {
    return customSelect(
      r'''
      WITH RECURSIVE descendants(level) AS (
        SELECT plan_items.*, 0 AS level FROM plan_items WHERE id = ?1
        UNION ALL
        SELECT pi.*, d.level + 1 FROM plan_items pi
        INNER JOIN descendants d ON pi.parent_id = d.id
      )
      SELECT * FROM descendants ORDER BY level ASC, created_at ASC
      ''',
      variables: <Variable<Object>>[Variable<String>(rootId)],
      readsFrom: <ResultSetImplementation<dynamic, dynamic>>{planItems},
    ).watch().map((List<QueryRow> rows) => rows.map((row) => planItems.map(row.data)).toList());
  }

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  Future<void> insertPlanItem(PlanItemsCompanion companion) {
    return into(planItems).insert(companion);
  }

  Future<void> insertPlanItems(List<PlanItemsCompanion> companions) {
    // batch() is one round-trip for many inserts.
    return batch((Batch b) => b.insertAll(planItems, companions));
  }

  Future<void> updatePlanItem(PlanItemsCompanion companion) {
    return (update(planItems)..where((tbl) => tbl.id.equals(companion.id.value)))
        .write(companion);
  }

  Future<void> updateScheduledForDay(String id, int? bucket) {
    return (update(planItems)..where((tbl) => tbl.id.equals(id))).write(
      PlanItemsCompanion(
        scheduledForDay: Value<int?>(bucket),
        updatedAt: Value<DateTime>(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> deletePlanItem(String id) {
    return (delete(planItems)..where((tbl) => tbl.id.equals(id))).go();
  }
}