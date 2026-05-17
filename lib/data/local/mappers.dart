import 'package:drift/drift.dart' show Value;

import '../../core/extensions/datetime_extensions.dart';
import '../../domain/enums/plan_item_state.dart';
import '../../domain/models/disposition_event.dart';
import '../../domain/models/intention.dart';
import '../../domain/models/item_time.dart';
import '../../domain/models/plan_item.dart';
import 'database.dart';
import 'tables/disposition_event_table.dart';
import 'tables/intentions_table.dart';
import 'tables/plan_items_table.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Intention <-> IntentionRow
// ─────────────────────────────────────────────────────────────────────────────

extension IntentionRowMapper on IntentionRow {
  /// Materialize this row as a domain [Intention].
  ///
  /// [planItemIds] is supplied separately by the repository — the row
  /// itself doesn't know which plan items it spawned (that's a query
  /// against [PlanItems]).
  Intention toDomain({List<String> planItemIds = const <String>[]}) {
    return Intention(
      id: id,
      userId: userId,
      rawText: rawText,
      capturedAt: capturedAt,
      source: source,
      parseStatus: parseStatus,
      planItemIds: planItemIds,
      parseError: parseError,
    );
  }
}

extension IntentionDomainMapper on Intention {
  /// Build an [IntentionsCompanion] for inserting this domain object.
  /// Used by [IntentionDao.insertIntention].
  IntentionsCompanion toCompanion({required DateTime now}) {
    return IntentionsCompanion.insert(
      id: id,
      userId: userId,
      rawText: rawText,
      capturedAt: capturedAt,
      source: source,
      parseStatus: Value(parseStatus),
      parseError: Value<String?>(parseError),
      createdAt: now,
      updatedAt: now,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PlanItem <-> PlanItemRow
// ─────────────────────────────────────────────────────────────────────────────

extension PlanItemRowMapper on PlanItemRow {
  /// Materialize this row as a domain [PlanItem] **without children**.
  /// Tree assembly is handled by the repository — see
  /// [PlanItemRepository.findById] with `includeChildren: true`.
  PlanItem toDomain({List<PlanItem> children = const <PlanItem>[]}) {
    return PlanItem(
      id: id,
      userId: userId,
      intentionId: intentionId,
      parentId: parentId,
      title: title,
      type: type,
      time: timeData,
      temperature: temperature,
      scored: scored,
      confidences: confidences,
      children: children,
      createdAt: createdAt,
      updatedAt: updatedAt,
      groupId: groupId,
    );
  }
}

extension PlanItemDomainMapper on PlanItem {
  /// Build a [PlanItemsCompanion] for inserting this domain object.
  /// The [scheduledForDay] column is materialized here from the [time]
  /// field — see [_computeScheduledForDay].
  PlanItemsCompanion toCompanion({required DateTime now}) {
    return PlanItemsCompanion.insert(
      id: id,
      userId: userId,
      intentionId: intentionId,
      title: title,
      type: type,
      timeData: time,
      temperature: temperature,
      createdAt: now,
      updatedAt: now,
      parentId: Value<String?>(parentId),
      scored: Value<bool>(scored),
      confidences: Value(confidences),
      scheduledForDay: Value<int?>(_computeScheduledForDay(time)),
      groupId: Value<String?>(groupId),
    );
  }
}

/// Computes the UTC day bucket for an [ItemTime], or null if the time
/// has no concrete day attached.
///
/// This is the projection that lets the day-view query be a simple
/// indexed `WHERE scheduled_for_day = ?` instead of an in-memory JSON
/// filter over every row.
int? _computeScheduledForDay(ItemTime time) {
  return time.when<int?>(
    hardTime: (DateTime at, _) => at.utcDayBucket,
    timeWindow: (DateTime? from, DateTime until) =>
    // The window's "scheduled day" is its close. The day view shows
    // items whose deadline is the target day; recommendations for
    // earlier days are derived by the UI from the same window.
    until.utcDayBucket,
    recurring: (String rrule, DateTime referenceTime, DateTime? until) =>
    // Recurring items are surfaced by the recurrence engine, not by
    // a single bucket. We leave the column null so they don't appear
    // in date-train queries by accident.
    null,
    untimed: () => null,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DispositionEvent <-> DispositionEventRow
// ─────────────────────────────────────────────────────────────────────────────

extension DispositionEventRowMapper on DispositionEventRow {
  DispositionEvent toDomain() {
    return DispositionEvent(
      id: id,
      planItemId: planItemId,
      priorState: priorState,
      newState: newState,
      prompted: prompted,
      occurredAt: occurredAt,
      rescheduledTo: rescheduledTo,
      note: note,
    );
  }
}

extension DispositionEventDomainMapper on DispositionEvent {
  DispositionEventsCompanion toCompanion() {
    return DispositionEventsCompanion.insert(
      id: id,
      planItemId: planItemId,
      priorState: priorState,
      newState: newState,
      prompted: prompted,
      occurredAt: occurredAt,
      rescheduledTo: Value<DateTime?>(rescheduledTo),
      note: Value<String?>(note),
    );
  }
}