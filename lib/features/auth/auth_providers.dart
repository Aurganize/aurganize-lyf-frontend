import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/logger.dart';

part 'auth_providers.g.dart';

const Uuid _uuid = Uuid();
const String _kCurrentUserIdKey = 'currentUserId';

/// Async access to [SharedPreferences].
///
/// Hand-written because it's a simple resource that does not benefit
/// from auto-dispose. `keepAlive: true` would work via codegen too,
/// but a plain Provider is shorter at no cost.
final FutureProvider<SharedPreferences> sharedPreferencesProvider =
FutureProvider<SharedPreferences>(
      (Ref ref) => SharedPreferences.getInstance(),
  name: 'sharedPreferences',
);

/// The signed-in user's id.
///
/// In v1.0 there is no real authentication. We mint a stable UUID on
/// first launch and persist it in [SharedPreferences]. Every subsequent
/// launch reads it back, so the same user-scoped data is visible.
///
/// When real authentication ships in Phase 12, this provider is the
/// single place that changes — every downstream consumer keeps working
/// because the interface (`Future<String>`) stays identical.
@Riverpod(keepAlive: true)
Future<String> currentUserId(CurrentUserIdRef ref) async {
  final SharedPreferences prefs =
  await ref.watch(sharedPreferencesProvider.future);

  final String? existing = prefs.getString(_kCurrentUserIdKey);
  if (existing != null) {
    appLogger('Auth').info('resumed user $existing');
    return existing;
  }

  final String fresh = _uuid.v4();
  await prefs.setString(_kCurrentUserIdKey, fresh);
  appLogger('Auth').info('minted new dev user $fresh');
  return fresh;
}

/// Synchronous accessor that throws if the user id has not been
/// resolved yet. Useful in code paths that run after the splash /
/// onboarding has gated on [currentUserIdProvider] resolving.
///
/// Most providers in this app `await` the [currentUserIdProvider]
/// future and use the resolved value directly — that's the safe path.
/// This synchronous variant exists for places that genuinely cannot
/// be async, such as Drift-stream construction inside another
/// provider's body where we want to fail loudly if used too early.
@riverpod
String currentUserIdSync(CurrentUserIdSyncRef ref) {
  final AsyncValue<String> async = ref.watch(currentUserIdProvider);
  return async.maybeWhen(
    data: (String id) => id,
    orElse: () => throw StateError(
      'currentUserIdSync read before currentUserIdProvider resolved. '
          'Await currentUserIdProvider.future or use AsyncValue.when in a widget.',
    ),
  );
}