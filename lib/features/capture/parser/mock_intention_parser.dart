import 'package:uuid/uuid.dart';

import '../../../domain/enums/plan_item_type.dart';
import '../../../domain/enums/temperature.dart';
import '../../../domain/models/confidence.dart';
import '../../../domain/models/item_time.dart';
import '../../../domain/models/plan_item.dart';
import 'intention_parser.dart';

/// Heuristic, deterministic parser used in development and tests.
///
/// **Not** intended to be smart. Its job is to exercise every code path
/// in the UI (tentative chips, multi-card splits, all temperatures, all
/// types) with predictable output. Phase 21 replaces it with a remote
/// LLM-backed implementation.
class MockIntentionParser implements IntentionParser {
  MockIntentionParser({Uuid? uuid, DateTime Function()? clock})
      : _uuid = uuid ?? const Uuid(),
        _clock = clock ?? DateTime.now;

  final Uuid _uuid;
  final DateTime Function() _clock;

  // Splits on the strongest signals first, weakest last.
  static final RegExp _splitPattern =
  RegExp(r'\s*,\s+(?:and\s+|also\s+|then\s+)|\s+and\s+(?:then\s+)?|\s+;\s+');

  @override
  Future<List<PlanItem>> parse({
    required String userId,
    required String intentionId,
    required String rawText,
  }) async {
    // A small artificial delay simulates server-side parsing. Keeping
    // it under 1s lets developers feel the real cadence without being
    // tedious.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final List<String> chunks = _splitInto(rawText);
    final DateTime now = _clock();

    return chunks.map<PlanItem>((String chunk) {
      return _parseSingle(
        chunk: chunk,
        userId: userId,
        intentionId: intentionId,
        now: now,
      );
    }).toList(growable: false);
  }

  // ── Splitting ──────────────────────────────────────────────────────────────

  List<String> _splitInto(String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return <String>[trimmed];
    final List<String> raw = trimmed.split(_splitPattern);
    return raw
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList(growable: false);
  }

  // ── Per-chunk parsing ──────────────────────────────────────────────────────

  PlanItem _parseSingle({
    required String chunk,
    required String userId,
    required String intentionId,
    required DateTime now,
  }) {
    final String lower = chunk.toLowerCase();
    final (PlanItemType type, double typeConfidence) = _inferType(lower);
    final (ItemTime time, double timeConfidence) = _inferTime(lower, now);
    final Temperature temperature = _inferTemperature(type, time);
    final double temperatureConfidence = 0.78;

    return PlanItem(
      id: _uuid.v4(),
      userId: userId,
      intentionId: intentionId,
      title: _normalizeTitle(chunk),
      type: type,
      time: time,
      temperature: temperature,
      confidences: <String, Confidence>{
        'type': Confidence(typeConfidence),
        'time': Confidence(timeConfidence),
        'temperature': Confidence(temperatureConfidence),
      },
      createdAt: now,
      updatedAt: now,
    );
  }

  String _normalizeTitle(String chunk) {
    // Strip leading "I should ", "I need to ", "remind me to ", etc.
    final String stripped = chunk.replaceFirst(
      RegExp(
        r'^\s*(i\s+should|i\s+need\s+to|i\s+must|remind\s+me\s+to|i\s+want\s+to)\s+',
        caseSensitive: false,
      ),
      '',
    );
    // Capitalize first letter of remaining.
    if (stripped.isEmpty) return chunk;
    return stripped[0].toUpperCase() + stripped.substring(1);
  }

  // ── Type ───────────────────────────────────────────────────────────────────

  (PlanItemType, double) _inferType(String lower) {
    if (RegExp(r'\b(call|phone|ring|dial)\b').hasMatch(lower)) {
      return (PlanItemType.call, 0.92);
    }
    if (RegExp(r'\b(pick\s*up|buy|grab|fetch|drop\s*off)\b').hasMatch(lower)) {
      return (PlanItemType.errand, 0.9);
    }
    if (RegExp(r'\b(take|swallow|dose)\b').hasMatch(lower) &&
        RegExp(r'\b(medication|meds|pill|vitamin|bp)\b').hasMatch(lower)) {
      return (PlanItemType.medication, 0.96);
    }
    if (RegExp(r'\b(appointment|meeting|consult|dentist|doctor|haircut)\b')
        .hasMatch(lower)) {
      return (PlanItemType.appointment, 0.88);
    }
    if (RegExp(r'\b(prepare|plan|organize|wedding|launch|project|build)\b')
        .hasMatch(lower)) {
      return (PlanItemType.project, 0.84);
    }
    if (RegExp(r'\b(think\s+about|consider|reflect)\b').hasMatch(lower)) {
      return (PlanItemType.note, 0.7);
    }
    return (PlanItemType.task, 0.6);
  }

