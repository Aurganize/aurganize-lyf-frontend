import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/confidence.dart';
import '../../../domain/models/plan_item.dart';
import '../../../domain/enums/plan_item_type.dart';
import '../../../domain/enums/temperature.dart';
import '../../../domain/models/item_time.dart';
import '../../capture/presentation/parsed_card_view_model.dart';
import '../../capture/providers/capture_providers.dart';
import '../../capture/services/card_action_service.dart';
import '../../../shared/widgets/confirmation_peek_card.dart';

/// The stack of parsed-card peeks above the floating island — PDD §14.
///
/// Renders up to [maxVisible] cards, with cards 2 and 3 visibly offset
/// (vertically displaced, slightly smaller, partially obscured) so the
/// user perceives "there are more behind." Beyond that, the conversation
/// history (Phase 07) is the canonical place to see remaining cards.
///
/// Each card binds to a single [PendingCard]. Add-to-plan calls
/// [CardActionService.confirm]; dismiss calls [CardActionService.dismiss].
/// Tap on the card body fires [onOpen] which the host routes to the
/// detail view (Phase 06 Part 01 / routing in Part 05).
class PeekCardStack extends ConsumerWidget {
  const PeekCardStack({
    super.key,
    required this.cards,
    required this.onOpen,
    this.maxVisible = 3,
  });

  final List<PendingCard> cards;

  /// Called when the user taps the body of the top card to drill into
  /// the full confirmation detail.
  final void Function(PendingCard card) onOpen;

  final int maxVisible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cards.isEmpty) return const SizedBox.shrink();

    // Visible cards top-to-bottom: index 0 is the topmost. We render in
    // *reverse* z-order: lowest first, top last, so the top card draws
    // over the offset stack underneath.
    final List<PendingCard> visible = cards.take(maxVisible).toList();

    return SizedBox(
      // Pre-compute height so the Stack doesn't fight the column.
      // Each card has its own height; the offsets cumulate ~6 px each.
      // We allow ample vertical room and the Stack clips overflow.
      height: 180,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          for (int i = visible.length - 1; i >= 0; i--)
            _PositionedPeek(
              key: ValueKey<String>(visible[i].planItem.id),
              card: visible[i],
              depth: i, // 0 == topmost, larger == further back
              onConfirm: () async {
                await ref.read(cardActionServiceProvider).confirm(
                  planItemId: visible[i].planItem.id,
                );
              },
              onDismiss: () async {
                await ref.read(cardActionServiceProvider).dismiss(
                  planItemId: visible[i].planItem.id,
                  intentionId: visible[i].intention.id,
                );
              },
              onExpand: () => onOpen(visible[i]),
            ),
        ],
      ),
    );
  }
}

/// Internal: positions one peek card with the appropriate depth offset.
class _PositionedPeek extends StatelessWidget {
  const _PositionedPeek({
    super.key,
    required this.card,
    required this.depth,
    required this.onConfirm,
    required this.onDismiss,
    required this.onExpand,
  });

  final PendingCard card;
  final int depth;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;
  final VoidCallback onExpand;

  static const double _verticalOffsetPerDepth = 6;
  static const double _scalePerDepth = 0.04;

  @override
  Widget build(BuildContext context) {
    // Offset upward by `depth * 6` px so deeper cards peek above the top.
    // Scale down slightly so they read as "behind."
    final double dy = -depth * _verticalOffsetPerDepth;
    final double scale = 1 - depth * _scalePerDepth;

    return AnimatedPositioned(
      duration: AppMotion.effectiveStateChange(context),
      curve: AppMotion.stateChangeCurve,
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      bottom: dy.abs() + 0,
      child: AnimatedScale(
        duration: AppMotion.effectiveStateChange(context),
        curve: AppMotion.stateChangeCurve,
        scale: scale,
        alignment: Alignment.bottomCenter,
        // Reduce opacity slightly on stacked cards so they read as
        // visually backgrounded.
        child: Opacity(
          opacity: depth == 0 ? 1.0 : 0.85,
          child: ConfirmationPeekCard(
            viewModel: _viewModelFor(card),
            onConfirm: onConfirm,
            onExpand: onExpand,
            onChipTap: (_) => onExpand(),
            onDismiss: onDismiss,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan item → ParsedCardViewModel
// ─────────────────────────────────────────────────────────────────────────────

/// Adapts a [PendingCard] into the presentational [ParsedCardViewModel]
/// the peek widget expects. Pulled out so it's testable in isolation.
ParsedCardViewModel _viewModelFor(PendingCard card) {
  final PlanItem item = card.planItem;
  return ParsedCardViewModel(
    planItemId: item.id,
    rawText: card.intention.rawText,
    title: item.title,
    titleConfidence: item.confidenceFor('title'),
    attributes: <ParsedAttribute>[
      ParsedAttribute(
        key: 'type',
        label: 'Type',
        displayValue: _typeLabel(item.type),
        confidence: item.confidenceFor('type'),
        icon: _typeIcon(item.type),
      ),
      ParsedAttribute(
        key: 'time',
        label: 'When',
        displayValue: _timeLabel(item.time),
        confidence: item.confidenceFor('time'),
        icon: Icons.calendar_today_outlined,
      ),
      ParsedAttribute(
        key: 'temperature',
        label: 'Temperature',
        displayValue: _temperatureLabel(item.temperature),
        confidence: item.confidenceFor('temperature'),
        icon: Icons.thermostat_outlined,
      ),
    ],
  );
}

String _typeLabel(PlanItemType t) {
  return switch (t) {
    PlanItemType.task => 'Task',
    PlanItemType.errand => 'Errand',
    PlanItemType.call => 'Call',
    PlanItemType.appointment => 'Appointment',
    PlanItemType.medication => 'Medication',
    PlanItemType.note => 'Note',
    PlanItemType.project => 'Project',
    PlanItemType.unknown => 'Untyped',
  };
}

IconData _typeIcon(PlanItemType t) {
  return switch (t) {
    PlanItemType.task => Icons.check_box_outline_blank,
    PlanItemType.errand => Icons.shopping_bag_outlined,
    PlanItemType.call => Icons.phone_outlined,
    PlanItemType.appointment => Icons.event_outlined,
    PlanItemType.medication => Icons.medical_services_outlined,
    PlanItemType.note => Icons.sticky_note_2_outlined,
    PlanItemType.project => Icons.account_tree_outlined,
    PlanItemType.unknown => Icons.help_outline,
  };
}

String _timeLabel(ItemTime time) {
  return time.when<String>(
    hardTime: (DateTime _, __) => 'At a fixed time',
    timeWindow: (DateTime? __, DateTime ___) => 'Within a window',
    recurring: (String __, DateTime ___, DateTime? ____) => 'Recurring',
    untimed: () => 'No specific time',
  );
}

String _temperatureLabel(Temperature t) {
  return switch (t) {
    Temperature.hot => 'Hot',
    Temperature.warm => 'Warm',
    Temperature.cool => 'Cool',
  };
}