import 'dart:async';

import 'package:aurganize_lyf/app/app.dart';
import 'package:aurganize_lyf/features/landing/widgets/conversation_history.dart';
import 'package:aurganize_lyf/features/landing/widgets/conversation_input_bar.dart';
import 'package:aurganize_lyf/features/landing/widgets/conversation_stage.dart';
import 'package:aurganize_lyf/features/landing/widgets/landing_app_header.dart';
import 'package:aurganize_lyf/features/landing/widgets/peek_card_stack.dart';
import 'package:aurganize_lyf/features/landing/widgets/voice_capture_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/extensions/datetime_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/enums/capture_source.dart';
import '../../domain/models/plan_item.dart';
import '../../shared/widgets/date_train.dart';
import '../capture/providers/capture_controller.dart';
import '../capture/providers/capture_providers.dart';
import '../capture/providers/conversation_input.dart';
import '../capture/services/voice_capture_service.dart';
import '../disposition/providers/disposition_toast.dart';
import '../plan/providers/date_train_provider.dart';
import '../plan/providers/items_for_date_provider.dart';
import 'widgets/landing_app_header.dart';
import 'widgets/landing_island_host.dart';
import 'widgets/today_peek.dart';

/// The landing screen — PDD §13 default state.
///
/// Composes:
///   - [LandingAppHeader]
///   - The live [DateTrain] from [dateTrainEntriesProvider]
///   - The [TodayPeek] for the currently-selected day
///   - The [LandingIslandHost] at the bottom
///
/// Listens to [dispositionToastsProvider] and surfaces each toast as
/// a snackbar, then clears it.
class LandingScreen extends ConsumerWidget {
  const LandingScreen({
    super.key,
    required this.onOpenPlanItem,
    required this.onOpenSettings,
    required this.onExpandIsland,
    required this.onVoiceCapture,
  });

  final void Function(PlanItem item) onOpenPlanItem;
  final VoidCallback onOpenSettings;
  final VoidCallback onExpandIsland;
  final VoidCallback onVoiceCapture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wire toast handling at the screen level so a single point handles
    // every disposition origin (peek rows, leftover view, detail).
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

