import 'package:drift/drift.dart';

import '../../../domain/enums/plan_item_state.dart';
import '../database.dart';
import '../tables/disposition_event_table.dart';

part 'disposition_event_dao.g.dart';

/// Data-access methods for the append-only disposition events log.
///
/// **Append-only.** No update or delete methods are exposed. The
/// repository uses these methods exclusively.
@DriftAccessor(tables: <Type>[DispositionEvents])
class DispositionEventDao extends DatabaseAccessor<AurganizeDatabase>
    with _$DispositionEventDaoMixin {
  DispositionEventDao(super.db);

  Future<void> append(DispositionEventsCompanion companion) {
    return into(dispositionEvents).insert(companion);
  }

  /// Full event history for a plan item, newest first.
  Future<List<DispositionEventRow>> history(String planItemId) {
    return (select(dispositionEvents)
      ..where((tbl) => tbl.planItemId.equals(planItemId))
      ..orderBy(<OrderClauseGenerator<DispositionEvents>>[
            (tbl) => OrderingTerm.desc(tbl.occurredAt),
      ]))
        .get();
  }

  Stream<List<DispositionEventRow>> watchHistory(String planItemId) {
    return (select(dispositionEvents)
      ..where((tbl) => tbl.planItemId.equals(planItemId))
      ..orderBy(<OrderClauseGenerator<DispositionEvents>>[
            (tbl) => OrderingTerm.desc(tbl.occurredAt),
      ]))
        .watch();
  }

  /// The most recent disposition event for [planItemId], or null if the
  /// plan item has never been dispositioned. Used to derive current
  /// state — SRS FR-4.7.
  Future<DispositionEventRow?> latestFor(String planItemId) {
    return (select(dispositionEvents)
      ..where((tbl) => tbl.planItemId.equals(planItemId))
      ..orderBy(<OrderClauseGenerator<DispositionEvents>>[
            (tbl) => OrderingTerm.desc(tbl.occurredAt),
      ])
      ..limit(1))
        .getSingleOrNull();
  }

  /// Per-day counts of "engagement events" — dispositions made during
  /// the given UTC day bucket, prompted or proactive. Used by the
  /// gamification engine in Phase 10.
  Future<int> countEventsOnDay({
    required int dayBucket,
    required String userId,
  }) async {
    final List<QueryRow> rows = await customSelect(
      r'''
      SELECT COUNT(*) AS n
      FROM disposition_events de
      INNER JOIN plan_items pi ON pi.id = de.plan_item_id
      WHERE pi.user_id = ?1
        AND CAST((CAST(strftime('%s', de.occurred_at / 1000, 'unixepoch') AS INTEGER) / 86400) AS INTEGER) = ?2
      ''',
      variables: <Variable<Object>>[
        Variable<String>(userId),
        Variable<int>(dayBucket),
      ],
      readsFrom: <ResultSetImplementation<dynamic, dynamic>>{dispositionEvents},
    ).get();
    return rows.isEmpty ? 0 : rows.first.read<int>('n');
  }
}