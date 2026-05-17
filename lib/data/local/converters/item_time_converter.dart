import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/models/item_time.dart';

/// Serializes the sealed [ItemTime] union to/from a JSON string column.
///
/// We choose JSON over a discriminator-plus-columns layout (a `type` column
/// + nullable `at`, `from`, `until`, `rrule`, ...) because:
///
///   1. The variants have non-overlapping fields. Spreading them across
///      columns would create many nullable columns whose validity rules
///      live in app code rather than the schema — exactly the bug-shaped
///      hole a relational schema is meant to close.
///   2. We rarely query ON the inner fields. The only query that filters
///      by an inner time value is "scheduled for date D", and we materialize
///      that via a separate computed column at write time (see
///      [PlanItems.scheduledForDay]). The rest of the time, ItemTime is
///      a property read into memory, not a filter.
///   3. RFC 5545 RRULE strings are themselves opaque blobs to SQLite;
///      storing them in a TEXT column is no worse than storing the whole
///      ItemTime in JSON.
///
/// **Round-trip is exact** because [ItemTime] is `@freezed` with
/// `fromJson` / `toJson` — we delegate serialization to the generated code.
class ItemTimeConverter extends TypeConverter<ItemTime, String>
    with JsonTypeConverter2<ItemTime, String, Map<String, Object?>> {
  const ItemTimeConverter();

  @override
  ItemTime fromSql(String fromDb) {
    final Map<String, Object?> json =
    jsonDecode(fromDb) as Map<String, Object?>;
    return ItemTime.fromJson(json);
  }

  @override
  String toSql(ItemTime value) => jsonEncode(value.toJson());

  // JsonTypeConverter2 mixin lets Drift use this in queries that
  // return JSON directly (we don't currently, but it costs nothing).
  @override
  ItemTime fromJson(Map<String, Object?> json) => ItemTime.fromJson(json);

  @override
  Map<String, Object?> toJson(ItemTime value) => value.toJson();
}