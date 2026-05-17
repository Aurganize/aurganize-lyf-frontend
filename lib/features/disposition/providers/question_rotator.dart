import 'dart:math';

import 'package:meta/meta.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../presentation/disposition_copy.dart';

part 'question_rotator.g.dart';

/// Picks a non-repeating opening question for each disposition prompt.
///
/// Holds an in-memory set of recently-seen question indices and
/// avoids them until the bank is exhausted, then resets.
///
/// `keepAlive: true` so the seen-set survives screen navigations
/// within a single app session. The set resets when the app
/// process is killed — that's the right scope: "session" matches
/// the user's mental model of "you already asked me that today",
/// not "you asked me that 3 months ago at midnight."
@Riverpod(keepAlive: true)
class QuestionRotator extends _$QuestionRotator {
  // The seed is only set in tests; production uses the real Random.
  late final Random _rng;
  final Set<int> _seenIndices = <int>{};

  QuestionRotator() {
    _rng = Random();
  }

  QuestionRotator._({Random? rng}) : _rng = rng ?? Random();

  @override
  // The build method is called by the codegen; we initialize via a
  // factory shim in tests by overriding the provider. The default
  // ctor uses the real Random.
  // Note: codegen requires a no-arg constructor; we expose `_seedFor`
  // as a test hook below.
  // ignore: prefer_initializing_formals
  bool build() {
    // No persistent state to expose — this notifier is "stateless"
    // from the outside view. We use it as a method-bag.
    return false;
  }

  /// Pick a fresh question for the supplied [planItemTitle].
  String questionFor(String planItemTitle) {
    if (_seenIndices.length >= DispositionCopy.questionBank.length) {
      _seenIndices.clear();
    }
    int index;
    do {
      index = _rng.nextInt(DispositionCopy.questionBank.length);
    } while (_seenIndices.contains(index));
    _seenIndices.add(index);
    return DispositionCopy.questionBank[index]
        .replaceAll('{title}', planItemTitle);
  }

  /// Test hook to reset the seen set deterministically.
  @visibleForTesting
  void debugReset() => _seenIndices.clear();
}