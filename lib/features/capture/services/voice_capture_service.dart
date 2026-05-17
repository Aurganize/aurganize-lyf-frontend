import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/utils/logger.dart';

part 'voice_capture_service.g.dart';

/// Listening-loop state visible to the widget.
enum VoiceState {
  idle,
  initializing,
  listening,
  /// Recognition has stopped; the final transcript is in [VoiceResult.text].
  /// The widget pulls it and resets the service to [idle].
  done,
  /// An error or permission denial.
  failed,
}

/// Reason a voice session ended in [VoiceState.failed].
enum VoiceFailureReason {
  /// The user denied (or has not granted) microphone permission.
  permissionDenied,
  /// The user previously denied permission with "don't ask again", or
  /// the OS blocked the request entirely. The widget surfaces an
  /// "Open Settings" dialog.
  permissionPermanentlyDenied,
  /// The plugin's `initialize()` failed — usually because the device
  /// has no speech recognition available (some restricted Android
  /// builds).
  unavailable,
  /// Network / engine error mid-listen.
  recognitionFailed,
  /// We tried to start while already listening — recovered by stopping
  /// then restarting, but surfaced for diagnostic logs.
  conflict,
}

/// Single immutable snapshot exposed to the widget.
class VoiceResult {
  const VoiceResult({
    required this.state,
    this.text = '',
    this.confidence = 0,
    this.failure,
  });

  final VoiceState state;
  /// The accumulated recognized text. Updates while [state] is
  /// [VoiceState.listening]; final when [VoiceState.done].
  final String text;
  final double confidence;
  final VoiceFailureReason? failure;

  VoiceResult copyWith({
    VoiceState? state,
    String? text,
    double? confidence,
    VoiceFailureReason? failure,
  }) {
    return VoiceResult(
      state: state ?? this.state,
      text: text ?? this.text,
      confidence: confidence ?? this.confidence,
      failure: failure ?? this.failure,
    );
  }
}

@Riverpod(keepAlive: true)
VoiceCaptureService voiceCaptureService(VoiceCaptureServiceRef ref) {
  final service = VoiceCaptureService(SpeechToText());
  ref.onDispose(service._dispose);
  return service;
}

/// Wraps [SpeechToText] in a small async-friendly facade.
///
/// Lifecycle:
///   - The plugin is initialized lazily on the first [start] call.
///   - Subsequent calls reuse the same plugin instance.
///   - The service is `keepAlive` so initialization happens once per
///     process.
///
/// Concurrency:
///   - At most one listening session at a time. A [start] while
///     listening stops the current session first (and surfaces a
///     [VoiceFailureReason.conflict] note in the prior stream).
///   - The plugin's internal callbacks fire from the platform side;
///     we marshal them through a [StreamController] so consumers can
///     `await for` a single stream regardless of platform timing.
class VoiceCaptureService {
  VoiceCaptureService(this._stt);

  final SpeechToText _stt;
  bool _initialized = false;
  StreamController<VoiceResult>? _ctl;

  static final Logger _log = appLogger('Voice');

  /// Start listening. Returns a stream that emits [VoiceResult]s for
  /// the duration of the session — exactly one terminal event
  /// ([VoiceState.done] or [VoiceState.failed]) is the last item.
  ///
  /// The stream is single-subscription. If a previous stream is open,
  /// stop the prior session first; this method will surface a
  /// [VoiceFailureReason.conflict] on the prior stream.
  Stream<VoiceResult> start() async* {
    // Stop any existing session.
    if (_ctl != null && !(_ctl!.isClosed)) {
      _ctl!.add(const VoiceResult(
        state: VoiceState.failed,
        failure: VoiceFailureReason.conflict,
      ));
      await _ctl!.close();
      await _stt.stop();
    }

    final StreamController<VoiceResult> ctl =
    StreamController<VoiceResult>();
    _ctl = ctl;
    yield const VoiceResult(state: VoiceState.initializing);

    // Permission gate.
    final PermissionStatus status = await Permission.microphone.request();
    if (status.isPermanentlyDenied) {
      yield const VoiceResult(
        state: VoiceState.failed,
        failure: VoiceFailureReason.permissionPermanentlyDenied,
      );
      await ctl.close();
      return;
    }
    if (!status.isGranted) {
      yield const VoiceResult(
        state: VoiceState.failed,
        failure: VoiceFailureReason.permissionDenied,
      );
      await ctl.close();
      return;
    }

    // Lazy init.
    if (!_initialized) {
      final bool available = await _stt.initialize(
        onError: (SpeechRecognitionError err) {
          _log.warning('plugin error: ${err.errorMsg}');
          if (!ctl.isClosed) {
            ctl.add(const VoiceResult(
              state: VoiceState.failed,
              failure: VoiceFailureReason.recognitionFailed,
            ));
            ctl.close();
          }
        },
        onStatus: (String status) {
          _log.fine('plugin status: $status');
          if (status == 'notListening' || status == 'done') {
            // Plugin reports stop. Our completion path uses the
            // result handler below; this is a backup.
          }
        },
      );
      if (!available) {
        yield const VoiceResult(
          state: VoiceState.failed,
          failure: VoiceFailureReason.unavailable,
        );
        await ctl.close();
        return;
      }
      _initialized = true;
    }

    // Listen.
    yield const VoiceResult(state: VoiceState.listening);
    await _stt.listen(
      onResult: (SpeechRecognitionResult result) {
        if (ctl.isClosed) return;
        ctl.add(VoiceResult(
          state: result.finalResult ? VoiceState.done : VoiceState.listening,
          text: result.recognizedWords,
          confidence: result.confidence,
        ));
        if (result.finalResult) {
          ctl.close();
        }
      },
      // Generous silence-to-stop. Users pause mid-thought; we don't
      // want to cut them off after a comma.
      pauseFor: const Duration(seconds: 2),
      // Long absolute limit so a single capture can be a paragraph.
      listenFor: const Duration(seconds: 60),
      partialResults: true,
      cancelOnError: true,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        // Force on-device recognition where supported — privacy first.
        onDevice: true,
        cancelOnError: true,
      ),
    );

    // Forward results from the controller's stream until close.
    yield* ctl.stream;
  }

  /// Manually stop the active session. The result-handler closes the
  /// controller; this method is a no-op if no session is active.
  Future<void> stop() async {
    await _stt.stop();
    // The plugin's `onResult` fires with `finalResult: true` on stop,
    // which closes the controller via the path above.
  }

  void _dispose() {
    _ctl?.close();
    _ctl = null;
  }
}