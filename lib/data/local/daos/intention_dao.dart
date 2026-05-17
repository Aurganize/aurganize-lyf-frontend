import 'package:drift/drift.dart';

import '../../../domain/enums/parse_status.dart';
import '../database.dart';
import '../tables/intentions_table.dart';
import '../tables/plan_items_table.dart';

part 'intention_dao.g.dart';

/// Data-access methods for the [Intentions] table.
///
/// Stateless — every method is a transaction-safe single query.
@DriftAccessor(tables: <Type>[Intentions, PlanItems])
class IntentionDao extends DatabaseAccessor<AurganizeDatabase>
    with _$IntentionDaoMixin {
  IntentionDao(super.db);

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  Future<IntentionRow?> findById(String id) {
    return (select(intentions)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Recent captures for a user, newest first, optionally limited.
  /// Backs the conversation panel's history view.
  Future<List<IntentionRow>> findRecentForUser(
      String userId, {
        int limit = 50,
      }) {
    return (select(intentions)
      ..where((tbl) => tbl.userId.equals(userId))
      ..orderBy(<OrderClauseGenerator<Intentions>>[
            (tbl) => OrderingTerm.desc(tbl.capturedAt),
      ])
      ..limit(limit))
        .get();
  }

  /// All intentions still awaiting parse. The parsing worker calls
  /// this on app start to recover anything stranded by a crash mid-parse.
  Future<List<IntentionRow>> findPending() {
    return (select(intentions)
      ..where((tbl) => tbl.parseStatus.isIn(<String>[
        ParseStatus.pending.name,
        ParseStatus.inProgress.name,
      ])))
        .get();
  }

  /// Stream of pending intentions. Used by the in-app parsing pipeline
  /// to know when new work has been queued.
  Stream<List<IntentionRow>> watchPending() {
    return (select(intentions)
      ..where((tbl) => tbl.parseStatus.equals(ParseStatus.pending.name))
      ..orderBy(<OrderClauseGenerator<Intentions>>[
            (tbl) => OrderingTerm.asc(tbl.capturedAt),
      ]))
        .watch();
  }

  /// Returns the IDs of plan items spawned by [intentionId]. Used by
  /// the repository to fill [Intention.planItemIds].
  Future<List<String>> findPlanItemIdsForIntention(String intentionId) async {
    final List<PlanItemRow> rows = await (select(planItems)
      ..where((tbl) => tbl.intentionId.equals(intentionId)))
        .get();
    return rows.map((PlanItemRow r) => r.id).toList();
  }

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  Future<void> insertIntention(IntentionsCompanion companion) {
    return into(intentions).insert(companion);
  }

  /// Atomically moves an intention from [ParseStatus.pending] to
  /// [ParseStatus.inProgress]. Returns true if a row actually moved
  /// (false means another worker already claimed it).
  ///
  /// Implements an optimistic lock via the `WHERE parse_status = pending`
  /// clause — `update().write()` returns the count of affected rows.
  Future<bool> claimForParsing(String id, {required DateTime now}) async {
    final int affected = await (update(intentions)
      ..where((tbl) =>
      tbl.id.equals(id) &
      tbl.parseStatus.equals(ParseStatus.pending.name)))
        .write(IntentionsCompanion(
      parseStatus: const Value<ParseStatus>(ParseStatus.inProgress),
      updatedAt: Value<DateTime>(now),
    ));
    return affected > 0;
  }

  Future<void> markParsed(String id, {required DateTime now}) {
    return (update(intentions)..where((tbl) => tbl.id.equals(id))).write(
      IntentionsCompanion(
        parseStatus: const Value<ParseStatus>(ParseStatus.parsed),
        parseError: const Value<String?>(null),
        updatedAt: Value<DateTime>(now),
      ),
    );
  }

  Future<void> markFailed(
      String id, {
        required String error,
        required DateTime now,
      }) {
    return (update(intentions)..where((tbl) => tbl.id.equals(id))).write(
      IntentionsCompanion(
        parseStatus: const Value<ParseStatus>(ParseStatus.failed),
        parseError: Value<String?>(error),
        updatedAt: Value<DateTime>(now),
      ),
    );
  }

  Future<void> markDismissed(String id, {required DateTime now}) {
    return (update(intentions)..where((tbl) => tbl.id.equals(id))).write(
      IntentionsCompanion(
        parseStatus: const Value<ParseStatus>(ParseStatus.dismissed),
        updatedAt: Value<DateTime>(now),
      ),
    );
  }

  /// Permanently delete an intention (and, via FK cascade, any plan
  /// items it spawned and their disposition events). Used only by the
  /// Settings → "delete my data" flow.
  Future<void> deleteForever(String id) {
    return (delete(intentions)..where((tbl) => tbl.id.equals(id))).go();
  }
}