  // ── Time ───────────────────────────────────────────────────────────────────

  (ItemTime, double) _inferTime(String lower, DateTime now) {
    // Hard time patterns
    final RegExpMatch? hardTime =
    RegExp(r'\b(?:at\s+)?(\d{1,2})\s*(am|pm|a\.m\.|p\.m\.)\b').firstMatch(lower);
    if (hardTime != null) {
      final int hour =
      _to24h(int.parse(hardTime.group(1)!), hardTime.group(2)!);
      final DateTime at = DateTime(now.year, now.month, now.day, hour);
      // If we matched "daily" alongside, mark as recurring.
      if (RegExp(r'\b(daily|every\s+day|each\s+day)\b').hasMatch(lower)) {
        return (
        ItemTime.recurring(
          rrule: 'FREQ=DAILY',
          referenceTime: at,
        ),
        0.94,
        );
      }
      return (ItemTime.hardTime(at: at), 0.92);
    }
    // Day-of-week recurrences
    final RegExpMatch? weekly = RegExp(
      r'\bevery\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
    ).firstMatch(lower);
    if (weekly != null) {
      final String dayName = weekly.group(1)!;
      final String byday = _weekdayToByday(dayName);
      return (
      ItemTime.recurring(
        rrule: 'FREQ=WEEKLY;BYDAY=$byday',
        referenceTime: now,
      ),
      0.9,
      );
    }
    // "Weekly" without a specific day
    if (RegExp(r'\bweekly\b|\bevery\s+week\b').hasMatch(lower)) {
      return (
      ItemTime.recurring(
        rrule: 'FREQ=WEEKLY',
        referenceTime: now,
      ),
      0.6, // tentative — we don't know which day
      );
    }
    // Soft windows
    if (RegExp(r'\bthis\s+week\b').hasMatch(lower)) {
      return (
      ItemTime.timeWindow(
        from: now,
        until: _endOfWeek(now),
      ),
      0.7,
      );
    }
    if (RegExp(r'\bby\s+friday\b').hasMatch(lower)) {
      return (
      ItemTime.timeWindow(
        from: now,
        until: _nextOccurrenceOfWeekday(now, DateTime.friday),
      ),
      0.78,
      );
    }
    if (RegExp(r'\btomorrow\b').hasMatch(lower)) {
      final DateTime tom = DateTime(now.year, now.month, now.day + 1);
      return (
      ItemTime.timeWindow(from: tom, until: tom),
      0.85,
      );
    }
    if (RegExp(r'\b(sometime|whenever|some\s+day)\b').hasMatch(lower)) {
      return (const ItemTime.untimed(), 0.9);
    }
    return (const ItemTime.untimed(), 0.45);
  }

  int _to24h(int rawHour, String suffix) {
    final bool isPm = suffix.startsWith('p');
    if (rawHour == 12) return isPm ? 12 : 0;
    return isPm ? rawHour + 12 : rawHour;
  }

  String _weekdayToByday(String name) {
    return switch (name) {
      'monday' => 'MO',
      'tuesday' => 'TU',
      'wednesday' => 'WE',
      'thursday' => 'TH',
      'friday' => 'FR',
      'saturday' => 'SA',
      'sunday' => 'SU',
      _ => 'MO',
    };
  }

  DateTime _endOfWeek(DateTime from) {
    // Treat Sunday as the end of the week (Indian English convention; the
    // mock doesn't need to be locale-perfect).
    final int daysToSunday = (DateTime.sunday - from.weekday) % 7;
    final DateTime sunday = DateTime(from.year, from.month, from.day + daysToSunday);
    return DateTime(sunday.year, sunday.month, sunday.day, 23, 59);
  }

  DateTime _nextOccurrenceOfWeekday(DateTime from, int weekday) {
    final int delta = (weekday - from.weekday) % 7;
    final int days = delta == 0 ? 7 : delta;
    return DateTime(from.year, from.month, from.day + days, 23, 59);
  }

  // ── Temperature ────────────────────────────────────────────────────────────

  Temperature _inferTemperature(PlanItemType type, ItemTime time) {
    if (type == PlanItemType.medication || type == PlanItemType.appointment) {
      return Temperature.hot;
    }
    return time.when<Temperature>(
      hardTime: (_, __) => Temperature.hot,
      timeWindow: (_, __) => Temperature.warm,
      recurring: (_, __, ___) => Temperature.hot,
      untimed: () => Temperature.cool,
    );
  }
}