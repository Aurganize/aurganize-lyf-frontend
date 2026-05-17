import 'package:drift/drift.dart';

import '../../../domain/enums/plan_item_type.dart';
import '../../../domain/enums/temperature.dart';
import '../converters/confidences_converter.dart';
import '../converters/item_time_converter.dart';
import 'intentions_table.dart';

/// Drift table for [PlanItem] entities — SRS §9.1.
///
/// Recursive: `parent_id` self-references `plan_items.id`. SQLite enforces
/// the foreign key when `PRAGMA foreign_keys = ON` is set (we do this in
/// the database opener).
///
/// `time_data` carries the full [ItemTime] sealed union as JSON via
/// [ItemTimeConverter]. We also materialize `scheduled_for_day` as a
/// nullable INTEGER (Unix-day count from epoch) at write time — this is
/// the column the day-view query filters by, and indexing it makes that
/// query O(log n) instead of O(n) with in-memory time-parsing.
///
/// `confidences` carries the per-attribute confidence map as JSON via
/// [ConfidencesConverter].
///
/// Indices:
///   - `idx_plan_items_user_parent` — for tree navigation per user.
///   - `idx_plan_items_scheduled_day` — for the today view and date train.
///   - `idx_plan_items_intention` — to walk back from an intention to
///     its produced plan items (rare, but used in the dismiss flow).
///   - `idx_plan_items_group` — group-plan items per group.
@DataClassName('PlanItemRow')
class PlanItems extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();

  TextColumn get intentionId => text()
      .named('intention_id')
      .references(Intentions, #id, onDelete: KeyAction.cascade)();

  TextColumn get parentId => text()
      .named('parent_id')
      .nullable()
      .references(
    PlanItems,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get title => text()();
  TextColumn get type => textEnum<PlanItemType>()();

  TextColumn get timeData =>
      text().named('time_data').map(const ItemTimeConverter())();

  TextColumn get temperature => textEnum<Temperature>()();

  BoolColumn get scored =>
      boolean().withDefault(const Constant<bool>(true))();

  TextColumn get confidences => text()
      .withDefault(const Constant<String>('{}'))
      .map(const ConfidencesConverter())();

  /// Materialized "what day is this scheduled for" column, populated at
  /// write time from [timeData]. The unit is **whole UTC days since the
  /// Unix epoch** — `DateTime.toUtc().millisecondsSinceEpoch ~/ 86400000`.
  /// Null for untimed items and items whose [ItemTime] has no concrete day.
  ///
  /// Why a separate column rather than computing this from `time_data`
  /// in SQL: SQLite cannot index JSON extracts cheaply, and the day view
  /// runs on every landing-screen build.
  IntColumn get scheduledForDay =>
      integer().named('scheduled_for_day').nullable()();

  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  TextColumn get groupId => text().named('group_id').nullable()();

  /// Whether the user has explicitly accepted this plan item.
  ///
  /// Parser-produced items default to `false`. The user flips this to
  /// `true` by tapping "Add to plan" on the confirmation peek or detail.
  /// User-created items (manually added via the project view, etc.) are
  /// inserted with `confirmed: true`.
  BoolColumn get confirmed =>
      boolean().withDefault(const Constant<bool>(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}