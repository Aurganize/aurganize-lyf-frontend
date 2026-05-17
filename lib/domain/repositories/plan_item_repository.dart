import '../enums/plan_item_state.dart';
import '../models/disposition_event.dart';
import '../models/plan_item.dart';
import 'package:aurganize_lyf/core/extensions/datetime_extensions.dart';

/// Operations on plan items and their disposition history.
///
/// Disposition is part of this interface (not a separate one) because
/// the state of a plan item and its history are tightly coupled: every
/// disposition is appended to the log, and the item's current state is
/// derived from the log (SRS FR-4.7).
abstract interface class PlanItemRepository {
  /// Persist a new plan item. The caller must ensure [PlanItem.parentId]
  /// references an existing item (or is null for a root item) — the
  /// store enforces this via FK and will throw otherwise.
  Future<PlanItem> create(PlanItem item);

  /// Persist many plan items in one transaction. Used by the parsing
  /// pipeline when a single intention produces multiple plan items.
  Future<void> createMany(List<PlanItem> items);

  /// Lookup by id. When [includeChildren] is true, the returned
  /// [PlanItem.children] is populated recursively to arbitrary depth.
  Future<PlanItem?> findById(String id, {bool includeChildren = false});

  Future<List<PlanItem>> findByIntention(String intentionId);

  Future<PlanItem> update(PlanItem item);

  Future<void> delete(String id);

  // -- Day views ---------------------------------------------------------------

  /// Live stream of items scheduled for [date]'s UTC day, excluding
  /// items whose latest disposition is terminal. Backs the landing
  /// screen.
  Stream<List<PlanItem>> watchForDay({
    required String userId,
    required DateTime date,
  });

  /// Live stream of items scheduled for [date] that have never been
  /// dispositioned. Backs the leftover view.
  Stream<List<PlanItem>> watchLeftoversForDay({
    required String userId,
    required DateTime date,
  });

  /// Per-day count of leftover items in a window. Backs the count pills
  /// on the date-train tiles.
  Future<Map<DateTime, int>> leftoverCountsByDay({
    required String userId,
    required DateTime from,
    required DateTime to,
  });

  // -- Project view ------------------------------------------------------------

  /// Live stream of the project subtree rooted at [rootId]. Re-emits
  /// on any change in plan_items.
  Stream<PlanItem?> watchProjectTree(String rootId);

  // -- Disposition -------------------------------------------------------------

  /// Append a disposition event for [planItemId]. The repository
  /// validates that [event.priorState] matches the current derived
  /// state and refuses (throws [StateError]) otherwise — this prevents
  /// stale-client races from skipping a transition.
  Future<DispositionEvent> recordDisposition({
    required DispositionEvent event,
  });

  /// Full disposition history, newest first.
  Future<List<DispositionEvent>> historyFor(String planItemId);

  Stream<List<DispositionEvent>> watchHistoryFor(String planItemId);

  /// Current derived state — the [DispositionEvent.newState] of the
  /// most recent event, or [PlanItemState.planned] if there is none.
  Future<PlanItemState> currentStateFor(String planItemId);

  /// Atomic disposition. Records the [event] and, if the new state
  /// implies one, applies any associated mutation to the plan item:
  ///
  ///   - [PlanItemState.rescheduled]: the disposition event is appended
  ///     with `newState = rescheduled`, then a second
  ///     `recordDisposition` (within the same transaction) appends
  ///     `(rescheduled → planned)` and updates `scheduledForDay` to
  ///     the new bucket derived from [rescheduleTo].
  ///   - Any other state: just append the event.
  ///
  /// Returns the final [PlanItemState] visible to consumers — typically
  /// the event's `newState`, except for rescheduled which collapses
  /// to `planned`.
  ///
  /// Throws [StateError] (from the underlying [recordDisposition]) if
  /// the supplied `priorState` does not match the current state.
  Future<PlanItemState> applyDisposition({
    required String planItemId,
    required PlanItemState priorState,
    required PlanItemState newState,
    required bool prompted,
    DateTime? rescheduleTo,
  });
}