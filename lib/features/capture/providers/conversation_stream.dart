import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/repositories/repository_providers.dart';
import '../../../domain/enums/parse_status.dart';
import '../../../domain/models/intention.dart';
import '../../../domain/models/plan_item.dart';
import '../../../domain/repositories/intention_repository.dart';
import '../../../domain/repositories/plan_item_repository.dart';
import '../../auth/auth_providers.dart';

part 'conversation_stream.g.dart';

/// Sealed view-model for one entry in the conversation history.
sealed class ConversationItem {
  const ConversationItem({required this.timestamp, required this.intentionId});

  /// The capture's timestamp — drives chronological ordering.
  final DateTime timestamp;
  /// The id of the underlying intention.
  final String intentionId;
}

/// The user's spoken/typed text, as recorded.
class ConversationUserItem extends ConversationItem {
  const ConversationUserItem({
    required super.timestamp,
    required super.intentionId,
    required this.rawText,
  });

  final String rawText;
}

/// "Saved — parsing…" placeholder visible while [ParseStatus.pending]
/// or [ParseStatus.parsing].
class ConversationParsingItem extends ConversationItem {
  const ConversationParsingItem({
    required super.timestamp,
    required super.intentionId,
  });
}

/// One assistant-side card per parsed plan item that the user has not
/// yet confirmed or dispositioned. There may be 0, 1, or many of these
/// per intention.
class ConversationCardItem extends ConversationItem {
  const ConversationCardItem({
    required super.timestamp,
    required super.intentionId,
    required this.planItem,
  });

  final PlanItem planItem;
}

/// Sticky "you've already added these" item for an intention whose
/// every plan item has been confirmed. Not shown by default in v1.0 —
/// confirmed plan items appear in the today peek; the conversation
/// history shows just user-side bubbles for those captures. Reserved
/// for future use.

/// Failed-parse bubble. The user can tap "Edit directly" which the
/// host wires up to drop the raw text into the input field for manual
/// shaping.
class ConversationFailedItem extends ConversationItem {
  const ConversationFailedItem({
    required super.timestamp,
    required super.intentionId,
    required this.rawText,
    this.errorMessage,
  });

  final String rawText;
  final String? errorMessage;
}

/// The conversation history for the current user, oldest-to-newest.
///
/// Composition:
///   - Streams the user's recent intentions via
///     [IntentionRepository.watchRecentForUser].
///   - For each intention, emits a [ConversationUserItem] plus one of:
///       * [ConversationParsingItem] when status is pending/parsing.
///       * [ConversationCardItem] (one per pending plan item) when
///         status is parsed.
///       * [ConversationFailedItem] when status is failed.
///       * Nothing extra when status is dismissed AND all spawned
///         plan items have been acted on (we still show the user's
///         bubble for chronological continuity).
@riverpod
Stream<List<ConversationItem>> conversationStream(
    ConversationStreamRef ref,
    ) async* {
  final String userId = await ref.watch(currentUserIdProvider.future);
  final IntentionRepository intentionRepo =
  ref.watch(intentionRepositoryProvider);
  final PlanItemRepository planRepo = ref.watch(planItemRepositoryProvider);

  await for (final List<Intention> recent
  in intentionRepo.watchRecentForUser(userId, limit: 50)) {
    // The repository emits newest-first; we reverse to oldest-first
    // so the list reads top-to-bottom chronologically (older above,
    // newer below) — matching the visual scroll-from-bottom shape.
    final List<Intention> chronological = recent.reversed.toList();
    final List<ConversationItem> items = <ConversationItem>[];

    for (final Intention i in chronological) {
      items.add(ConversationUserItem(
        timestamp: i.capturedAt,
        intentionId: i.id,
        rawText: i.rawText,
      ));

      switch (i.parseStatus) {
        case ParseStatus.pending:
        case ParseStatus.parsing:
        case ParseStatus.inProgress:
          items.add(ConversationParsingItem(
            timestamp: i.capturedAt,
            intentionId: i.id,
          ));
        case ParseStatus.parsed:
          final List<PlanItem> children =
          await planRepo.findByIntention(i.id);
          for (final p in children) {
            if (p.confirmed) continue;
            if (await planRepo.hasAnyDisposition(p.id)) continue;
            items.add(ConversationCardItem(
              timestamp: i.capturedAt,
              intentionId: i.id,
              planItem: p,
            ));
          }
        case ParseStatus.failed:
          items.add(ConversationFailedItem(
            timestamp: i.capturedAt,
            intentionId: i.id,
            rawText: i.rawText,
            errorMessage: i.parseError,
          ));
        case ParseStatus.dismissed:
        // No assistant-side item; user's bubble already added.
          break;
      }
    }

    yield items;
  }
}