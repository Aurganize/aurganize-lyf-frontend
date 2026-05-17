import 'package:drift/drift.dart';

import '../../../domain/enums/plan_item_state.dart';
import 'plan_items_table.dart';

/// Drift table for [DispositionEvent] entities — SRS FR-4.6.
///
/// **Append-only.** We never UPDATE or DELETE rows here in normal flow.
/// The Dao exposes only insert and read methods (Part 03).
///
/// Indices:
///   - `idx_disposition_events_item_time` — to fetch a plan item's history
///     ordered by time, and to read the latest disposition for "current
///     state" derivation. The (plan_item_id, occurred_at DESC) shape is
///     exactly what `currentStateFor` queries.
@DataClassName('DispositionEventRow')
class DispositionEvents extends Table {
  TextColumn get id => text()();

  TextColumn get planItemId => text()
      .named('plan_item_id')
      .references(PlanItems, #id, onDelete: KeyAction.cascade)();

  TextColumn get priorState =>
      textEnum<PlanItemState>().named('prior_state')();

  TextColumn get newState => textEnum<PlanItemState>().named('new_state')();

  BoolColumn get prompted => boolean()();

  DateTimeColumn get occurredAt => dateTime().named('occurred_at')();

  DateTimeColumn get rescheduledTo =>
      dateTime().named('rescheduled_to').nullable()();

  TextColumn get note => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}