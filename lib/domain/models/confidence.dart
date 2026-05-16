import 'package:freezed_annotation/freezed_annotation.dart';

part 'confidence.freezed.dart';
part 'confidence.g.dart';

/// A confidence score in the range `[0.0, 1.0]` for a single inferred
/// attribute. SRS FR-2.4.
///
/// Two values are exposed as named constants because they appear so
/// often:
///   - [Confidence.certain] — the value was set by the user, not inferred.
///   - [Confidence.unknown] — no inference attempted; surfaces tentatively.
@freezed
class Confidence with _$Confidence {
  const Confidence._();

  @Assert('value >= 0.0 && value <= 1.0', 'Confidence must be in [0,1]')
  const factory Confidence(double value) = _Confidence;

  factory Confidence.fromJson(Map<String, Object?> json) =>
      _$ConfidenceFromJson(json);

  /// User-set value — full confidence.
  static const Confidence certain = Confidence(1);

  /// No information — used for fields the parser did not attempt.
  static const Confidence unknown = Confidence(0);

  /// The threshold below which the UI renders the attribute as tentative
  /// (dashed border, "tap to confirm or change") per PDD §9.3.
  static const double tentativeThreshold = 0.7;

  bool get isTentative => value < tentativeThreshold;

  bool get isCertain => value >= tentativeThreshold;

}