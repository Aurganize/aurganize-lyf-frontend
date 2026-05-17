import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/datetime_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/plan_item.dart';
import '../../disposition/presentation/disposition_action.dart';
import '../../disposition/providers/disposition_controller.dart';
import '../../disposition/providers/disposition_toast.dart';
import '../providers/leftovers_provider.dart';
import 'leftover_row.dart';

/// PDD §20. Hosted at `/leftover/:bucket`.
///
/// Renders the un-dispositioned items from [dayBucket] as a stack of
/// [LeftoverRow]s. On each disposition, the row animates out; when the
/// last row clears, the screen pops back to landing.
class LeftoverScreen extends ConsumerWidget {
  const LeftoverScreen({super.key, required this.dayBucket});

  final int dayBucket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      dispositionToastsProvider,
          (prev, curr) {
        if (curr == null || curr == prev) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(curr.message),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        ref.read(dispositionToastsProvider.notifier).clear();
      },
    );

    // Auto-pop the screen when the leftover list becomes empty.
    ref.listen<AsyncValue<List<PlanItem>>>(
      leftoversForDateProvider(dayBucket: dayBucket),
          (AsyncValue<List<PlanItem>>? prev, AsyncValue<List<PlanItem>> curr) {
        final bool wasNonEmpty = prev?.valueOrNull?.isNotEmpty ?? false;
        final bool isEmpty = curr.valueOrNull?.isEmpty ?? false;
        if (wasNonEmpty && isEmpty) {
          // Defer a frame so the row's exit animation can complete.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              GoRouter.of(context).pop();
            }
          });
        }
      },
    );

    final AsyncValue<List<PlanItem>> items =
    ref.watch(leftoversForDateProvider(dayBucket: dayBucket));

    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      appBar: AppBar(
        title: Text(_dayTitle(dayBucket)),
      ),
      body: items.when(
        loading: () => const _LoadingBody(),
        error: (Object e, _) => _ErrorBody(error: e),
        data: (List<PlanItem> list) {
          if (list.isEmpty) {
            // The user may have arrived at an already-empty day. Show
            // an "all clear" message; the auto-pop only fires on the
            // transition from non-empty to empty.
            return const _AllClearBody();
          }
          return _LeftoverBody(dayBucket: dayBucket, items: list);
        },
      ),
    );
  }

  String _dayTitle(int bucket) {
    final DateTime local = DayBucket.asDateTime(bucket).toLocal();
    return DateFormat.EEEE().format(local);
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 1.5),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Text(
          'Couldn\'t load this day. $error',
          style: AppTypography.bodyMuted,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _AllClearBody extends StatelessWidget {
  const _AllClearBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.check_circle_outline,
              size: 32,
              color: AppColors.brandPrimary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'This day is closed out.',
              style: AppTypography.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Nothing to look at here.',
              style: AppTypography.bodyMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: () => GoRouter.of(context).pop(),
              child: const Text('Back to plan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftoverBody extends ConsumerWidget {
  const _LeftoverBody({required this.dayBucket, required this.items});

  final int dayBucket;
  final List<PlanItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int today = DayBucket.today();
    final String eyebrow = switch (dayBucket) {
      _ when dayBucket == today - 1 => 'FROM YESTERDAY',
      _ when dayBucket == today - 2 => 'FROM TWO DAYS AGO',
      _ => 'FROM ${DateFormat.yMMMd().format(DayBucket.asDateTime(dayBucket).toLocal()).toUpperCase()}',
    };

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: <Widget>[
          Text(eyebrow, style: AppTypography.eyebrow),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _countTitle(items.length),
            style: AppTypography.title,
          ),
          const SizedBox(height: AppSpacing.lg),
          for (int i = 0; i < items.length; i++) ...<Widget>[
            LeftoverRow(
              key: ValueKey<String>(items[i].id),
              title: items[i].title,
              temperature: items[i].temperature,
              time: items[i].time,
              onDone: () => _dispatch(
                ref,
                items[i],
                DispositionAction.done,
              ),
              onToday: () => _dispatch(
                ref,
                items[i],
                DispositionAction.pushToToday,
              ),
              onSkip: () => _dispatch(
                ref,
                items[i],
                DispositionAction.skipIt,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.md),
          _BulkSkipRow(dayBucket: dayBucket, items: items),
        ],
      ),
    );
  }

  String _countTitle(int count) {
    return '$count ${count == 1 ? "thing" : "things"} to look at';
  }

  Future<void> _dispatch(
      WidgetRef ref,
      PlanItem item,
      DispositionAction action,
      ) async {
    try {
      await ref.read(dispositionControllerProvider.notifier).dispose(
        planItemId: item.id,
        action: action,
        prompted: true,
      );
    } catch (e) {
      // The row already animated out; if the write fails, the next
      // stream emission will restore the row. The disposition toast
      // surfaces nothing for the failure case here — we leave a
      // logged event and let the listener bring the row back.
    }
  }
}

class _BulkSkipRow extends ConsumerStatefulWidget {
  const _BulkSkipRow({required this.dayBucket, required this.items});

  final int dayBucket;
  final List<PlanItem> items;

  @override
  ConsumerState<_BulkSkipRow> createState() => _BulkSkipRowState();
}

class _BulkSkipRowState extends ConsumerState<_BulkSkipRow> {
  bool _busy = false;

  Future<void> _confirmAndSkip() async {
    if (_busy) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext _) => AlertDialog(
        title: const Text('Clean slate?'),
        content: const Text(
          'This skips every remaining item from this day. No penalty; '
              'engagement still counts.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Skip all'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(dispositionControllerProvider.notifier)
          .bulkSkip(widget.items.map((p) => p.id).toList(growable: false));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't skip all: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _dayLabel(int bucket) {
    final int today = DayBucket.today();
    if (bucket == today - 1) return 'yesterday';
    if (bucket == today - 2) return 'two days ago';
    final DateTime local = DayBucket.asDateTime(bucket).toLocal();
    return DateFormat.MMMd().format(local);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Skip everything from ${_dayLabel(widget.dayBucket)}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surfaceTertiary,
        borderRadius: AppSpacing.borderRadiusMedium,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _busy ? null : _confirmAndSkip,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  _busy
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  )
                      : const Icon(
                    Icons.layers_clear,
                    size: 18,
                    color: AppColors.iconMuted,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Skip everything from ${_dayLabel(widget.dayBucket)}',
                      style: AppTypography.body,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}