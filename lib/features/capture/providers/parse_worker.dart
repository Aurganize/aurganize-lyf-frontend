import 'dart:async';

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/logger.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/intention.dart';
import '../../../domain/models/plan_item.dart';
import '../../../domain/repositories/intention_repository.dart';
import '../../../domain/repositories/plan_item_repository.dart';
import '../parser/intention_parser.dart';
import '../parser/parser_providers.dart';

part 'parse_worker.g.dart';

/// The background parse loop.
///
/// Long-lived, started by [ensureRunning], pauseable via [pause] and
/// [resume]. Watches the [IntentionRepository.watchPending] stream and
/// processes one intention at a time, in arrival order, using the
/// active [intentionParserProvider].
///
/// ### Guarantees
///   - Pending intentions are picked up in arrival order (FIFO).
///   - Each intention is claimed via the repository's atomic
///     `claimForParsing` — concurrent workers (we only run one in v1.0,
///     but the contract is there) cannot double-process.
///   - On parse failure, the intention is moved to `ParseStatus.failed`
///     with the error message; raw text is preserved.
///   - The loop never crashes the app: every iteration is wrapped in
///     try/catch and logs failures.
///
/// ### Lifecycle
///   - Started by [ensureRunning], typically from the app boot path.
///   - Pause via [pause] (acquires no more work; in-flight work
///     completes).
///   - Resume via [resume].
///   - Cancelled automatically when the provider is disposed —
///     [keepAlive: true] keeps it alive across screen navigations.
@Riverpod(keepAlive: true)
class ParseWorker extends _$ParseWorker {
  static final Logger _log = appLogger('ParseWorker');

  StreamSubscription<List<Intention>>? _subscription;
  bool _paused = false;
  bool _inFlight = false;

  @override
  ParseWorkerState build() {
    ref.onDispose(_disposeInternal);
    return const ParseWorkerState.stopped();
  }

  /// Idempotent — calling repeatedly has no effect once running.
  void ensureRunning() {
    if (_subscription != null) return;
    final IntentionRepository repo = ref.read(intentionRepositoryProvider);
    _subscription = repo.watchPending().listen(_onPendingChanged);
    state = const ParseWorkerState.running();
    _log.info('parse worker started');
  }

  void pause() {
    _paused = true;
    state = const ParseWorkerState.paused();
  }

  void resume() {
    _paused = false;
    state = const ParseWorkerState.running();
    _drain();
  }

  void _disposeInternal() {
    _subscription?.cancel();
    _subscription = null;
    state = const ParseWorkerState.stopped();
  }

  // ── Loop ──────────────────────────────────────────────────────────────────

  void _onPendingChanged(List<Intention> pending) {
    if (pending.isEmpty || _paused || _inFlight) return;
    unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_inFlight || _paused) return;
    _inFlight = true;
    try {
      while (!_paused) {
        final IntentionRepository repo = ref.read(intentionRepositoryProvider);
        // Take the oldest pending intention. We re-read the stream's
        // latest list each loop turn to pick up newly arrived work.
        final List<Intention> pending =
        await repo.watchPending().first.timeout(
          const Duration(milliseconds: 50),
          onTimeout: () => const <Intention>[],
        );
        if (pending.isEmpty) break;
        await _processOne(pending.first);
      }
    } catch (error, stack) {
      _log.severe('drain loop error', error, stack);
    } finally {
      _inFlight = false;
    }
  }

  Future<void> _processOne(Intention intention) async {
    final IntentionRepository intentRepo =
    ref.read(intentionRepositoryProvider);
    final PlanItemRepository planRepo =
    ref.read(planItemRepositoryProvider);
    final IntentionParser parser = ref.read(intentionParserProvider);

    // 1. Atomically claim. If we don't win, another worker did — skip.
    final bool claimed = await intentRepo.claimForParsing(intention.id);
    if (!claimed) {
      _log.info('lost claim for ${intention.id}; skipping');
      return;
    }

    try {
      // 2. Parse.
      final List<PlanItem> items = await parser.parse(
        userId: intention.userId,
        intentionId: intention.id,
        rawText: intention.rawText,
      );

      if (items.isEmpty) {
        // Parser contract requires non-empty; treat as failure.
        throw ParserFailure('parser returned no plan items');
      }

      // 3. Persist plan items in one transaction.
      await planRepo.createMany(items);

      // 4. Mark the intention parsed.
      await intentRepo.markParsed(intention.id);
      _log.info(
        'parsed ${intention.id} into ${items.length} plan item(s)',
      );
    } catch (error, stack) {
      _log.warning('parse failure for ${intention.id}', error, stack);
      await intentRepo.markFailed(
        intention.id,
        error: error.toString(),
      );
    }
  }
}

/// Worker lifecycle marker. Mostly used in tests and dev observability.
sealed class ParseWorkerState {
  const ParseWorkerState();
  const factory ParseWorkerState.stopped() = _Stopped;
  const factory ParseWorkerState.running() = _Running;
  const factory ParseWorkerState.paused() = _Paused;
}

class _Stopped extends ParseWorkerState {
  const _Stopped();
}

class _Running extends ParseWorkerState {
  const _Running();
}

class _Paused extends ParseWorkerState {
  const _Paused();
}