    final int selectedDay = ref.watch(selectedDayProvider);
    final AsyncValue<List<DateTrainEntry>> trainEntries =
    ref.watch(dateTrainEntriesProvider);

    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      body: ConversationStageShell(
          panelBody: const _ConversationPanelBody(),
          planContent: SafeArea(
            bottom: false, // the island handles its own bottom safe area
            child: Stack(
              children: <Widget>[
                // Layered content — header, date train, peek — and an
                // intentionally large Spacer that lets the canvas breathe.
                Positioned.fill(
                  child: Column(
                    children: <Widget>[
                      LandingAppHeader(
                        streak: 0, // placeholder until Phase 10
                        onStreakTap: () {
                          ref
                              .read(selectedDayProvider.notifier)
                              .resetToToday();
                        },
                        onMenuTap: onOpenSettings,
                      ),
                      trainEntries.when(
                        loading: () => const _DateTrainSkeleton(),
                        error: (Object e, _) =>
                            _DateTrainError(error: e),
                        data: (List<DateTrainEntry> e) => DateTrain(
                          entries: e,
                          onTap: (DateTime date) {
                            final int bucket = date.utcDayBucket;
                            final int today = DayBucket.today();
                            if (bucket < today) {
                              // Past-day tap → leftover view.
                              GoRouter.of(context).pushNamed(
                                'leftover',
                                pathParameters: <String, String>{
                                  'bucket': bucket.toString(),
                                },
                              );
                            } else {
                              // Today / future tap → swap focus.
                              ref.read(selectedDayProvider.notifier).select(bucket);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TodayPeek(
                        dayBucket: selectedDay,
                        onRowTap: onOpenPlanItem,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                // ── Peek stack docked above the island ─────────────────────────────
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: AppSpacing.xxl + AppSpacing.floatingIslandHeight + AppSpacing.lg,
                  child: Consumer(builder: (BuildContext context, WidgetRef ref, _) {
                    final pending = ref.watch(pendingCardsProvider);
                    return pending.maybeWhen(
                      data: (List<PendingCard> cards) {
                        if (cards.isEmpty) return const SizedBox.shrink();
                        return PeekCardStack(
                          cards: cards,
                          onOpen: (PendingCard card) {
                            GoRouter.of(context).pushNamed(
                              'confirm',
                              pathParameters: <String, String>{
                                'planItemId': card.planItem.id,
                              },
                            );
                          },
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    );
                  }),
                ),

                // The island floats over the canvas.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LandingIslandHost(
                    onExpand: onExpandIsland,
                    onVoiceCapture: onVoiceCapture,
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date-train placeholders
// ─────────────────────────────────────────────────────────────────────────────

class _DateTrainSkeleton extends StatelessWidget {
  const _DateTrainSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: AppSpacing.dayTileHeight + 8,
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      ),
    );
  }
}

class _DateTrainError extends StatelessWidget {
  const _DateTrainError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(
        'Couldn\'t load the date train. $error',
        style: AppTypography.bodyMuted,
      ),
    );
  }
}

//
// class _ConversationPanelPlaceholder extends StatelessWidget {
//   const _ConversationPanelPlaceholder();
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: <Widget>[
//         // Chat history area — Phase 07 Part 03 fills this with bubbles.
//         Expanded(
//           child: Padding(
//             padding: const EdgeInsets.all(AppSpacing.lg),
//             child: Center(
//               child: Text(
//                 'Chat history lands here in Phase 07 Part 03.',
//                 style: AppTypography.bodyMuted,
//                 textAlign: TextAlign.center,
//               ),
//             ),
//           ),
//         ),
//         // The real input bar — replaces the (typing area) placeholder.
//         ConversationInputBar(
//           autofocus: true,
//           onVoiceCapture: () {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Voice capture — Phase 07 Part 02'),
//               ),
//             );
//           },
//           onError: (Object error) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text("Couldn't save: $error")),
//             );
//           },
//         ),
//       ],
//     );
//   }
// }

class _ConversationComposer extends ConsumerStatefulWidget {
  const _ConversationComposer();

  @override
  ConsumerState<_ConversationComposer> createState() =>
      _ConversationComposerState();
}

class _ConversationComposerState
    extends ConsumerState<_ConversationComposer> {

  final TextEditingController _controller =
  TextEditingController();

  bool _submitting = false;

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _submitting) return;

    setState(() => _submitting = true);

    try {
      await ref.read(captureControllerProvider.notifier).submit(
        rawText: text,
        source: CaptureSource.typed,
      );

      _controller.clear();
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: 'Type a message...',
              filled: true,
            ),
          ),
        ),
        IconButton(
          onPressed: _submit,
          icon: const Icon(Icons.send),
        ),
      ],
    );
  }
}


class _ConversationPanelBody extends ConsumerStatefulWidget {
  const _ConversationPanelBody();

  @override
  ConsumerState<_ConversationPanelBody> createState() =>
      _ConversationPanelBodyState();
}

class _ConversationPanelBodyState
    extends ConsumerState<_ConversationPanelBody> {
  StreamSubscription<VoiceResult>? _voiceSub;
  VoiceResult? _voice;

  bool get _listening => _voice?.state == VoiceState.listening;

  Future<void> _startVoice() async {
    if (_voiceSub != null) {
      await _stopVoice();
      return;
    }
    final stream = ref.read(voiceCaptureServiceProvider).start();
    _voiceSub = stream.listen(_onVoiceResult, onDone: _onVoiceDone);
  }

  void _onVoiceResult(VoiceResult r) {
    setState(() => _voice = r);
    if (r.state == VoiceState.failed) {
      _handleFailure(r.failure!);
    } else if (r.state == VoiceState.done) {
      // Push the final transcript into the draft, give focus to the field.
      ref
          .read(conversationInputProvider.notifier)
          .setDraft(r.text);
    }
  }

  void _onVoiceDone() {
    setState(() {
      _voiceSub = null;
      // Hold _voice briefly in `done` state to render the transcript;
      // cleared on the next setState/build cycle (when the user types
      // or hits send).
    });
  }

  Future<void> _stopVoice() async {
    await ref.read(voiceCaptureServiceProvider).stop();
  }

  Future<void> _handleFailure(VoiceFailureReason reason) async {
    if (!mounted) return;
    final String message = switch (reason) {
      VoiceFailureReason.permissionDenied =>
      'Voice capture needs microphone access.',
      VoiceFailureReason.permissionPermanentlyDenied =>
      'Mic access is off for this app. Enable it in Settings.',
      VoiceFailureReason.unavailable =>
      'Voice capture isn\'t available on this device.',
      VoiceFailureReason.recognitionFailed =>
      'Couldn\'t hear that — try again.',
      VoiceFailureReason.conflict =>
      'A new voice session started.',
    };
    if (reason == VoiceFailureReason.permissionPermanentlyDenied) {
      final bool? openSettings = await showDialog<bool>(
        context: context,
        builder: (BuildContext _) => AlertDialog(
          title: const Text('Microphone access is off'),
          content: const Text(
            'Aurganize lyf needs microphone access for voice capture. '
                'You can grant it in your device settings, or keep typing.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep typing'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      if (openSettings == true) {
        await openAppSettings();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
    setState(() => _voice = null);
  }

  @override
  void dispose() {
    _voiceSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: ConversationHistory(
            onOpenCard: (String planItemId) {
              // Routing the same way the peek-card stack does.
              GoRouter.of(context).pushNamed(
                'confirm',
                pathParameters: <String, String>{'planItemId': planItemId},
              );
            },
          ),
        ),
        if (_listening)
          VoiceCapturePanel(
            transcript: _voice?.text ?? '',
            onStop: _stopVoice,
          )
        else
          ConversationInputBar(
            autofocus: true,
            onVoiceCapture: _startVoice,
            onError: (Object error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Couldn't save: $error")),
              );
            },
          ),
      ],
    );
  }
}