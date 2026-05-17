import '../../domain/models/intention.dart';
import '../../domain/repositories/intention_repository.dart';
import '../local/daos/intention_dao.dart';
import '../local/database.dart';
import '../local/mappers.dart';
import '../local/tables/intentions_table.dart';

class DriftIntentionRepository implements IntentionRepository {
  DriftIntentionRepository(this._dao);

  final IntentionDao _dao;

  @override
  Future<Intention> create(Intention intention) async {
    final DateTime now = DateTime.now().toUtc();
    await _dao.insertIntention(intention.toCompanion(now: now));
    return intention;
  }

  @override
  Future<Intention?> findById(String id) async {
    final IntentionRow? row = await _dao.findById(id);
    if (row == null) return null;
    final List<String> planItemIds =
    await _dao.findPlanItemIdsForIntention(id);
    return row.toDomain(planItemIds: planItemIds);
  }

  @override
  Future<List<Intention>> findRecentForUser(
      String userId, {
        int limit = 50,
      }) async {
    final List<IntentionRow> rows =
    await _dao.findRecentForUser(userId, limit: limit);
    // For the recent-list we don't need plan-item ids; the conversation
    // panel doesn't render them. Keep the cheap shape.
    return rows
        .map((IntentionRow r) => r.toDomain())
        .toList(growable: false);
  }

  @override
  Stream<List<Intention>> watchPending() {
    return _dao.watchPending().map(
          (List<IntentionRow> rows) =>
          rows.map((IntentionRow r) => r.toDomain()).toList(growable: false),
    );
  }

  @override
  Future<bool> claimForParsing(String id) {
    return _dao.claimForParsing(id, now: DateTime.now().toUtc());
  }

  @override
  Future<void> markParsed(String id) {
    return _dao.markParsed(id, now: DateTime.now().toUtc());
  }

  @override
  Future<void> markFailed(String id, {required String error}) {
    return _dao.markFailed(id, error: error, now: DateTime.now().toUtc());
  }

  @override
  Future<void> markDismissed(String id) {
    return _dao.markDismissed(id, now: DateTime.now().toUtc());
  }

  @override
  Future<void> deleteForever(String id) => _dao.deleteForever(id);

  @override
  Stream<List<Intention>> watchRecentForUser(String userId, {int limit = 50}) {
    return _dao
        .watchRecentForUser(userId, limit: limit)
        .map<List<Intention>>(
          (rows) => rows.map((r) => r.toDomain()).toList(growable: false),
    );
  }
}