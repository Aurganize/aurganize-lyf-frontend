import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';

/// Single-instance provider for the app-wide [AurganizeDatabase].
///
/// Lifecycle: opened on first read, closed automatically when the
/// [ProviderScope] disposes (i.e. app shutdown). Tests can override
/// this with `forTesting` constructors.
final Provider<AurganizeDatabase> databaseProvider =
Provider<AurganizeDatabase>((Ref ref) {
  final AurganizeDatabase db = AurganizeDatabase();
  ref.onDispose(db.close);
  return db;
});