import 'package:aurganize_lyf/core/extensions/context_extensions.dart';
import 'package:aurganize_lyf/core/theme/app_colors.dart';
import 'package:aurganize_lyf/core/theme/app_spacing.dart';
import 'package:aurganize_lyf/core/theme/app_typography.dart';
import 'package:aurganize_lyf/domain/enums/plan_item_state.dart';
import 'package:aurganize_lyf/domain/enums/temperature.dart';
import 'package:aurganize_lyf/domain/models/confidence.dart';
import 'package:aurganize_lyf/features/capture/presentation/parsed_card_view_model.dart';
import 'package:aurganize_lyf/features/dev_gallery/dev_gallery_screen.dart';
import 'package:aurganize_lyf/features/disposition/presentation/disposition_action.dart';
import 'package:aurganize_lyf/features/disposition/presentation/disposition_copy.dart';
import 'package:aurganize_lyf/features/disposition/presentation/show_disposition_sheet.dart';
import 'package:aurganize_lyf/shared/widgets/confidence_chip.dart';
import 'package:aurganize_lyf/shared/widgets/confirmation_detail_view.dart';
import 'package:aurganize_lyf/shared/widgets/confirmation_peek_card.dart';
import 'package:aurganize_lyf/shared/widgets/date_train.dart';
import 'package:aurganize_lyf/shared/widgets/day_tile.dart';
import 'package:aurganize_lyf/shared/widgets/disposition_button.dart';
import 'package:aurganize_lyf/shared/widgets/disposition_sheet_content.dart';
import 'package:aurganize_lyf/shared/widgets/floating_island.dart';
import 'package:aurganize_lyf/shared/widgets/plan_item_row.dart';
import 'package:aurganize_lyf/shared/widgets/temperature_dot.dart';
import 'package:flutter/material.dart';
import 'package:aurganize_lyf/features/dev_gallery/dev_gallery_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/extensions/datetime_extensions.dart';
import '../core/theme/app_theme.dart';
import 'package:aurganize_lyf/features/capture/providers/parse_worker.dart';
import '../domain/enums/capture_source.dart';
import '../domain/models/plan_item.dart';
import '../features/capture/providers/capture_controller.dart';
import '../features/capture/providers/capture_providers.dart';
import '../features/disposition/providers/disposition_controller.dart';
import '../features/disposition/providers/disposition_toast.dart';
import '../features/disposition/providers/question_rotator.dart';
import '../features/landing/landing_screen.dart';
import '../features/landing/widgets/conversation_stage.dart';
import '../features/onboarding/onboarding_providers.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/plan/providers/date_train_provider.dart';
import '/features/auth/auth_providers.dart';

class AurganizeLyfApp extends ConsumerStatefulWidget {
  const AurganizeLyfApp({super.key});

  @override
  ConsumerState<AurganizeLyfApp> createState() => _AurganizeLyfAppState();
}

class _AurganizeLyfAppState extends ConsumerState<AurganizeLyfApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(parseWorkerProvider.notifier).ensureRunning();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<bool> onboarded = ref.watch(onboardingCompletedProvider);

    return MaterialApp(
      title: 'Aurganize lyf',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: onboarded.when(
        loading: () => const _LaunchSplash(),
        error: (Object _, __) => const _LaunchSplash(),
        data: (bool done) => done
            ? Consumer(
          builder: (BuildContext context, WidgetRef ref, _) {
            return LandingScreen(
              onOpenPlanItem: (PlanItem item) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Detail for ${item.title}')),
                );
              },
              onOpenSettings: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings — Phase 06')),
                );
              },
              // Now the island calls into the stage controller.
              onExpandIsland: () {
                ref
                    .read(conversationStageProvider.notifier)
                    .expand();
              },
              onVoiceCapture: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Voice capture — Phase 07')),
                );
              },
            );
          },
        )
            : OnboardingScreen(
          onGetStarted: () {
            // No-op for now — onboardingCompletedProvider flipping
            // is what causes the `data` arm above to swap to the
            // gallery. We could call `setState` for safety but it's
            // not needed: the AsyncValue change triggers a rebuild.
          },
        ),
      ),
    );
  }
}


class _LaunchSplash extends StatelessWidget {
  const _LaunchSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}


class _TemperatureDotsRow extends StatelessWidget {
  const _TemperatureDotsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        _LabeledDot(temperature: Temperature.hot, label: 'hot'),
        _LabeledDot(temperature: Temperature.warm, label: 'warm'),
        _LabeledDot(temperature: Temperature.cool, label: 'cool'),
      ],
    );
  }
}

