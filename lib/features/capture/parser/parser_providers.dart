import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'intention_parser.dart';
import 'mock_intention_parser.dart';

part 'parser_providers.g.dart';

/// The active [IntentionParser] implementation.
///
/// Marked `keepAlive: true` because the parser itself is stateless and
/// auto-disposing it would just waste cycles on re-construction.
///
/// **Override in tests** by passing `intentionParserProvider.overrideWithValue(...)`
/// to a [ProviderContainer] or a [ProviderScope.overrides].
///
/// **Override in Phase 21** (remote backend) by replacing the body
/// with a `RemoteIntentionParser` that calls our FastAPI server. The
/// signature does not change.
@Riverpod(keepAlive: true)
IntentionParser intentionParser(IntentionParserRef ref) {
  return MockIntentionParser();
}