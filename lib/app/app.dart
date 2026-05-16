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

class AurganizeLyfApp extends StatelessWidget {
  const AurganizeLyfApp({super.key});

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
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aurganize Lyf',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.surfacePrimary,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F6E56),
            brightness: Brightness.light,
        ),
      ),
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
          ],
      ),
    );
  }
}

//
// class _ThemePreviewScreen extends StatelessWidget {
//   const _ThemePreviewScreen._();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Aurganize Lyf'),),
//       body: SafeArea(
//           child: ListView(
//             padding: const EdgeInsets.all(16),
//             children: <Widget>[
//               Text('Title - screen titles', style: AppTypography.title,),
//               const SizedBox(height: 16,),
//               Text(
//                 'Body - workhorse. The theme is now wired. Buttons, sheets,'
//                 'snackbars, and inputs will inherit the design system'
//                 'automatically',
//                 style: AppTypography.body,
//               ),
//               const SizedBox(height: 24,),
//               FilledButton(
//                   onPressed: () {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Marked done')),
//                     );
//                   },
//                   child: const Text('Primary button'),
//               ),
//               const SizedBox(height: 12,),
//               OutlinedButton(
//                   onPressed: () {
//                     //
//                   },
//                   child: const Text('Secondary Button'),
//               ),
//               const SizedBox(height: 12,),
//               TextButton(
//                   onPressed: () {},
//                   child: const Text('Tertiary Button'),
//               ),
//               const SizedBox(height: 24,),
//               TextField(
//                 decoration: const InputDecoration(
//                   hintText: 'Capture an intention...',
//                 ),
//                 style: AppTypography.body,
//               ),
//               const SizedBox(height: 24,),
//               Container(
//                 decoration: BoxDecoration(
//                   color: AppColors.surfacePrimary,
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(color: AppColors.borderDefault, width: 0.5),
//                 ),
//                 padding: const EdgeInsets.all(16),
//                 child: Text(
//                   'A surface-secondary card with a default border. The "you '
//                   'typed" quote block on the confirmation card deatil users'
//                   'this same treatment',
//                   style: AppTypography.body,
//                 ),
//               ),
//             ],
//           ),
//       ),
//     );
//   }
// }




//
// class _TypeScaleStream extends StatelessWidget {
//   const _TypeScaleStream();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.surfacePrimary,
//       body: SafeArea(
//           child: ListView(
//             padding: const EdgeInsets.all(16),
//             children: <Widget>[
//               Text('Aurganize Lyf', style: AppTypography.display,),
//               const SizedBox(height: 24,),
//               Text('Title - 22/28/500', style: AppTypography.title,),
//               const SizedBox(height: 16,),
//               Text('Heading - 17/24/500', style: AppTypography.heading,),
//               const SizedBox(height: 16,),
//               Text(
//                 'Body - 14/20/400. This is the workhorse text style used for'
//                 'plan item titles, conversation bubbles, and primary body.',
//                 style: AppTypography.body,
//               ),
//               const SizedBox(height: 16,),
//               Text(
//                 'Body 2 - 13/18/400. Used for notification body and settings rows.',
//                 style: AppTypography.body2,
//               ),
//               const SizedBox(height: 16,),
//               Text(
//                 'Caption - 11/15/400. Sub-labels and helper text.',
//                 style: AppTypography.caption,
//               ),
//               const SizedBox(height: 16,),
//               Text(
//                 'EYEBROW - 10/14/500 +0.5 SP',
//                 style: AppTypography.eyebrow,
//               ),
//               const SizedBox(height: 24,),
//               const Divider(),
//               const SizedBox(height: 24,),
//               Text(
//                 'bodyMuted variant - used for brand-colored action labels.',
//                 style: AppTypography.bodyMuted,
//               ),
//               const SizedBox(height: 8,),
//               Text(
//                 'bodyBrand variant - used for brand-colored action labels.',
//                 style: AppTypography.bodyBrand,
//               ),
//               const SizedBox(height: 8,),
//               Container(
//                 color: AppColors.brandPrimary,
//                 padding: const EdgeInsets.all(8),
//                 child: Text(
//                   'bodyOnBrand - used on brand-filled surfaces like the floating island.',
//                   style: AppTypography.bodyOnBrand,
//                 ),
//               ),
//               const SizedBox(height: 8,),
//               Text(
//                 'bodyStrikethrough - used on completed children in the project view',
//                 style: AppTypography.bodyStrikethrough,
//               ),
//             ],
//           ),
//       ),
//     );
//   }
// }



