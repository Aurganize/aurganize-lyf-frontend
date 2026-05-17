import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'tables/disposition_event_table.dart';
import 'tables/intentions_table.dart';
import 'tables/plan_items_table.dart';

import 'daos/disposition_event_dao.dart';
import 'daos/intention_dao.dart';
import 'daos/plan_item_dao.dart';

import 'package:aurganize_lyf/domain/enums/capture_source.dart';
import 'package:aurganize_lyf/domain/enums/parse_status.dart';
import 'package:aurganize_lyf/domain/enums/plan_item_type.dart';
import 'package:aurganize_lyf/domain/enums/plan_item_state.dart';
import 'package:aurganize_lyf/domain/enums/temperature.dart';

import 'package:aurganize_lyf/domain/models/confidence.dart';
import 'package:aurganize_lyf/domain/models/item_time.dart';
import 'package:aurganize_lyf/domain/models/disposition_event.dart';
import 'package:aurganize_lyf/domain/models/intention.dart';
import 'package:aurganize_lyf/domain/models/plan_item.dart';
import 'package:aurganize_lyf/domain/models/disposition_event.dart';

import 'package:aurganize_lyf/data/local/converters/confidences_converter.dart';
import 'package:aurganize_lyf/data/local/converters/item_time_converter.dart';

part 'database.g.dart';

/// The root Drift database for Aurganize lyf.
///
/// Tables: [Intentions], [PlanItems], [DispositionEvents].
///
/// Schema version: 1.
///
/// To bump the schema in a future release: add tables / columns,
/// increment [schemaVersion], add a branch in [_migration] to handle
/// the upgrade. Generated migrations via `drift_dev schema dump` and
/// `drift_dev schema generate` are preferred over hand-written ALTERs
/// for non-trivial changes.
@DriftDatabase(
  tables: <Type>[
    Intentions,
    PlanItems,
    DispositionEvents,
  ],
  daos: <Type>[
    IntentionDao,
    PlanItemDao,
    DispositionEventDao,
  ],
)
class AurganizeDatabase extends _$AurganizeDatabase {
  AurganizeDatabase() : super(_openConnection());

  /// Constructor used by tests — accepts a [QueryExecutor] (typically
  /// an in-memory NativeDatabase) so tests don't touch the file system.
  AurganizeDatabase.forTesting(super.e);

  final Provider<AurganizeDatabase> databaseProvider =
  Provider<AurganizeDatabase>(
        (Ref ref) {
      final AurganizeDatabase db = AurganizeDatabase();
      ref.onDispose(db.close);
      return db;
    },
    name: 'database',
  );


  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _createIndices(m);
    },
    beforeOpen: (OpeningDetails details) async {
      // SQLite ships with foreign keys disabled by default. Enable them
      // every connection — otherwise our `.references()` cascade
      // declarations are nothing more than documentation.
      await customStatement('PRAGMA foreign_keys = ON');

      // Enable WAL mode for better concurrency between the UI thread
      // and the (eventual) sync worker isolate. Persisted across runs.
      await customStatement('PRAGMA journal_mode = WAL');

      // Strict typing — SQLite would otherwise tolerate string-in-int
      // columns. Our type converters already enforce shape, but defense
      // in depth costs nothing here.
      await customStatement('PRAGMA strict = ON').catchError((_) {
        // PRAGMA strict requires SQLite 3.37+; older versions on
        // legacy Android devices may reject it. Swallow the error —
        // strict is an enhancement, not a correctness requirement.
      });
    },
    // For v1 there is no upgrade path. Add `from: ...` branches here
    // in v2+ releases.
  );

  Future<void> _createIndices(Migrator m) async {
    // Order matters: indices are created after tables. We bundle them
    // here so a single onCreate covers schema + indices atomically.
    await customStatement('''
      CREATE INDEX idx_intentions_user_captured
        ON intentions(user_id, captured_at DESC)
    ''');
    await customStatement('''
      CREATE INDEX idx_intentions_parse_status
        ON intentions(parse_status)
        WHERE parse_status IN ('pending', 'inProgress')
    ''');
    await customStatement('''
      CREATE INDEX idx_plan_items_user_parent
        ON plan_items(user_id, parent_id)
    ''');
    await customStatement('''
      CREATE INDEX idx_plan_items_scheduled_day
        ON plan_items(user_id, scheduled_for_day)
        WHERE scheduled_for_day IS NOT NULL
    ''');
    await customStatement('''
      CREATE INDEX idx_plan_items_intention
        ON plan_items(intention_id)
    ''');
    await customStatement('''
      CREATE INDEX idx_plan_items_group
        ON plan_items(group_id)
        WHERE group_id IS NOT NULL
    ''');
    await customStatement('''
      CREATE INDEX idx_disposition_events_item_time
        ON disposition_events(plan_item_id, occurred_at DESC)
    ''');
  }

  // -------------------------------------------------------------------------
  // Debug helpers
  // -------------------------------------------------------------------------

  /// **Test helper.** Wipes every row in every table. Not exposed in
  /// prod UI; used by Settings → "delete my data" via a separate
  /// confirmed path.
  Future<void> wipeForTests() async {
    await transaction(() async {
      await delete(dispositionEvents).go();
      await delete(planItems).go();
      await delete(intentions).go();
    });
  }
}

/// Opens the production database file.
///
/// On iOS and Android we store the file in the app's documents directory
/// (`path_provider`'s `getApplicationDocumentsDirectory`). It is excluded
/// from cloud backup on iOS by default — we don't want a parsed plan
/// state syncing through iCloud independently of our own sync.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // sqlite3_flutter_libs ships the native library; this call wires it.
    if (Platform.isIOS || Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final Directory dbDir = await getApplicationDocumentsDirectory();
    final File dbFile = File(p.join(dbDir.path, 'aurganize_lyf.sqlite'));

    // Some older iOS versions return a directory path without a trailing
    // slash, and Drift expects an existing parent. Belt-and-braces:
    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
    }

    // The temporary directory has different semantics on iOS for the
    // SQLite working files. Setting it explicitly avoids subtle
    // permission errors.
    final String cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(
      dbFile,
      logStatements: false, // flip to true in dev to spy on SQL
    );
  });
}