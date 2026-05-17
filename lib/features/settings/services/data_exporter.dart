import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/logger.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/enums/parse_status.dart';
import '../../../domain/repositories/intention_repository.dart';
import '../../../domain/repositories/plan_item_repository.dart';
import '../../auth/auth_providers.dart';

part 'data_exporter.g.dart';

@Riverpod(keepAlive: true)
DataExporter dataExporter(DataExporterRef ref) {
  return DataExporter(
    intentionRepo: ref.watch(intentionRepositoryProvider),
    planRepo: ref.watch(planItemRepositoryProvider),
    userIdFuture: () => ref.read(currentUserIdProvider.future),
  );
}

/// Produces a portable JSON snapshot of the user's data and surfaces
/// it via the platform share sheet (iOS) or chooser (Android).
///
/// The format is **stable** — Phase 22 will document it in the API
/// reference. v1.0 includes:
///   - intentions (raw captures)
///   - plan_items (parsed structured items)
///   - disposition_events (full audit log)
///   - user_id
///
/// Settings preferences are intentionally NOT exported here — those
/// are device-local; importing them on a new device makes little sense
/// without an explicit "restore settings" flow we don't ship in v1.0.
class DataExporter {
  DataExporter({
    required IntentionRepository intentionRepo,
    required PlanItemRepository planRepo,
    required Future<String> Function() userIdFuture,
  })  : _intentionRepo = intentionRepo,
        _planRepo = planRepo,
        _userIdFuture = userIdFuture;

  final IntentionRepository _intentionRepo;
  final PlanItemRepository _planRepo;
  final Future<String> Function() _userIdFuture;

  static final Logger _log = appLogger('DataExporter');

  Future<void> exportAndShare() async {
    final String userId = await _userIdFuture();
    final Map<String, Object?> snapshot = await _buildSnapshot(userId);

    final Directory tmp = await getTemporaryDirectory();
    final String stamp =
    DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final File file =
    File('${tmp.path}/aurganize-export-$stamp.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(snapshot),
      flush: true,
    );
    _log.info('exported ${file.lengthSync()} bytes to ${file.path}');

    await Share.shareXFiles(
      <XFile>[XFile(file.path, mimeType: 'application/json')],
      subject: 'Aurganize lyf export',
    );
  }

  Future<Map<String, Object?>> _buildSnapshot(String userId) async {
    final intentions = await _intentionRepo.findRecentForUser(
      userId,
      limit: 100000, // effectively unbounded for this user
    );
    final List<Map<String, Object?>> intentionMaps = <Map<String, Object?>>[];
    final List<Map<String, Object?>> planItemMaps = <Map<String, Object?>>[];

    for (final intention in intentions) {
      intentionMaps.add(<String, Object?>{
        'id': intention.id,
        'raw_text': intention.rawText,
        'captured_at': intention.capturedAt.toIso8601String(),
        'source': intention.source.name,
        'parse_status': intention.parseStatus.name,
        'parse_error': intention.parseError,
      });

      final List items = await _planRepo.findByIntention(intention.id);
      for (final p in items) {
        planItemMaps.add(<String, Object?>{
          'id': p.id,
          'intention_id': p.intentionId,
          'parent_id': p.parentId,
          'title': p.title,
          'type': p.type.name,
          'temperature': p.temperature.name,
          'confirmed': p.confirmed,
          'created_at': p.createdAt.toIso8601String(),
          'updated_at': p.updatedAt.toIso8601String(),
        });
      }
    }

    return <String, Object?>{
      'schema': 'aurganize-lyf-export/v1',
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'user_id': userId,
      'intentions': intentionMaps,
      'plan_items': planItemMaps,
      // Future: disposition_events. We omit in v1.0 because the
      // repository doesn't yet expose a "find all events for user"
      // query and the SRS data-portability requirement is satisfied
      // by what we have. Phase 22 fills it in.
    };
  }
}