//
// class _ColorPaletteScreen extends StatelessWidget {
//   const _ColorPaletteScreen();
//
//   @override
//   Widget build(BuildContext context) {
//     final List<_Swatch> swatches = <_Swatch>[
//       const _Swatch('brand.primary', AppColors.brandPrimary, AppColors.surfacePrimary),
//       const _Swatch('brand.dark', AppColors.brandDark, AppColors.surfacePrimary),
//       const _Swatch('brand.light', AppColors.brandLight, AppColors.textPrimary),
//       const _Swatch('surface.primary', AppColors.surfacePrimary, AppColors.textPrimary),
//       const _Swatch('surface.secondary', AppColors.surfaceSecondary, AppColors.textPrimary),
//       const _Swatch('surface.tertiary', AppColors.surfaceTertiary, AppColors.textPrimary),
//       const _Swatch('text.primary', AppColors.textPrimary, AppColors.surfacePrimary),
//       const _Swatch('text.secondary', AppColors.textSecondary, AppColors.surfacePrimary),
//       const _Swatch('text.tertiary', AppColors.textTertiary, AppColors.surfacePrimary),
//       const _Swatch('border.default', AppColors.borderDefault, AppColors.textPrimary),
//       const _Swatch('border.strong', AppColors.borderStrong, AppColors.textPrimary),
//       const _Swatch('temp.hot', AppColors.tempHot, AppColors.surfacePrimary),
//       const _Swatch('temp.warm', AppColors.tempWarm, AppColors.surfacePrimary),
//       const _Swatch('temp.cool', AppColors.tempCool, AppColors.surfacePrimary),
//       const _Swatch('attention.coral.bg', AppColors.attentionCoralBackground, AppColors.attentionCoralForeground),
//       const _Swatch('attention.amber.bg', AppColors.attentionAmberBackground, AppColors.attentionAmberForeground)
//     ];
//
//     return Scaffold(
//       backgroundColor: AppColors.surfacePrimary,
//       appBar: AppBar(
//         title: const Text('Color tokens'),
//         backgroundColor: AppColors.surfacePrimary,
//         foregroundColor: AppColors.textPrimary,
//         elevation: 0,
//       ),
//       body: ListView.separated(
//         padding: const EdgeInsets.all(16),
//         itemCount: swatches.length,
//         separatorBuilder: (_,__) => const SizedBox(height: 8,),
//         itemBuilder: (BuildContext context, int index) {
//           final _Swatch s =swatches[index];
//           return Container(
//             height: 56,
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             decoration: BoxDecoration(
//               color: s.color,
//               borderRadius:  BorderRadius.circular(10),
//               border: Border.all(color: AppColors.borderDefault, width: 0.5),
//             ),
//             alignment: Alignment.centerLeft,
//             child: Text(
//               s.label,
//               style: TextStyle(
//                 color: s.textOn,
//                 fontWeight: FontWeight.w500
//               ),
//             ),
//           );
//         },
//     ),
//     );
//   }
// }
//
//
//
//
//
// class _Swatch {
//   const _Swatch(this.label, this.color, this.textOn);
//   final String label;
//   final Color color;
//   final Color textOn;
// }

// class _BootStrapScreen extends StatelessWidget {
//   const _BootStrapScreen();
//
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: SafeArea(
//           child: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: <Widget>[
//                 Text(
//                   'Aurganize Lyf',
//                   style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'Bootstrap Ok.',
//                   style: TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
//                 ),
//               ],
//             ),
//           ),
//       ),
//     );
//   }
// }

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