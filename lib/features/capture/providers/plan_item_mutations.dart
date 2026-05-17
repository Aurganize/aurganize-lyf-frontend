import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/logger.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/enums/plan_item_type.dart';
import '../../../domain/enums/temperature.dart';
import '../../../domain/models/confidence.dart';
import '../../../domain/models/item_time.dart';
import '../../../domain/models/plan_item.dart';
import '../../../domain/repositories/plan_item_repository.dart';

part 'plan_item_mutations.g.dart';

/// Single-write mutations applied to a [PlanItem] from the
/// confirmation detail. Every editor in [editors/] writes through here.
///
/// Each mutation reads the current item, computes a new version, and
/// writes it via the repository. The `confidence` for the changed
/// field flips to [Confidence.certain] — the user touched it, the
/// parser's guess no longer applies.
@riverpod
class PlanItemMutations extends _$PlanItemMutations {
  static final Logger _log = appLogger('PlanItemMutations');

  @override
  void build() {
    // Stateless notifier — see Phase 04 Part 04's QuestionRotator for
    // the same pattern.
  }

  Future<PlanItem> updateTitle(String planItemId, String newTitle) async {
    final PlanItem item = await _require(planItemId);
    final PlanItem updated = item.copyWith(
      title: newTitle,
      confidences: <String, Confidence>{
        ...item.confidences,
        'title': Confidence.certain,
      },
    );
    _log.info('title($planItemId) → "$newTitle"');
    return _write(updated);
  }

  Future<PlanItem> updateType(String planItemId, PlanItemType newType) async {
    final PlanItem item = await _require(planItemId);
    final PlanItem updated = item.copyWith(
      type: newType,
      confidences: <String, Confidence>{
        ...item.confidences,
        'type': Confidence.certain,
      },
    );
    _log.info('type($planItemId) → ${newType.name}');
    return _write(updated);
  }

  Future<PlanItem> updateTime(String planItemId, ItemTime newTime) async {
    final PlanItem item = await _require(planItemId);
    final PlanItem updated = item.copyWith(
      time: newTime,
      confidences: <String, Confidence>{
        ...item.confidences,
        'time': Confidence.certain,
      },
    );
    _log.info('time($planItemId) → ${newTime.runtimeType}');
    return _write(updated);
  }

  Future<PlanItem> updateTemperature(
      String planItemId,
      Temperature newTemperature,
      ) async {
    final PlanItem item = await _require(planItemId);
    final PlanItem updated = item.copyWith(
      temperature: newTemperature,
      confidences: <String, Confidence>{
        ...item.confidences,
        'temperature': Confidence.certain,
      },
    );
    _log.info('temperature($planItemId) → ${newTemperature.name}');
    return _write(updated);
  }

  Future<PlanItem> updateParent(String planItemId, String? newParentId) async {
    final PlanItem item = await _require(planItemId);
    // Self-parenting is rejected at the repository level via FK, but we
    // also guard here so the error is clear to the editor.
    if (newParentId == planItemId) {
      throw ArgumentError(
        'A plan item cannot be its own parent.',
      );
    }
    final PlanItem updated = item.copyWith(
      parentId: newParentId,
      confidences: <String, Confidence>{
        ...item.confidences,
        'parent': Confidence.certain,
      },
    );
    _log.info('parent($planItemId) → ${newParentId ?? "(none)"}');
    return _write(updated);
  }

  // ── private ────────────────────────────────────────────────────────────────

  Future<PlanItem> _require(String id) async {
    final PlanItemRepository repo = ref.read(planItemRepositoryProvider);
    final PlanItem? item = await repo.findById(id);
    if (item == null) {
      throw StateError('plan item $id not found');
    }
    return item;
  }

  Future<PlanItem> _write(PlanItem item) {
    final PlanItemRepository repo = ref.read(planItemRepositoryProvider);
    return repo.update(item);
  }
}