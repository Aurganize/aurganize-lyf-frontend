import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'logger.dart';

/// A [ProviderObserver] that logs lifecycle events at sensible levels.
///
/// Installed only in debug mode. Wiring is done in `main.dart`.
class LoggingProviderObserver extends ProviderObserver {
  LoggingProviderObserver();

  static final Logger _log = appLogger('Providers');

  @override
  void didAddProvider(
      ProviderBase<Object?> provider,
      Object? value,
      ProviderContainer container,
      ) {
    if (!kDebugMode) return;
    _log.fine('+ ${provider.name ?? provider.runtimeType}');
  }

  @override
  void didDisposeProvider(
      ProviderBase<Object?> provider,
      ProviderContainer container,
      ) {
    if (!kDebugMode) return;
    _log.fine('- ${provider.name ?? provider.runtimeType}');
  }

  @override
  void providerDidFail(
      ProviderBase<Object?> provider,
      Object error,
      StackTrace stackTrace,
      ProviderContainer container,
      ) {
    // Errors surface even in release — they indicate real failures.
    _log.severe(
      'Provider failed: ${provider.name ?? provider.runtimeType}',
      error,
      stackTrace,
    );
  }

  @override
  void didUpdateProvider(
      ProviderBase<Object?> provider,
      Object? previousValue,
      Object? newValue,
      ProviderContainer container,
      ) {
    if (!kDebugMode) return;
    // Updates are noisy — keep at FINEST. Enable selectively.
    _log.finest('~ ${provider.name ?? provider.runtimeType}');
  }
}