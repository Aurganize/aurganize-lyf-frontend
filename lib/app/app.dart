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
import '../features/capture/providers/capture_controller.dart';
import '../features/capture/providers/capture_providers.dart';
import '../features/disposition/providers/disposition_controller.dart';
import '../features/disposition/providers/disposition_toast.dart';
import '../features/disposition/providers/question_rotator.dart';
import '../features/plan/providers/date_train_provider.dart';
import '/features/auth/auth_providers.dart';

class AurganizeLyfApp extends ConsumerStatefulWidget {
  const AurganizeLyfApp({super.key});

  @override
  ConsumerState<AurganizeLyfApp> createState() => _AurganizeLyfAppState();
}

class _AurganizeLyfAppState extends ConsumerState<AurganizeLyfApp> {

  final ParsedCardViewModel _sampleViewModel = const ParsedCardViewModel(
    planItemId: 'sample',
    rawText: "pick up the dry cleaning before friday and call mom sometime",
    title: 'Pick up the dry cleaning',
    titleConfidence: Confidence(0.92),
    attributes: <ParsedAttribute>[
      ParsedAttribute(
        key: 'type',
        label: 'Type',
        displayValue: 'Errand',
        confidence: Confidence(0.95),
        icon: Icons.shopping_bag_outlined,
      ),
      ParsedAttribute(
        key: 'time',
        label: 'When',
        displayValue: 'This week',
        confidence: const Confidence(0.6), // tentative
        icon: Icons.calendar_today_outlined,
      ),
     ParsedAttribute(
        key: 'recurrence',
        label: 'Recurrence',
        displayValue: 'One-off',
        confidence: const Confidence(0.92),
        icon: Icons.refresh,
      ),
      ParsedAttribute(
        key: 'parent',
        label: 'Parent',
        displayValue: 'No parent',
        confidence: Confidence.certain,
        icon: Icons.account_tree_outlined,
      ),
      ParsedAttribute(
        key: 'temperature',
        label: 'Temperature',
        displayValue: 'Warm',
        confidence: const Confidence(0.88),
        icon: Icons.thermostat_outlined,
      ),
    ],
  );


