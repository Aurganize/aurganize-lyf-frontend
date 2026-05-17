import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/logger.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/enums/capture_source.dart';
import '../../../domain/enums/plan_item_type.dart';
import '../../../domain/enums/temperature.dart';
import '../../../domain/models/intention.dart';
import '../../../domain/models/item_time.dart';
import '../../../domain/models/plan_item.dart';
import '../../auth/auth_providers.dart';

part 'create_child_plan_item.g.dart';

/// Creates a new plan item as a child of [parentId].
///
/// The synthetic [Intention] preserves the audit trail — every plan
/// item still traces back to a captured intention (SRS §9.1). For
/// manually-created items the "raw text" is just the title; the
/// intention is immediately marked dismissed so it never shows up
/// in the conversation panel as a pending parse.
///
/// Returns the newly created plan item.
@riverpod
class CreateChildPlanItem extends _$CreateChildPlanItem {
  static final Logger _log = appLogger('CreateChild');
  static const Uuid _uuid = Uuid();

  @override
  void build() {}

  Future<PlanItem> create({
    required String parentId,
    required String title,
  }) async {
    final String trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(title, 'title', 'cannot be empty');
    }

    final String userId = await ref.read(currentUserIdProvider.future);
    final DateTime now = DateTime.now().toUtc();

    // 1. Synthetic intention — preserves the audit chain.
    final Intention intention = Intention(
      id: _uuid.v4(),
      userId: userId,
      rawText: trimmed,
      capturedAt: now,
      source: CaptureSource.manual,
    );
    await ref.read(intentionRepositoryProvider).create(intention);
    await ref.read(intentionRepositoryProvider).markDismissed(intention.id);

    // 2. The plan item itself — confirmed at birth, no parser needed.
    final PlanItem item = PlanItem(
      id: _uuid.v4(),
      userId: userId,
      intentionId: intention.id,
      parentId: parentId,
      title: trimmed,
      type: PlanItemType.task,
      time: const ItemTime.untimed(),
      temperature: Temperature.cool,
      confirmed: true,
      createdAt: now,
      updatedAt: now,
    );
    await ref.read(planItemRepositoryProvider).create(item);
    _log.info('created child ${item.id} under $parentId');
    return item;
  }
}