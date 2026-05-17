import 'package:aurganize_lyf/data/local/tables/disposition_event_table.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aurganize_lyf/data/local/database.dart';
import 'package:aurganize_lyf/domain/enums/capture_source.dart';
import 'package:aurganize_lyf/domain/enums/parse_status.dart';
import 'package:aurganize_lyf/domain/enums/plan_item_state.dart';
import 'package:aurganize_lyf/domain/enums/plan_item_type.dart';
import 'package:aurganize_lyf/domain/enums/temperature.dart';
import 'package:aurganize_lyf/domain/models/confidence.dart';
import 'package:aurganize_lyf/domain/models/item_time.dart';

void main() {
  late AurganizeDatabase db;

  setUp(() {
    db = AurganizeDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('intentions table', () {
    test('insert and read back', () async {
      final DateTime now = DateTime.now().toUtc();
      await db.into(db.intentions).insert(
        IntentionsCompanion.insert(
          id: 'i-1',
          userId: 'u-1',
          rawText: 'call the dentist',
          capturedAt: now,
          source: CaptureSource.typed,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final IntentionRow row =
      await (db.select(db.intentions)..where((tbl) => tbl.id.equals('i-1')))
          .getSingle();

      expect(row.id, 'i-1');
      expect(row.rawText, 'call the dentist');
      expect(row.source, CaptureSource.typed);
      expect(row.parseStatus, ParseStatus.pending);
      expect(row.parseError, isNull);
    });

    test('parse_status enum round-trips through .name', () async {
      final DateTime now = DateTime.now().toUtc();
      await db.into(db.intentions).insert(
        IntentionsCompanion.insert(
          id: 'i-2',
          userId: 'u-1',
          rawText: 'x',
          capturedAt: now,
          source: CaptureSource.voice,
          parseStatus: const Value<ParseStatus>(ParseStatus.parsed),
          createdAt: now,
          updatedAt: now,
        ),
      );
      final IntentionRow row =
      await (db.select(db.intentions)..where((tbl) => tbl.id.equals('i-2')))
          .getSingle();
      expect(row.parseStatus, ParseStatus.parsed);
    });
  });

  group('plan_items table', () {
    Future<void> _seedIntention(String id) async {
      final DateTime now = DateTime.now().toUtc();
      await db.into(db.intentions).insert(
        IntentionsCompanion.insert(
          id: id,
          userId: 'u-1',
          rawText: 'src',
          capturedAt: now,
          source: CaptureSource.typed,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    test('ItemTime sealed union round-trips through the converter', () async {
      await _seedIntention('intent-time');
      final DateTime now = DateTime.now().toUtc();
      final ItemTime hard = ItemTime.hardTime(
        at: DateTime.utc(2026, 5, 16, 9),
        duration: const Duration(minutes: 30),
      );

      await db.into(db.planItems).insert(
        PlanItemsCompanion.insert(
          id: 'p-1',
          userId: 'u-1',
          intentionId: 'intent-time',
          title: 'BP medication',
          type: PlanItemType.medication,
          timeData: hard,
          temperature: Temperature.hot,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final PlanItemRow row = await (db.select(db.planItems)
        ..where((tbl) => tbl.id.equals('p-1')))
          .getSingle();
      expect(row.timeData, hard);
    });

    test('confidences map round-trips', () async {
      await _seedIntention('intent-conf');
      final DateTime now = DateTime.now().toUtc();
      final Map<String, Confidence> confidences = <String, Confidence>{
        'type': const Confidence(0.95),
        'time': const Confidence(0.6),
        'parent': Confidence.certain,
      };

      await db.into(db.planItems).insert(
        PlanItemsCompanion.insert(
          id: 'p-2',
          userId: 'u-1',
          intentionId: 'intent-conf',
          title: 'x',
          type: PlanItemType.task,
          timeData: const ItemTime.untimed(),
          temperature: Temperature.cool,
          createdAt: now,
          updatedAt: now,
          confidences: Value<Map<String, Confidence>>(confidences),
        ),
      );

      final PlanItemRow row = await (db.select(db.planItems)
        ..where((tbl) => tbl.id.equals('p-2')))
          .getSingle();
      expect(row.confidences['type']?.value, 0.95);
      expect(row.confidences['time']?.isTentative, isTrue);
      expect(row.confidences['parent'], Confidence.certain);
    });

    test('self-referencing parent_id enforces FK', () async {
      await _seedIntention('intent-fk');
      final DateTime now = DateTime.now().toUtc();

      // Inserting a child with a parent that doesn't exist should fail.
      Future<void> insertOrphan() {
        return db.into(db.planItems).insert(
          PlanItemsCompanion.insert(
            id: 'orphan',
            userId: 'u-1',
            intentionId: 'intent-fk',
            title: 'orphan',
            type: PlanItemType.task,
            timeData: const ItemTime.untimed(),
            temperature: Temperature.cool,
            createdAt: now,
            updatedAt: now,
            parentId: const Value<String?>('does-not-exist'),
          ),
        );
      }

      await expectLater(insertOrphan(), throwsA(isA<Exception>()));
    });

    test('cascade delete: deleting an intention removes its plan items',
            () async {
          await _seedIntention('intent-cascade');
          final DateTime now = DateTime.now().toUtc();
          await db.into(db.planItems).insert(
            PlanItemsCompanion.insert(
              id: 'p-cascade',
              userId: 'u-1',
              intentionId: 'intent-cascade',
              title: 'x',
              type: PlanItemType.task,
              timeData: const ItemTime.untimed(),
              temperature: Temperature.cool,
              createdAt: now,
              updatedAt: now,
            ),
          );

          await (db.delete(db.intentions)
            ..where((tbl) => tbl.id.equals('intent-cascade')))
              .go();

          final List<PlanItemRow> rows =
          await (db.select(db.planItems)..where((tbl) => tbl.id.equals('p-cascade')))
              .get();
          expect(rows, isEmpty);
        });
  });

  group('disposition_events table', () {
    test('append-only history is preserved by occurred_at', () async {
      final DateTime now = DateTime.now().toUtc();
      await db.into(db.intentions).insert(
        IntentionsCompanion.insert(
          id: 'i', userId: 'u', rawText: 'x',
          capturedAt: now, source: CaptureSource.typed,
          createdAt: now, updatedAt: now,
        ),
      );
      await db.into(db.planItems).insert(
        PlanItemsCompanion.insert(
          id: 'p', userId: 'u', intentionId: 'i', title: 'x',
          type: PlanItemType.task, timeData: const ItemTime.untimed(),
          temperature: Temperature.cool, createdAt: now, updatedAt: now,
        ),
      );

      for (int i = 0; i < 3; i++) {
        await db.into(db.dispositionEvents).insert(
          DispositionEventsCompanion.insert(
            id: 'evt-$i',
            planItemId: 'p',
            priorState: PlanItemState.planned,
            newState: i == 2
                ? PlanItemState.done
                : PlanItemState.inProgress,
            prompted: true,
            occurredAt: now.add(Duration(minutes: i)),
          ),
        );
      }

      final List<DispositionEventRow> ordered =
      await (db.select(db.dispositionEvents)
        ..where((tbl) => tbl.planItemId.equals('p'))
        ..orderBy(<OrderClauseGenerator<DispositionEvents>>[
              (tbl) => OrderingTerm.desc(tbl.occurredAt),
        ]))
          .get();

      expect(ordered.length, 3);
      expect(ordered.first.newState, PlanItemState.done);
    });
  });
}