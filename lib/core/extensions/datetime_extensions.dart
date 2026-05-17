/// DateTime helpers used across the data layer and UI.
///
/// The product's "what day is this on" reasoning is everywhere — date
/// train tiles, today view, leftover view, project-progress sums. The
/// only correct unit for these comparisons is **whole UTC days**.
/// Local-time day boundaries cause "this item belongs to today" to
/// disagree with "this item is in the today index" across DST.
extension DateTimeDayBucket on DateTime {
  /// Number of whole UTC days from the Unix epoch to this instant.
  /// Stable across time zones and DST.
  int get utcDayBucket {
    final DateTime utc = isUtc ? this : toUtc();
    return utc.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  }

  /// Strips time-of-day. Returns the start of the same UTC day.
  DateTime get utcDayStart {
    final DateTime utc = isUtc ? this : toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }

  /// True if this instant falls in the same UTC day as [other].
  bool isSameUtcDayAs(DateTime other) => utcDayBucket == other.utcDayBucket;
}

/// Static-style helpers for working with day buckets without a DateTime
/// in hand.
abstract final class DayBucket {
  DayBucket._();

  /// The current UTC day bucket according to the device clock.
  static int today() => DateTime.now().utcDayBucket;

  /// The day bucket [offsetDays] from today. Negative offsets are past
  /// days; positive offsets are future days.
  static int relativeToToday(int offsetDays) => today() + offsetDays;

  /// Converts a UTC-day bucket back to the [DateTime] at start-of-day UTC.
  static DateTime asDateTime(int bucket) => DateTime.fromMillisecondsSinceEpoch(
    bucket * Duration.millisecondsPerDay,
    isUtc: true,
  );
}