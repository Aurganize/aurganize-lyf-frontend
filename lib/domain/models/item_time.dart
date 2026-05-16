import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_time.freezed.dart';
part 'item_time.g.dart';
/// The time aspect of a plan item — SRS FR-3.3.
///
/// Four variants, exhaustively:
///   - [hardTime]   — a fixed clock time (e.g. "9 a.m. tomorrow").
///   - [timeWindow] — a soft deadline window (e.g. "by Friday").
///   - [recurring]  — a recurring rule (e.g. "every weekday at 9 a.m.").
///   - [untimed]    — no time at all (e.g. "sometime call mom").
///
/// Sealed union — pattern-match in consumers to handle each variant.
/// When new variants are added, dart's exhaustiveness check will
/// surface every consumer that needs updating.
@freezed
sealed class ItemTime with _$ItemTime {

  const factory ItemTime.hardTime({
    required DateTime at,

    /// Optional duration. For appointments and medication this matters;
    /// for alarms it's null.
    Duration? duration,
  }) = HardTime;

  const factory ItemTime.timeWindow({
    /// The window opens at this instant. Often null (window is open now).
    DateTime? from,

    /// The window closes at this instant. Required — without an end,
    /// it's an [untimed] item.
    required DateTime until,
  }) = TimeWindow;

  const factory ItemTime.recurring({
    /// The recurrence rule, in iCalendar RRULE format (RFC 5545).
    /// Examples:
    ///   "FREQ=DAILY"                          — every day
    ///   "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR"     — every weekday
    ///   "FREQ=WEEKLY;BYDAY=SA"                 — every Saturday
    ///
    /// We choose RRULE over a custom DSL because it's the format
    /// the device calendar uses and the parser's LLM output already
    /// speaks it fluently.
    required String rrule,

    /// The reference clock time for each occurrence. For "daily at 9",
    /// this is today (or any day) at 9:00.
    required DateTime referenceTime,

    /// Optional end of the recurrence. Null means "indefinitely".
    DateTime? until,
  }) = Recurring;

  const factory ItemTime.untimed() = Untimed;

  factory ItemTime.fromJson(Map<String, Object?> json) =>
      _$ItemTimeFromJson(json);


}