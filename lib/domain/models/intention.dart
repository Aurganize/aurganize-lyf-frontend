import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/capture_source.dart';
import '../enums/parse_status.dart';

part 'intention.freezed.dart';
part 'intention.g.dart';

/// The raw, natural-language expression of something the user means
/// to do — exactly as captured. The permanent source of truth.
///
/// **An [Intention] is immutable from the user's perspective.** It is
/// retained permanently independent of any structured interpretation
/// derived from it (SRS FR-1.3).
///
/// The [parseStatus] field is the only mutable aspect, and it moves
/// monotonically forward through its lifecycle.
@freezed
class Intention with _$Intention {
  const Intention._();

  const factory Intention({
    /// Client-generated UUID v4. Stable across sync.
    required String id,

    /// Owning user — the user who captured this. In v1.0 every
    /// intention has exactly one owner; group items are propagated
    /// as separate member-private copies (SRS FR-7.4).
    required String userId,

    /// The text the user typed or spoke, verbatim.
    required String rawText,

    /// When the user captured this (device clock at submission time).
    required DateTime capturedAt,

    /// How it was captured.
    required CaptureSource source,

    /// Current parse status. Starts at [ParseStatus.pending],
    /// progresses through [ParseStatus.inProgress] to
    /// [ParseStatus.parsed] or [ParseStatus.failed].
    @Default(ParseStatus.pending) ParseStatus parseStatus,

    /// IDs of the [PlanItem]s produced from parsing this intention.
    /// May contain multiple IDs — a single capture can split into
    /// several plan items (SRS FR-2.2).
    @Default(<String>[]) List<String> planItemIds,

    /// Free-form server-side error message if [parseStatus] is
    /// [ParseStatus.failed]. Surfaced to the user via the
    /// "We saved what you typed but couldn't organize it" copy
    /// in PDD §25.
    String? parseError,
  }) = _Intention;

  factory Intention.fromJson(Map<String, Object?> json) =>
      _$IntentionFromJson(json);

  bool get isParsed => parseStatus == ParseStatus.parsed;
  bool get isFailed => parseStatus == ParseStatus.failed;
  bool get isPending =>
      parseStatus == ParseStatus.pending ||
          parseStatus == ParseStatus.inProgress;
}