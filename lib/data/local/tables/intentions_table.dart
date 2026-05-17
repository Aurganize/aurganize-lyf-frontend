import 'package:drift/drift.dart';

import '../../../domain/enums/capture_source.dart';
import '../../../domain/enums/parse_status.dart';

/// Drift table for [Intention] entities — SRS §9.1.
///
/// Schema notes:
///   - `id` is a client-generated UUIDv4 stored as TEXT.
///   - `captured_at` is the device clock at capture, stored as Unix
///     millisecond epoch via Drift's built-in [DateTime] handling.
///   - `parse_status` is the [ParseStatus] enum stored as `.name`
///     ("pending", "parsed", etc.) — Drift's `textEnum<E>()` helper.
///   - `parse_error` is null unless `parse_status == failed`.
///
/// Indices:
///   - `idx_intentions_user_captured` — user-scoped, time-descending.
///     This is the index that backs "show me my recent captures".
///   - `idx_intentions_parse_status` — for the parsing worker to find
///     pending intentions on app start (recover from a crash mid-parse).
@DataClassName('IntentionRow')
class Intentions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get rawText => text().named('raw_text')();
  DateTimeColumn get capturedAt => dateTime().named('captured_at')();
  TextColumn get source => textEnum<CaptureSource>()();
  TextColumn get parseStatus =>
      textEnum<ParseStatus>().named('parse_status').withDefault(
        Constant<String>(ParseStatus.pending.name),
      )();
  TextColumn get parseError => text().named('parse_error').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};

// The `String` type parameter on the indexes below is not "the index
// returns strings" — it's the type that Drift's generated wrapper uses
// internally for raw SQL. The string is the actual CREATE INDEX statement.
}