import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/logger.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/enums/capture_source.dart';
import '../../../domain/models/intention.dart';
import '../../../domain/repositories/intention_repository.dart';
import '../../auth/auth_providers.dart';

part 'capture_controller.g.dart';

const Uuid _uuid = Uuid();

/// State of the capture controller.
///
/// This is a thin wrapper around the most recently captured intention.
/// The widget doesn't watch this directly — it calls [submit] and gets
/// back the [Intention]. State lives here because tests want a place
/// to observe the sequence of captures.
class CaptureState {
  const CaptureState({this.latest, this.error});

  /// The most recently submitted intention, or null on first launch
  /// of the controller.
  final Intention? latest;

  /// The most recent submission error, or null if the last attempt
  /// succeeded.
  final Object? error;

  CaptureState copyWith({Intention? latest, Object? error}) {
    return CaptureState(
      latest: latest ?? this.latest,
      error: error,
    );
  }
}

/// Orchestrates capture submission — PDD §13, SRS FR-1.2, NFR-1.1.
///
/// Usage from a widget:
///
/// ```dart
/// final controller = ref.read(captureControllerProvider.notifier);
/// final intention = await controller.submit(
///   rawText: 'pick up dry cleaning',
///   source: CaptureSource.typed,
/// );
/// ```
///
/// `submit` returns within ~100 ms regardless of parser duration — the
/// raw text is persisted, the work continues in the background, and
/// the resulting plan items flow back through [pendingCardsProvider].
@riverpod
class CaptureController extends _$CaptureController {
  static final Logger _log = appLogger('CaptureController');

  @override
  CaptureState build() => const CaptureState();

  /// Persists [rawText] as a new [Intention] and queues it for parsing.
  ///
  /// Throws if the local persistence fails (which should only happen
  /// in extreme conditions — disk full, DB locked). Network errors
  /// during parsing surface later via [Intention.parseStatus]; this
  /// method does not throw for them.
  Future<Intention> submit({
    required String rawText,
    required CaptureSource source,
  }) async {
    final String trimmed = rawText.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        rawText,
        'rawText',
        'cannot be empty after trimming',
      );
    }

    final String userId = await ref.read(currentUserIdProvider.future);
    final DateTime now = DateTime.now().toUtc();
    final Intention intention = Intention(
      id: _uuid.v4(),
      userId: userId,
      rawText: trimmed,
      capturedAt: now,
      source: source,
    );

    try {
      final IntentionRepository repo = ref.read(intentionRepositoryProvider);
      await repo.create(intention);
      _log.info('captured intention ${intention.id} (${trimmed.length} chars)');
      state = state.copyWith(latest: intention, error: null);
      return intention;
    } catch (error, stack) {
      _log.severe('capture persistence failed', error, stack);
      state = state.copyWith(error: error);
      rethrow;
    }
  }
}