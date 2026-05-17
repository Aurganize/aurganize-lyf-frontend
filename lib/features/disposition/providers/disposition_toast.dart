import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../presentation/disposition_action.dart';

part 'disposition_toast.g.dart';

/// A one-shot toast emitted by the disposition controller after a
/// successful action. The screen listens to the provider and surfaces
/// the message via [ScaffoldMessenger]; after that, the consumer
/// resets the state to null (or simply ignores subsequent identical
/// values — the message text already encodes the recency).
class DispositionToast {
  const DispositionToast({
    required this.message,
    required this.action,
    required this.timestamp,
  });

  final String message;
  final DispositionAction action;

  /// Used by widget-side dedupe so listeners ignore the same toast
  /// twice. Without this, switching dependencies on the listener
  /// in unrelated widgets could re-fire the same message.
  final DateTime timestamp;
}

@Riverpod(keepAlive: true)
class DispositionToasts extends _$DispositionToasts {
  @override
  DispositionToast? build() => null;

  /// Emit a toast for the [action]. The message text varies by action
  /// and is canonical — same wording every time.
  ///
  /// Per PDD §22 / §17 the language is supportive: "Skipped — streak
  /// intact", never "Skipped — task abandoned."
  void emit(DispositionAction action) {
    final String message = switch (action) {
      DispositionAction.done => 'Marked done',
      DispositionAction.onIt => "On it — we'll keep nudging",
      DispositionAction.pushToTomorrow => 'Returned to plan for tomorrow',
      DispositionAction.pushToToday => 'Moved to today\'s plan',
      DispositionAction.skipIt => 'Skipped — streak intact',
    };
    state = DispositionToast(
      message: message,
      action: action,
      timestamp: DateTime.now(),
    );
  }

  /// Consumers call this after showing the toast so subsequent
  /// listeners don't re-show it.
  void clear() => state = null;
}