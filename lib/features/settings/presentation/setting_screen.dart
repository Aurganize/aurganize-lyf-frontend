import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/app_preferences.dart';
import '../services/data_exporter.dart';
import 'profile_card.dart';
import 'settings_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: <Widget>[
          const ProfileCard(),
          _NotificationsSection(),
          _EngagementSection(),
          _PrivacySection(),
          _PersonalizationSection(),
          _DataRow(),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifications
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifEnabled = ref.watch(notificationsEnabledProvider);
    final reduceEvening = ref.watch(reduceEveningNudgesProvider);
    final quietHours = ref.watch(quietHoursProvider);

    return SettingsSection(
      title: 'NOTIFICATIONS',
      children: <Widget>[
        notifEnabled.when(
          loading: () => const _PrefRowSkeleton(),
          error: (Object e, _) => _PrefRowError(error: e),
          data: (bool v) => SettingsToggleRow(
            title: 'Enable notifications',
            subtitle: 'Hot items get nudges; cool items stay quiet.',
            value: v,
            onChanged: (bool next) =>
                ref.read(notificationsEnabledProvider.notifier).set(next),
          ),
        ),
        reduceEvening.when(
          loading: () => const _PrefRowSkeleton(),
          error: (Object e, _) => _PrefRowError(error: e),
          data: (bool v) => SettingsToggleRow(
            title: 'Reduce evening nudges',
            subtitle: 'Soft items quiet down after sunset.',
            value: v,
            onChanged: (bool next) =>
                ref.read(reduceEveningNudgesProvider.notifier).set(next),
            // Only meaningful when notifications are enabled overall.
            enabled: notifEnabled.maybeWhen(
              data: (bool n) => n,
              orElse: () => true,
            ),
          ),
        ),
        quietHours.when(
          loading: () => const _PrefRowSkeleton(),
          error: (Object e, _) => _PrefRowError(error: e),
          data: (QuietHoursState q) => SettingsActionRow(
            title: 'Quiet hours',
            subtitle: '${_formatMinutes(q.startMinutes)} – '
                '${_formatMinutes(q.endMinutes)}',
            onTap: () async {
              final TimeOfDay? start = await showTimePicker(
                context: context,
                initialTime: _toTimeOfDay(q.startMinutes),
                helpText: 'QUIET START',
              );
              if (start == null || !context.mounted) return;
              final TimeOfDay? end = await showTimePicker(
                context: context,
                initialTime: _toTimeOfDay(q.endMinutes),
                helpText: 'QUIET END',
              );
              if (end == null) return;
              await ref.read(quietHoursProvider.notifier).set(
                startMinutes: start.hour * 60 + start.minute,
                endMinutes: end.hour * 60 + end.minute,
              );
            },
            enabled: notifEnabled.maybeWhen(
              data: (bool n) => n,
              orElse: () => true,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatMinutes(int minutes) {
  final int h = minutes ~/ 60;
  final int m = minutes % 60;
  final String period = h < 12 ? 'AM' : 'PM';
  final int displayHour = h % 12 == 0 ? 12 : h % 12;
  return '$displayHour:${m.toString().padLeft(2, '0')} $period';
}

TimeOfDay _toTimeOfDay(int minutes) {
  return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
}

// ─────────────────────────────────────────────────────────────────────────────
// Engagement
// ─────────────────────────────────────────────────────────────────────────────

class _EngagementSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamification = ref.watch(gamificationEnabledProvider);
    final recovery = ref.watch(recoveryDaysPerMonthProvider);

    return SettingsSection(
      title: 'ENGAGEMENT',
      children: <Widget>[
        gamification.when(
          loading: () => const _PrefRowSkeleton(),
          error: (Object e, _) => _PrefRowError(error: e),
          data: (bool v) => SettingsToggleRow(
            title: 'Streak & gamification',
            subtitle: 'Show the streak chip and reward recovery days.',
            value: v,
            onChanged: (bool next) =>
                ref.read(gamificationEnabledProvider.notifier).set(next),
          ),
        ),
        recovery.when(
          loading: () => const _PrefRowSkeleton(),
          error: (Object e, _) => _PrefRowError(error: e),
          data: (int v) => SettingsSliderRow(
            title: 'Recovery days per month',
            value: v,
            min: 0,
            max: 10,
            divisions: 10,
            valueLabel: '$v',
            onChanged: (int next) =>
                ref.read(recoveryDaysPerMonthProvider.notifier).set(next),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Privacy
// ─────────────────────────────────────────────────────────────────────────────

class _PrivacySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final corrections = ref.watch(correctionsForLearningProvider);
    final anon = ref.watch(anonStatsEnabledProvider);

    return SettingsSection(
      title: 'PRIVACY',
      children: <Widget>[
        corrections.when(
          loading: () => const _PrefRowSkeleton(),
          error: (Object e, _) => _PrefRowError(error: e),
          data: (bool v) => SettingsToggleRow(
            title: 'Use my corrections to improve parsing',
            subtitle:
            'Edits to parsed items help us guess better next time.',
            value: v,
            onChanged: (bool next) =>
                ref.read(correctionsForLearningProvider.notifier).set(next),
          ),
        ),
        anon.when(
          loading: () => const _PrefRowSkeleton(),
          error: (Object e, _) => _PrefRowError(error: e),
          data: (bool v) => SettingsToggleRow(
            title: 'Anonymous usage stats',
            subtitle: 'Helps us spot what\'s working.',
            value: v,
            onChanged: (bool next) =>
                ref.read(anonStatsEnabledProvider.notifier).set(next),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Personalization
// ─────────────────────────────────────────────────────────────────────────────

class _PersonalizationSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motion = ref.watch(reducedMotionProvider);
    final weekStart = ref.watch(weekStartPrefProvider);

    return SettingsSection(
      title: 'PERSONALIZATION',
      children: <Widget>[
        motion.when(
          loading: () => const _PrefRowSkeleton(),
          error: (Object e, _) => _PrefRowError(error: e),
          data: (ReducedMotionMode m) => SettingsActionRow(
            title: 'Reduced motion',
            subtitle: switch (m) {
              ReducedMotionMode.system => 'Follow system setting',
              ReducedMotionMode.alwaysOn => 'Always on',
              ReducedMotionMode.alwaysOff => 'Always off',
            },
            onTap: () async {
              final ReducedMotionMode? next =
              await _pickReducedMotion(context, current: m);
              if (next != null) {
                await ref.read(reducedMotionProvider.notifier).set(next);
              }
            },
          ),
        ),
        weekStart.when(
          loading: () => const _PrefRowSkeleton(),
          error: (Object e, _) => _PrefRowError(error: e),
          data: (WeekStart ws) => SettingsActionRow(
            title: 'Week starts on',
            subtitle: ws == WeekStart.monday ? 'Monday' : 'Sunday',
            onTap: () async {
              final WeekStart? next =
              await _pickWeekStart(context, current: ws);
              if (next != null) {
                await ref.read(weekStartPrefProvider.notifier).set(next);
              }
            },
          ),
        ),
      ],
    );
  }
}

Future<ReducedMotionMode?> _pickReducedMotion(
    BuildContext context, {
      required ReducedMotionMode current,
    }) {
  return showModalBottomSheet<ReducedMotionMode>(
    context: context,
    builder: (BuildContext _) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final ReducedMotionMode m in ReducedMotionMode.values)
              ListTile(
                title: Text(switch (m) {
                  ReducedMotionMode.system => 'Follow system',
                  ReducedMotionMode.alwaysOn => 'Always on',
                  ReducedMotionMode.alwaysOff => 'Always off',
                }),
                trailing: current == m ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(m),
              ),
          ],
        ),
      );
    },
  );
}

Future<WeekStart?> _pickWeekStart(
    BuildContext context, {
      required WeekStart current,
    }) {
  return showModalBottomSheet<WeekStart>(
    context: context,
    builder: (BuildContext _) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: const Text('Sunday'),
              trailing: current == WeekStart.sunday
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.of(context).pop(WeekStart.sunday),
            ),
            ListTile(
              title: const Text('Monday'),
              trailing: current == WeekStart.monday
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.of(context).pop(WeekStart.monday),
            ),
          ],
        ),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Data row — export + delete
// ─────────────────────────────────────────────────────────────────────────────

class _DataRow extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DataRow> createState() => _DataRowState();
}

class _DataRowState extends ConsumerState<_DataRow> {
  bool _exportBusy = false;

  Future<void> _export() async {
    if (_exportBusy) return;
    setState(() => _exportBusy = true);
    try {
      await ref.read(dataExporterProvider).exportAndShare();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't export: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _exportBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'YOUR DATA',
      children: <Widget>[
        SettingsActionRow(
          title: _exportBusy ? 'Preparing export…' : 'Export my data',
          subtitle: 'Share a JSON snapshot with another app.',
          onTap: _export,
          enabled: !_exportBusy,
          trailingIcon: Icons.ios_share,
        ),
        const SettingsActionRow(
          title: 'Delete my account and data',
          subtitle: 'Available when sync is enabled.',
          onTap: _noop,
          enabled: false,
          trailingIcon: Icons.delete_outline,
          titleColor: AppColors.tempHot,
        ),
      ],
    );
  }
}

void _noop() {}

// ─────────────────────────────────────────────────────────────────────────────
// Per-row placeholders
// ─────────────────────────────────────────────────────────────────────────────

class _PrefRowSkeleton extends StatelessWidget {
  const _PrefRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      alignment: Alignment.centerLeft,
      child: Container(
        height: 14,
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _PrefRowError extends StatelessWidget {
  const _PrefRowError({required this.error});
  final Object error;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg, vertical: AppSpacing.md,
      ),
      child: Text('Error: $error', style: AppTypography.bodyMuted),
    );
  }
}