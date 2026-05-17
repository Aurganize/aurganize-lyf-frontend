import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/models/confidence.dart';

/// Serializes the per-attribute confidence map to/from a JSON string column.
///
/// The map is `<String, Confidence>` — keys are field names like
/// `'type'`, `'time'`, `'parent'`, `'temperature'`. Confidence itself is
/// just a wrapped double, so the JSON payload is small. A typical map
/// after parsing has 3–5 entries; the JSON is ~80–120 bytes.
class ConfidencesConverter extends TypeConverter<Map<String, Confidence>, String> {
  const ConfidencesConverter();

  @override
  Map<String, Confidence> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const <String, Confidence>{};
    final Map<String, Object?> raw =
    jsonDecode(fromDb) as Map<String, Object?>;
    return raw.map<String, Confidence>(
          (String key, Object? value) => MapEntry<String, Confidence>(
        key,
        // Confidence.fromJson expects {'value': double}; the @freezed
        // generator emits exactly that shape.
        Confidence.fromJson(value! as Map<String, Object?>),
      ),
    );
  }

  @override
  String toSql(Map<String, Confidence> value) {
    if (value.isEmpty) return '{}';
    return jsonEncode(
      value.map<String, Object?>(
            (String key, Confidence c) => MapEntry<String, Object?>(key, c.toJson()),
      ),
    );
  }
}