  @override
  void initState() {
    super.initState();
    // Start the parsing loop. Idempotent — safe even on hot-reload.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(parseWorkerProvider.notifier).ensureRunning();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aurganize Lyf',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: DevGalleryScreen(
          sections:<DevGallerySection>[
            const DevGallerySection(
              title: 'Temperature dot',
              description:
              '7px circle that appears left of every plan item title. Never used elsewhere.',
              child: _TemperatureDotsRow(),
            ),
            DevGallerySection(
              title: 'Day tile — states',
              description:
              'Focused (today, brand fill), default (bordered), dim (faded, no border).',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  DayTile(
                    weekdayLabel: 'TUE',
                    dayOfMonth: 16,
                    state: DayTileState.focused,
                    pill: const DayTilePill.total(count: 4),
                    fullDateForA11y: 'Tuesday, May 16, 2026',
                    onTap: () {},
                  ),
                  DayTile(
                    weekdayLabel: 'WED',
                    dayOfMonth: 17,
                    state: DayTileState.defaultState,
                    fullDateForA11y: 'Wednesday, May 17, 2026',
                    onTap: () {},
                  ),
                  DayTile(
                    weekdayLabel: 'THU',
                    dayOfMonth: 18,
                    state: DayTileState.dim,
                    fullDateForA11y: 'Thursday, May 18, 2026',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            DevGallerySection(
              title: 'Day tile — leftover pills',
              description:
              'Amber for yesterday, coral for older. Both communicate "your attention would help here" — never red.',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  DayTile(
                    weekdayLabel: 'SUN',
                    dayOfMonth: 11,
                    state: DayTileState.defaultState,
                    pill: const DayTilePill.leftover(count: 5, olderThanYesterday: true),
                    fullDateForA11y: 'Sunday, May 11, 2026',
                    onTap: () {},
                  ),
                  DayTile(
                    weekdayLabel: 'MON',
                    dayOfMonth: 15,
                    state: DayTileState.defaultState,
                    pill: const DayTilePill.leftover(count: 2, olderThanYesterday: false),
                    fullDateForA11y: 'Monday, May 15, 2026',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            DevGallerySection(
              title: 'Date train',
              description:
              'Horizontally scrollable strip. Today is anchored at 1/4 from the left; past days with leftovers carry amber/coral pills.',
              child: DateTrain(
                entries: <DateTrainEntry>[
                  DateTrainEntry(
                    date: DateTime.utc(2026, 5, 11),
                    weekdayLabel: 'SUN',
                    fullDateForA11y: 'Sunday, May 11, 2026',
                    state: DayTileState.defaultState,
                    pill: const DayTilePill.leftover(count: 3, olderThanYesterday: true),
                  ),
                  DateTrainEntry(
                    date: DateTime.utc(2026, 5, 12),
                    weekdayLabel: 'MON',
                    fullDateForA11y: 'Monday, May 12, 2026',
                    state: DayTileState.defaultState,
                  ),
                  DateTrainEntry(
                    date: DateTime.utc(2026, 5, 15),
                    weekdayLabel: 'MON',
                    fullDateForA11y: 'Monday, May 15, 2026',
                    state: DayTileState.defaultState,
                    pill: const DayTilePill.leftover(count: 2, olderThanYesterday: false),
                  ),
                  DateTrainEntry(
                    date: DateTime.utc(2026, 5, 16),
                    weekdayLabel: 'TUE',
                    fullDateForA11y: 'Tuesday, May 16, 2026',
                    state: DayTileState.focused,
                    pill: const DayTilePill.total(count: 4),
                  ),
                  DateTrainEntry(
                    date: DateTime.utc(2026, 5, 17),
                    weekdayLabel: 'WED',
                    fullDateForA11y: 'Wednesday, May 17, 2026',
                    state: DayTileState.defaultState,
                  ),
                  DateTrainEntry(
                    date: DateTime.utc(2026, 5, 18),
                    weekdayLabel: 'THU',
                    fullDateForA11y: 'Thursday, May 18, 2026',
                    state: DayTileState.dim,
                  ),
                  DateTrainEntry(
                    date: DateTime.utc(2026, 5, 19),
                    weekdayLabel: 'FRI',
                    fullDateForA11y: 'Friday, May 19, 2026',
                    state: DayTileState.dim,
                  ),
                ],
                onTap: (DateTime _) {},
              ),
            ),
            DevGallerySection(
              title: 'Confidence chip — states',
              description:
              'Confirmed: solid fill, dark text. Tentative: dashed border, lighter text — "tap to confirm or change". Selected: brand-light fill, brand-dark text — actively being edited.',
              child: Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: <Widget>[
                  ConfidenceChip(
                    label: 'Errand',
                    leadingIcon: Icons.shopping_bag_outlined,
                    state: ConfidenceChipState.confirmed,
                    onTap: () {},
                  ),
                  ConfidenceChip(
                    label: 'This week',
                    leadingIcon: Icons.calendar_today_outlined,
                    state: ConfidenceChipState.tentative,
                    onTap: () {},
                  ),
                  ConfidenceChip(
                    label: 'Weekly',
                    leadingIcon: Icons.refresh,
                    state: ConfidenceChipState.selected,
                    onTap: () {},
                  ),
                  ConfidenceChip(
                    label: 'No parent',
                    state: ConfidenceChipState.confirmed,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            DevGallerySection(
              title: 'Plan item row — states',
              description:
              'Default (planned/in-progress), done (strikethrough title, brand check), skipped (muted title, no check). Tapping the title fires onTap; tapping the check fires the disposition prompt.',
              child: Column(
                children: <Widget>[
                  PlanItemRow(
                    title: 'Pick up the dry cleaning',
                    temperature: Temperature.warm,
                    state: PlanItemState.planned,
                    timeHint: 'this week',
                    onTap: () {},
                    onDispositionTap: () {},
                  ),
                  PlanItemRow(
                    title: 'Take BP medication',
                    temperature: Temperature.hot,
                    state: PlanItemState.planned,
                    timeHint: '9:00 AM · daily',
                    onTap: () {},
                    onDispositionTap: () {},
                  ),
                  PlanItemRow(
                    title: 'Call mom',
                    temperature: Temperature.cool,
                    state: PlanItemState.done,
                    timeHint: 'whenever',
                    onTap: () {},
                    onDispositionTap: () {},
                  ),
                  PlanItemRow(
                    title: 'Re-read the lease',
                    temperature: Temperature.cool,
                    state: PlanItemState.skipped,
                    timeHint: 'this week',
                    onTap: () {},
                    onDispositionTap: () {},
                    showDivider: false,
                  ),
                ],
              ),
            ),
            DevGallerySection(
              title: 'Floating island — capture prompt',
              description:
              'Default state. "What\'s on your mind?". Tapping the body fires onExpand; tapping the mic fires onVoiceCapture.',
              child: Center(
                child: FloatingIsland(
                  mode: IslandLabelMode.capturePrompt,
                  onExpand: () {},
                  onVoiceCapture: () {},
                ),
              ),
            ),
            DevGallerySection(
              title: 'Floating island — saved, parsing',
              description:
              'Brief state shown right after capture. The body opacity pulses to communicate background work; the label transitions automatically when parsing finishes.',
              child: Center(
                child: FloatingIsland(
                  mode: IslandLabelMode.savedParsing,
                  onExpand: () {},
                  onVoiceCapture: () {},
                ),
              ),
            ),
            DevGallerySection(
              title: 'Floating island — cards ready',
              description:
              'Cards are waiting in the conversation. Singular form when count is 1, plural otherwise.',
              child: Column(
                children: <Widget>[
                  Center(
                    child: FloatingIsland(
                      mode: IslandLabelMode.cardsReady,
                      cardCount: 1,
                      onExpand: () {},
                      onVoiceCapture: () {},
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: FloatingIsland(
                      mode: IslandLabelMode.cardsReady,
                      cardCount: 3,
                      onExpand: () {},
                      onVoiceCapture: () {},
                    ),
                  ),
                ],
              ),
            ),
            DevGallerySection(
              title: 'Confirmation peek card',
              description:
              'Docks above the floating island after parsing. Tappable body opens the detail view; chips open inline editors; "Add to plan" commits; "x" dismisses while keeping raw text.',
              child: ConfirmationPeekCard(
                viewModel: _sampleViewModel,
                onConfirm: () {},
                onExpand: () {},
                onChipTap: (ParsedAttribute _) {},
                onDismiss: () {},
              ),
            ),
            DevGallerySection(
              title: 'Confirmation detail view',
              description:
              'Full-screen view with the raw text quoted at the top, each inferred attribute on its own editable row. Push this button to view it.',
              child: Center(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => ConfirmationDetailView(
                          viewModel: _sampleViewModel,
                          onClose: () => Navigator.of(context).pop(),
                          onEditTitle: () {},
                          onEditAttribute: (ParsedAttribute _) {},
                          onConfirm: () => Navigator.of(context).pop(),
                          onDismiss: () => Navigator.of(context).pop(),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open detail view'),
                ),
              ),
            ),
            DevGallerySection(
              title: 'Disposition button — single row',
              description:
              'The 48-px row used inside the disposition sheet. Brand-colored icon and label anchor the row; muted sub-explanation and chevron close it.',
              child: DispositionButton(
                icon: Icons.check,
                label: DispositionCopy.doneLabel,
                subExplanation: DispositionCopy.doneSub,
                onTap: () {},
              ),
            ),
            DevGallerySection(
              title: 'Disposition prompt — full sheet (in place)',
              description:
              'Inline render of the sheet body so you can see the relationships without dismissing. The real sheet is shown via showModalBottomSheet — tap below to trigger it.',
              child: Column(
                children: <Widget>[
                  DispositionSheetContent(
                    question: 'Still planning to pick up the dry cleaning?',
                    onAction: (DispositionAction _) {},
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: FilledButton(
                      onPressed: () async {
                        final DispositionAction? result = await showDispositionSheet(
                          context: context,
                          question: DispositionCopy.composeQuestion(
                            'pick up the dry cleaning',
                            seed: 0,
                          ),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                              result == null
                                  ? 'Sheet dismissed — no change'
                                  : 'You chose: ${result.name}',
                            ),
                          ));
                        }
                      },
                      child: const Text('Open the real sheet'),
                    ),
                  ),
                ],
              ),
            ),
            const DevGallerySection(
              title: 'End-to-end capture',
              description:
              'Submit a real capture and watch the parse worker turn it into plan items. The "Pending cards" count below updates within ~1 second of parsing finishing.',
              child: _CaptureDevSection(),
            ),
            const DevGallerySection(
              title: 'Live date train',
              description:
              'The real date train, fed by dateTrainEntriesProvider. Submit captures above to see today\'s count increment; tap a past day to focus it.',
              child: _LiveDateTrain(),
            ),
            const DevGallerySection(
              title: 'End-to-end disposition',
              description:
              'Submit a capture above, then tap "Disposition the first pending item" to open the real sheet. The toast at the top of the screen reports the outcome.',
              child: _DispositionDevSection(),
            ),
          ],
      ),
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