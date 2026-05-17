import '../models/intention.dart';

/// Operations the rest of the app performs on intentions.
///
/// All implementations are required to:
///   - Preserve the raw text permanently (SRS FR-1.3).
///   - Persist a capture before any parsing runs (SRS FR-1.2).
///   - Treat the entity as effectively immutable from the user's
///     perspective; only `parseStatus` transitions are allowed.
abstract interface class IntentionRepository {
  /// Stores a new intention. Returns the stored entity (which equals
  /// the input — we do not auto-generate IDs server-side at this layer).
  Future<Intention> create(Intention intention);

  Future<Intention?> findById(String id);

  Future<List<Intention>> findRecentForUser(String userId, {int limit = 50});

  /// Stream of pending intentions. Used by the parsing worker.
  Stream<List<Intention>> watchPending();

  /// Atomically claim an intention for parsing. Returns true if this
  /// caller won the race; false if another worker already claimed it.
  Future<bool> claimForParsing(String id);

  Future<void> markParsed(String id);

  Future<void> markFailed(String id, {required String error});

  Future<void> markDismissed(String id);

  /// Hard-deletes the intention and (via FK cascade) every plan item
  /// and disposition event derived from it. Reserved for Settings →
  /// "delete my data".
  Future<void> deleteForever(String id);
}