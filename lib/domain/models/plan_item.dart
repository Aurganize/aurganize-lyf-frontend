import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/plan_item_state.dart';
import '../enums/plan_item_type.dart';
import '../enums/temperature.dart';
import 'confidence.dart';
import 'item_time.dart';

part 'plan_item.freezed.dart';
part 'plan_item.g.dart';

/// The structured interpretation of an [Intention] — SRS §9.1.
///
/// Recursive: a plan item may contain children to arbitrary depth
/// (SRS FR-3.2). A plan item with children renders as a project view
/// (PDD §19); a leaf renders as a single actionable row.
///
/// Most attributes carry a parallel [Confidence] field captured in
/// [confidences] — see SRS FR-2.4. The UI uses these to render
/// tentative chips (PDD §9.3).
///
/// **`children` is the source-of-truth for the tree shape from the
/// API.** The Drift schema stores `parentId` instead, and we reconstruct
/// the tree on read. Models can be returned with `children: []` when
/// the tree is being assembled and walked lazily.
@freezed
class PlanItem with _$PlanItem {
  const PlanItem._();

  const factory PlanItem({
    /// Client-generated UUID v4.
    required String id,

    /// Owning user.
    required String userId,

    /// The [Intention] this plan item was derived from. Multiple plan
    /// items can share the same source intention (SRS FR-2.2).
    required String intentionId,

    /// Parent plan item ID. Null for top-level items.
    String? parentId,

    /// Display title. Always derived initially from the intention's
    /// raw text, but editable.
    required String title,

    /// Coarse classification — see [PlanItemType] doc comments.
    required PlanItemType type,

    /// Time aspect of the item — see [ItemTime] doc comments.
    required ItemTime time,

    /// Time-sensitivity — see [Temperature] doc comments.
    required Temperature temperature,

    /// Whether this item participates in gamification calculations.
    /// SRS FR-3.5: users can mark items as unscored, in which case
    /// they are tracked but excluded from streak / engagement counts.
    /// SRS FR-6.4: unscored items MUST be excluded from gamification.
    @Default(true) bool scored,

    /// Whether the user has explicitly accepted this plan item.
    @Default(false) bool confirmed,

    /// Per-attribute confidence map. Keys are field names (`'type'`,
    /// `'time'`, `'parent'`, `'temperature'`). Missing keys imply
    /// [Confidence.certain] — i.e. the user set it.
    @Default(<String, Confidence>{}) Map<String, Confidence> confidences,

    /// Children, if any. The data layer fills this when reading the
    /// tree; API payloads may include or omit it depending on context.
    @Default(<PlanItem>[]) List<PlanItem> children,

    /// When this plan item was created.
    required DateTime createdAt,

    /// When this plan item was last modified (excluding disposition
    /// events, which have their own timestamps in the log).
    required DateTime updatedAt,

    /// Optional reference to the parent project's group, if this is a
    /// group plan item. Null for personal items.
    String? groupId,
  }) = _PlanItem;

  factory PlanItem.fromJson(Map<String, Object?> json) =>
      _$PlanItemFromJson(json);

  /// True if this plan item has any children — renders as project view.
  bool get isProject =>
      children.isNotEmpty || type == PlanItemType.project;

  /// True if this is a top-level plan item (no parent).
  bool get isRoot => parentId == null;

  /// Returns the [Confidence] for the given field, defaulting to
  /// [Confidence.certain] if absent.
  Confidence confidenceFor(String field) =>
      confidences[field] ?? Confidence.certain;
}