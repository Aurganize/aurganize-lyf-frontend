import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/floating_island.dart';
import '../../capture/providers/capture_providers.dart';

class LandingIslandHost extends ConsumerWidget {
  const LandingIslandHost({
    super.key,
    required this.onExpand,
    required this.onVoiceCapture,
  });

  final VoidCallback onExpand;
  final VoidCallback onVoiceCapture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PendingCard>> pending =
    ref.watch(pendingCardsProvider);

    final (IslandLabelMode mode, int cardCount) =
    pending.maybeWhen<(IslandLabelMode, int)>(
      data: (List<PendingCard> cards) => cards.isEmpty
          ? (IslandLabelMode.capturePrompt, 0)
          : (IslandLabelMode.cardsReady, cards.length),
      orElse: () => (IslandLabelMode.capturePrompt, 0),
    );

    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.xxl,
      ),
      child: Center(
        child: FloatingIsland(
          mode: mode,
          cardCount: cardCount,
          onExpand: onExpand,
          onVoiceCapture: onVoiceCapture,
        ),
      ),
    );
  }
}