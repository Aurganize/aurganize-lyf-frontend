import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/auth_providers.dart';

part 'app_preferences.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Keys are centralized so they're never typo'd at call sites.
// ─────────────────────────────────────────────────────────────────────────────

abstract final class PrefKeys {
  PrefKeys._();

  // Notifications
  static const String notificationsEnabled = 'notif.enabled';
  static const String reduceEveningNudges = 'notif.reduceEvening';
  static const String quietHoursStart = 'notif.quietStart'; // minutes from midnight
  static const String quietHoursEnd = 'notif.quietEnd';     // minutes from midnight

  // Engagement
  static const String gamificationEnabled = 'engage.gamification';
  static const String recoveryDaysPerMonth = 'engage.recoveryDays';

  // Privacy
  static const String correctionsForLearning = 'priv.corrections';
  static const String anonStats = 'priv.anonStats';

  // Personalization
  static const String reducedMotionOverride = 'pers.reducedMotion'; // 'system' | 'on' | 'off'
  static const String weekStart = 'pers.weekStart'; // 'sunday' | 'monday'
}

// ─────────────────────────────────────────────────────────────────────────────
// One provider per setting. Each watches sharedPreferencesProvider.
// We use the codegen sync form for booleans/ints, async for the more
// elaborate setting that requires reading prefs.
// ─────────────────────────────────────────────────────────────────────────────

T _read<T>(SharedPreferences prefs, String key, T defaultValue) {
  if (T == bool) return (prefs.getBool(key) ?? defaultValue as bool) as T;
  if (T == int) return (prefs.getInt(key) ?? defaultValue as int) as T;
  if (T == String) {
    return (prefs.getString(key) ?? defaultValue as String) as T;
  }
  throw ArgumentError('Unsupported pref type: $T');
}

Future<void> _write<T>(SharedPreferences prefs, String key, T value) async {
  if (value is bool) {
    await prefs.setBool(key, value);
  } else if (value is int) {
    await prefs.setInt(key, value);
  } else if (value is String) {
    await prefs.setString(key, value);
  } else {
    throw ArgumentError('Unsupported pref type: ${value.runtimeType}');
  }
}

// ── Notifications ──────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class NotificationsEnabled extends _$NotificationsEnabled {
  @override
  Future<bool> build() async {
    final SharedPreferences prefs =
    await ref.watch(sharedPreferencesProvider.future);
    return _read<bool>(prefs, PrefKeys.notificationsEnabled, true);
  }

  Future<void> set(bool value) async {
    final SharedPreferences prefs =
    await ref.read(sharedPreferencesProvider.future);
    await _write<bool>(prefs, PrefKeys.notificationsEnabled, value);
    state = AsyncValue<bool>.data(value);
  }
}

@Riverpod(keepAlive: true)
class ReduceEveningNudges extends _$ReduceEveningNudges {
  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return _read<bool>(prefs, PrefKeys.reduceEveningNudges, false);
  }

  Future<void> set(bool value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await _write<bool>(prefs, PrefKeys.reduceEveningNudges, value);
    state = AsyncValue<bool>.data(value);
  }
}

/// Quiet hours stored as start/end minutes from midnight. Combined into
/// a single notifier so a paired update is atomic.
@Riverpod(keepAlive: true)
class QuietHours extends _$QuietHours {
  @override
  Future<QuietHoursState> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return QuietHoursState(
      startMinutes: _read<int>(prefs, PrefKeys.quietHoursStart, 22 * 60),
      endMinutes: _read<int>(prefs, PrefKeys.quietHoursEnd, 7 * 60),
    );
  }

  Future<void> set({required int startMinutes, required int endMinutes}) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await _write<int>(prefs, PrefKeys.quietHoursStart, startMinutes);
    await _write<int>(prefs, PrefKeys.quietHoursEnd, endMinutes);
    state = AsyncValue<QuietHoursState>.data(QuietHoursState(
      startMinutes: startMinutes,
      endMinutes: endMinutes,
    ));
  }
}

class QuietHoursState {
  const QuietHoursState({
    required this.startMinutes,
    required this.endMinutes,
  });

  final int startMinutes;
  final int endMinutes;
}

// ── Engagement ─────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class GamificationEnabled extends _$GamificationEnabled {
  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return _read<bool>(prefs, PrefKeys.gamificationEnabled, true);
  }

  Future<void> set(bool value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await _write<bool>(prefs, PrefKeys.gamificationEnabled, value);
    state = AsyncValue<bool>.data(value);
  }
}

@Riverpod(keepAlive: true)
class RecoveryDaysPerMonth extends _$RecoveryDaysPerMonth {
  @override
  Future<int> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return _read<int>(prefs, PrefKeys.recoveryDaysPerMonth, 4);
  }

  Future<void> set(int value) async {
    final clamped = value.clamp(0, 10);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await _write<int>(prefs, PrefKeys.recoveryDaysPerMonth, clamped);
    state = AsyncValue<int>.data(clamped);
  }
}

// ── Privacy ────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class CorrectionsForLearning extends _$CorrectionsForLearning {
  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return _read<bool>(prefs, PrefKeys.correctionsForLearning, true);
  }

  Future<void> set(bool value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await _write<bool>(prefs, PrefKeys.correctionsForLearning, value);
    state = AsyncValue<bool>.data(value);
  }
}

@Riverpod(keepAlive: true)
class AnonStatsEnabled extends _$AnonStatsEnabled {
  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return _read<bool>(prefs, PrefKeys.anonStats, true);
  }

  Future<void> set(bool value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await _write<bool>(prefs, PrefKeys.anonStats, value);
    state = AsyncValue<bool>.data(value);
  }
}

// ── Personalization ────────────────────────────────────────────────────────

enum ReducedMotionMode { system, alwaysOn, alwaysOff }

@Riverpod(keepAlive: true)
class ReducedMotion extends _$ReducedMotion {
  @override
  Future<ReducedMotionMode> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final String raw = _read<String>(
      prefs, PrefKeys.reducedMotionOverride, 'system',
    );
    return switch (raw) {
      'on' => ReducedMotionMode.alwaysOn,
      'off' => ReducedMotionMode.alwaysOff,
      _ => ReducedMotionMode.system,
    };
  }

  Future<void> set(ReducedMotionMode value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final String raw = switch (value) {
      ReducedMotionMode.alwaysOn => 'on',
      ReducedMotionMode.alwaysOff => 'off',
      ReducedMotionMode.system => 'system',
    };
    await _write<String>(prefs, PrefKeys.reducedMotionOverride, raw);
    state = AsyncValue<ReducedMotionMode>.data(value);
  }
}

enum WeekStart { sunday, monday }

@Riverpod(keepAlive: true)
class WeekStartPref extends _$WeekStartPref {
  @override
  Future<WeekStart> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final String raw =
    _read<String>(prefs, PrefKeys.weekStart, 'sunday');
    return raw == 'monday' ? WeekStart.monday : WeekStart.sunday;
  }

  Future<void> set(WeekStart value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await _write<String>(prefs, PrefKeys.weekStart,
        value == WeekStart.monday ? 'monday' : 'sunday');
    state = AsyncValue<WeekStart>.data(value);
  }
}