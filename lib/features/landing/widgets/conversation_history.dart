import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../capture/presentation/parsed_card_view_model.dart';
import '../../capture/providers/conversation_input.dart';
import '../../capture/providers/conversation_stream.dart';
import '../../capture/services/card_action_service.dart';
import '../../../shared/widgets/confirmation_peek_card.dart';
import 'conversation_bubble.dart';

/// Scrollable conversation log. Pulls from [conversationStreamProvider],
/// renders one of four bubble shapes per item, scrolls to the bottom
/// when new items arrive.
class ConversationHistory extends ConsumerStatefulWidget {
  const ConversationHistory({
    super.key,
    required this.onOpenCard,
  });

  /// Routes to the confirmation detail screen for the supplied plan
  /// item id. The host (panel body) wires this to `go_router`.
  final void Function(String planItemId) onOpenCard;

  @override
  ConsumerState<ConversationHistory> createState() =>
      _ConversationHistoryState();
}

class _ConversationHistoryState extends ConsumerState<ConversationHistory> {
  final ScrollController _scrollCtl = ScrollController();
  int _lastItemCount = 0;
  bool _userIsScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollCtl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    // Track whether the user is at the bottom edge — if they are,
    // new items auto-scroll into view. If they've scrolled up to
    // read older history, we don't yank them back to the bottom.
    final double max = _scrollCtl.position.maxScrollExtent;
    final double offset = _scrollCtl.offset;
    setState(() => _userIsScrolling = max - offset > 80);
  }

  void _maybeAnchorToBottom(int newCount) {
    if (newCount <= _lastItemCount) {
      _lastItemCount = newCount;
      return;
    }
    if (_userIsScrolling) {
      _lastItemCount = newCount;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtl.hasClients) return;
      _scrollCtl.animateTo(
        _scrollCtl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
    _lastItemCount = newCount;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ConversationItem>> async =
    ref.watch(conversationStreamProvider);
    return async.when(
      loading: () => const Center(
        child: SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      ),
      error: (Object e, _) => _ErrorBody(error: e),
      data: (List<ConversationItem> items) {
        _maybeAnchorToBottom(items.length);
        if (items.isEmpty) return const _EmptyBody();
        return ListView.separated(
          controller: _scrollCtl,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          itemCount: items.length,
          separatorBuilder: (_, __) =>
          const SizedBox(height: AppSpacing.sm + 2),
          itemBuilder: (BuildContext context, int index) {
            return _renderItem(items[index]);
          },
        );
      },
    );
  }

  Widget _renderItem(ConversationItem item) {
    switch (item) {
      case ConversationUserItem u:
        return ConversationBubble(
          alignment: BubbleAlignment.user,
          child: Text(u.rawText),
        );
      case ConversationParsingItem _:
        return ConversationBubble(
          alignment: BubbleAlignment.assistant,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.4),
              ),
              SizedBox(width: AppSpacing.sm),
              Text('Saved — parsing…'),
            ],
          ),
        );
      case ConversationCardItem c:
        return ConversationBubble(
          alignment: BubbleAlignment.assistant,
          borderless: true,
          maxWidthFraction: 1.0,
          child: ConfirmationPeekCard(
            viewModel: ParsedCardViewModelFactory.fromDomain(
              item: c.planItem,
              rawText: '', // not shown in the embedded card
            ),
            onConfirm: () async {
              await ref.read(cardActionServiceProvider).confirm(
                planItemId: c.planItem.id,
              );
            },
            onChipTap: (_) => widget.onOpenCard(c.planItem.id),
            onExpand: () => widget.onOpenCard(c.planItem.id),
            onDismiss: () async {
              await ref.read(cardActionServiceProvider).dismiss(
                planItemId: c.planItem.id,
                intentionId: c.intentionId,
              );
            },
          ),
        );
      case ConversationFailedItem f:
        return ConversationBubble(
          alignment: BubbleAlignment.assistant,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline,
                  size: 14, color: AppColors.tempWarm),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: GestureDetector(
                  onTap: () {
                    // Drop the raw text into the input field for manual
                    // editing — the user can adjust and resend.
                    ref
                        .read(conversationInputProvider.notifier)
                        .setDraft(f.rawText);
                  },
                  child: const Text(
                    "Couldn't parse — tap to edit directly.",
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          "Nothing here yet. Type or speak something below.",
          style: AppTypography.bodyMuted,
          textAlign: TextAlign.center,
        ),
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
          "Couldn't load conversation: $error",
          style: AppTypography.bodyMuted,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}