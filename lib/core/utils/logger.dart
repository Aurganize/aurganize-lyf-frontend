import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Sets up the app-wide logger.
///
/// In debug builds, every log line is forwarded to the dev console.
/// In release builds, only warnings and errors are emitted, and the
/// payload is routed through a sink the app can install (e.g. Sentry,
/// crash reporting). For now, release just goes to stderr via debugPrint.
void configureLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.WARNING;
  Logger.root.onRecord.listen((LogRecord rec) {
    if (kReleaseMode && rec.level < Level.WARNING) return;

    final String prefix = '[${rec.level.name}] ${rec.loggerName}';
    final String message = '${rec.time.toIso8601String()} $prefix: ${rec.message}';

    debugPrint(message);
    if (rec.error != null) {
      debugPrint('  error: ${rec.error}');
    }
    if (rec.stackTrace != null) {
      debugPrint('  stack: ${rec.stackTrace}');
    }
  });
}

/// Convenience constructor — every file that logs creates one of these
/// at the top:
///
/// ```dart
/// final Logger _log = appLogger('PlanItemRepository');
/// ```
Logger appLogger(String name) => Logger(name);