import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/item_time.dart';
import '../../../domain/models/plan_item.dart';
import 'project_progress.dart';

/// Header block on the project view — eyebrow, title, soft deadline,
/// progress bar with a caption.
class ProjectHeader extends ConsumerWidget {
  const ProjectHeader({super.key, required this.project});

  final PlanItem project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ProjectProgress> progressAsync =
    ref.watch(projectProgressProvider(rootId: project.id));

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _eyebrow(progressAsync),
          const SizedBox(height: AppSpacing.sm),
          Text(project.title, style: AppTypography.title),
          const SizedBox(height: AppSpacing.sm),
          _deadlineLine(project.time),
          const SizedBox(height: AppSpacing.lg),
          _progressBar(progressAsync),
        ],
      ),
    );
  }

  Widget _eyebrow(AsyncValue<ProjectProgress> progress) {
    final String label = progress.maybeWhen(
      data: (ProjectProgress p) =>
      'PROJECT · ${p.total} ${p.total == 1 ? "ITEM" : "ITEMS"}',
      orElse: () => 'PROJECT',
    );
    return Text(label, style: AppTypography.eyebrow);
  }

  Widget _deadlineLine(ItemTime time) {
    final (IconData icon, String text)? line = _formatDeadline(time);
    if (line == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(line.$1, size: 14, color: AppColors.iconMuted),
        const SizedBox(width: AppSpacing.xs),
        Text(line.$2, style: AppTypography.caption),
      ],
    );
  }

  (IconData, String)? _formatDeadline(ItemTime time) {
    return time.when<(IconData, String)?>(
      hardTime: (DateTime at, _) {
        final DateTime local = at.toLocal();
        final DateFormat fmt = DateFormat.yMMMMEEEEd();
        return (Icons.event_outlined, '${fmt.format(local)} · ${_daysAway(local)}');
      },
      timeWindow: (DateTime? _, DateTime until) {
        final DateTime local = until.toLocal();
        final DateFormat fmt = DateFormat.yMMMMEEEEd();
        return (Icons.date_range_outlined,
        '${fmt.format(local)} · ${_daysAway(local)}');
      },
      recurring: (String rrule, _, __) => (
      Icons.refresh,
      rrule == 'FREQ=DAILY' ? 'Daily' : 'Recurring',
      ),
      untimed: () => null,
    );
  }

  String _daysAway(DateTime local) {
    final DateTime now = DateTime.now();
    final int diff = local
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (diff < 0) return '${(-diff)} ${diff == -1 ? "day" : "days"} ago';
    if (diff == 0) return 'today';
    if (diff == 1) return 'tomorrow';
    return '$diff days away';
  }

  Widget _progressBar(AsyncValue<ProjectProgress> progressAsync) {
    return progressAsync.when(
      loading: () => const _ProgressBarSkeleton(),
      error: (Object _, __) => const SizedBox.shrink(),
      data: (ProjectProgress p) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: p.fraction,
                minHeight: 4,
                backgroundColor: AppColors.surfaceSecondary,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.brandPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(p.label, style: AppTypography.caption),
          ],
        );
      },
    );
  }
}

class _ProgressBarSkeleton extends StatelessWidget {
  const _ProgressBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}