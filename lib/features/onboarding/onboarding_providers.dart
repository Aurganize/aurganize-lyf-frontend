import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_providers.dart';

part 'onboarding_providers.g.dart';

const String _kOnboardingCompletedKey = 'onboardingCompleted';

/// Whether the user has completed onboarding.
///
/// `true` after the first successful "Get started" tap. Persisted in
/// [SharedPreferences] so subsequent launches skip the screen.
///
/// `keepAlive: true` because the router consults this on every
/// navigation and disposing/recreating on every read is wasteful.
@Riverpod(keepAlive: true)
class OnboardingCompleted extends _$OnboardingCompleted {
  @override
  Future<bool> build() async {
    final SharedPreferences prefs =
    await ref.watch(sharedPreferencesProvider.future);
    return prefs.getBool(_kOnboardingCompletedKey) ?? false;
  }

  /// Marks onboarding as complete. Idempotent; safe to call again.
  Future<void> markComplete() async {
    final SharedPreferences prefs =
    await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_kOnboardingCompletedKey, true);
    state = const AsyncValue<bool>.data(true);
  }

  /// Test/dev helper — resets the flag.
  Future<void> debugReset() async {
    final SharedPreferences prefs =
    await ref.read(sharedPreferencesProvider.future);
    await prefs.remove(_kOnboardingCompletedKey);
    state = const AsyncValue<bool>.data(false);
  }
}