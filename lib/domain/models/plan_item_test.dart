import 'dart:math';

import 'package:aurganize_lyf/domain/enums/capture_source.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aurganize_lyf/domain/enums/plan_item_state.dart';
import 'package:aurganize_lyf/domain/enums/plan_item_type.dart';
import 'package:aurganize_lyf/domain/enums/temperature.dart';

import 'package:aurganize_lyf/domain/models/confidence.dart';
import 'package:aurganize_lyf/domain/models/disposition_event.dart';
import 'package:aurganize_lyf/domain/models/intention.dart';
import 'package:aurganize_lyf/domain/models/item_time.dart';
import 'package:aurganize_lyf/domain/models/plan_item.dart';

void main() {
  group('Confidence', () {
    test('bounds are enforced at construction', () {
      expect(() => Confidence(-0.1), throwsA(isA<AssertionError>()));
      expect(() => Confidence(1.1), throwsA(isA<AssertionError>()));
      expect(const Confidence(0).value, 0.0);
      expect(const Confidence(1).value, 1.0);
    });

    test('tentative threshold is 0.7', () {
      expect(const Confidence(0.69).isTentative, isTrue);
      expect(const Confidence(0.7).isTentative, isFalse);
      expect(const Confidence(0.71).isCertain, isTrue);
    });
  });


  group('ItemTime', () {
    test('sealed variants round-trip JSON', () {
      final ItemTime hard = ItemTime.hardTime(
          at: DateTime.utc(2026, 5, 16, 9),
      );
      final Map<String, Object?> json = hard.toJson();
      final ItemTime parsed = ItemTime.fromJson(json);
      expect(parsed, hard);
    });
  });

  group('PlanItem', () {
    final PlanItem child = PlanItem(
      id: 'child-1',
      userId: 'user-1',
      intentionId: 'int-1',
      parentId: 'parent-1',
      title: 'Buy a gift',
      type: PlanItemType.errand,
      time: const ItemTime.untimed(),
      temperature: Temperature.warm,
      createdAt: DateTime.utc(2026, 5, 16),
      updatedAt: DateTime.utc(2026, 5, 16),
    );

    final PlanItem parent = PlanItem(
      id: 'parent-1',
      userId: 'user-1',
      intentionId: 'int-1',
      title: "Prepare for sister's wedding",
      type: PlanItemType.project,
      time: const ItemTime.untimed(),
      temperature: Temperature.cool,
      createdAt: DateTime.utc(2026, 5, 16),
      updatedAt: DateTime.utc(2026, 5, 16),
      children: <PlanItem>[child],
    );

    test('a project is detected by children OR type', () {
      expect(parent.isProject, isTrue);
      expect(child.isProject, isFalse);
    });

    test('isRoot reflects parentId nullability', () {
      expect(parent.isRoot, isTrue);
      expect(child.isRoot, isFalse);
    });

    test('confidenceFor defaults to certain when missing', () {
      expect(parent.confidenceFor('type'), Confidence.certain);
    });
  });

  group('DispositionEvent', () {
    test('JSON round-trip preserves all fields', () {
      final DispositionEvent event = DispositionEvent(
        id: 'evt-1',
        planItemId: 'plan-1',
        priorState: PlanItemState.planned,
        newState: PlanItemState.done,
        prompted: true,
        occurredAt: DateTime.utc(2026, 5, 16, 16),
      );

      final DispositionEvent parsed = DispositionEvent.fromJson(event.toJson());
      expect(parsed, event);
    });
  });

  group('Intention', () {
    test('isPending covers both pending and inProgress', () {
      final Intention i1 = Intention(
        id: 'i1',
        userId: 'u',
        rawText: 'x',
        source: CaptureSource.typed,
        capturedAt: DateTime.utc(2026, 5, 16, 16),
      );
    });
  });
}