class _LabeledDot extends StatelessWidget {
  const _LabeledDot({required this.temperature, required this.label});
  final Temperature temperature;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TemperatureDot(temperature: temperature),
        const SizedBox(height: 8),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}



class _CurrentUserIdDisplay extends ConsumerWidget {
  const _CurrentUserIdDisplay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<String> asyncId = ref.watch(currentUserIdProvider);
    return asyncId.when(
      loading: () => const Text('Resolving user…',
          style: TextStyle(color: AppColors.textTertiary)),
      error: (Object error, StackTrace stack) => Text(
        'Failed: $error',
        style: AppTypography.body.copyWith(color: AppColors.tempHot),
      ),
      data: (String id) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('User id', style: AppTypography.caption),
          const SizedBox(height: 4),
          SelectableText(id, style: AppTypography.body),
        ],
      ),
    );
  }
}

class _CaptureDevSection extends ConsumerStatefulWidget {
  const _CaptureDevSection();

  @override
  ConsumerState<_CaptureDevSection> createState() => _CaptureDevSectionState();
}

class _CaptureDevSectionState extends ConsumerState<_CaptureDevSection> {
  final TextEditingController _controller = TextEditingController(
    text: 'pick up dry cleaning before friday and call mom sometime',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingCardsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          controller: _controller,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Type a capture...',
          ),
          style: AppTypography.body,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            FilledButton(
              onPressed: () async {
                try {
                  await ref
                      .read(captureControllerProvider.notifier)
                      .submit(
                    rawText: _controller.text,
                    source: CaptureSource.typed,
                  );
                  if (mounted) _controller.clear();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Capture failed: $e')),
                    );
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Pending cards', style: AppTypography.eyebrow),
        const SizedBox(height: AppSpacing.sm),
        pending.when(
          loading: () => const Text('Listening…',
              style: TextStyle(color: AppColors.textTertiary)),
          error: (Object e, _) => Text('Error: $e',
              style: AppTypography.body.copyWith(color: AppColors.tempHot)),
          data: (List<PendingCard> cards) {
            if (cards.isEmpty) {
              return const Text('No pending cards.',
                  style: TextStyle(color: AppColors.textTertiary));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final PendingCard c in cards.take(5))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '• ${c.planItem.title} '
                          '(${c.planItem.type.name}, ${c.planItem.temperature.name})',
                      style: AppTypography.body,
                    ),
                  ),
                if (cards.length > 5)
                  Text('+${cards.length - 5} more',
                      style: AppTypography.bodyMuted),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LiveDateTrain extends ConsumerWidget {
  const _LiveDateTrain();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(dateTrainEntriesProvider);
    return entries.when(
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object e, _) => Text('Error: $e',
          style: AppTypography.body.copyWith(color: AppColors.tempHot)),
      data: (List<DateTrainEntry> e) => DateTrain(
        entries: e,
        onTap: (DateTime date) {
          ref
              .read(selectedDayProvider.notifier)
              .select(date.utcDayBucket);
        },
      ),
    );
  }
}

class _DispositionDevSection extends ConsumerWidget {
  const _DispositionDevSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the toast so we can show snackbars when it fires.
    ref.listen<DispositionToast?>(
      dispositionToastsProvider,
          (DispositionToast? prev, DispositionToast? curr) {
        if (curr == null || curr == prev) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(curr.message)),
        );
        ref.read(dispositionToastsProvider.notifier).clear();
      },
    );

    final pending = ref.watch(pendingCardsProvider);
    return pending.when(
      loading: () => const Text('Loading…'),
      error: (Object e, _) => Text('Error: $e',
          style: AppTypography.body.copyWith(color: AppColors.tempHot)),
      data: (List<PendingCard> cards) {
        if (cards.isEmpty) {
          return const Text(
            'No pending items. Submit a capture above first.',
            style: TextStyle(color: AppColors.textTertiary),
          );
        }
        final PendingCard first = cards.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'First pending item: ${first.planItem.title}',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () async {
                final question = ref
                    .read(questionRotatorProvider.notifier)
                    .questionFor(first.planItem.title);
                final DispositionAction? choice =
                await showDispositionSheet(
                  context: context,
                  question: question,
                );
                if (choice == null) return;
                await ref
                    .read(dispositionControllerProvider.notifier)
                    .dispose(
                  planItemId: first.planItem.id,
                  action: choice,
                  prompted: true,
                );
              },
              child: const Text('Disposition the first pending item'),
            ),
          ],
        );
      },
    );
  }
}

