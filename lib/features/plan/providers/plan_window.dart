import 'package:aurganize_lyf/core/extensions/datetime_extensions.dart';

/// A contiguous window of UTC day buckets used by the date train and
/// related providers.
///
/// Buckets are inclusive on both ends. `length` is therefore `end - start + 1`.
class DayWindow {
  const DayWindow({required this.startBucket, required this.endBucket})
      : assert(endBucket >= startBucket, 'endBucket must be >= startBucket');

  final int startBucket;
  final int endBucket;

  int get length => endBucket - startBucket + 1;

  /// All buckets in the window, in order.
  Iterable<int> buckets() sync* {
    for (int b = startBucket; b <= endBucket; b++) {
      yield b;
    }
  }

  /// The window centered on [todayBucket], stretching [pastDays] back
  /// and [futureDays] forward.
  factory DayWindow.around(
      int todayBucket, {
        int pastDays = 2,
        int futureDays = 3,
      }) {
    return DayWindow(
      startBucket: todayBucket - pastDays,
      endBucket: todayBucket + futureDays,
    );
  }

  /// The default window for the date train.
  factory DayWindow.defaultTrain() => DayWindow.around(DayBucket.today());
}