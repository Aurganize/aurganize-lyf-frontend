import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/plan_item.dart';
import '../../capture/presentation/editors/show_title_editor.dart';
import '../../capture/providers/plan_item_mutations.dart';

enum ProjectAction { rename, archive, delete }

/// Shows the project's more-actions menu and applies the chosen action.
Future<void> handleProjectAction({
  required BuildContext context,
  required WidgetRef ref,
  required PlanItem project,
  required VoidCallback onDeleted,
}) async {
  final ProjectAction? action = await showMenu<ProjectAction>(
    context: context,
    position: const RelativeRect.fromLTRB(1000, 80, 8, 0),
    items: <PopupMenuEntry<ProjectAction>>[
      const PopupMenuItem<ProjectAction>(
        value: ProjectAction.rename,
        child: ListTile(
          leading: Icon(Icons.edit_outlined),
          title: Text('Rename'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
      const PopupMenuItem<ProjectAction>(
        value: ProjectAction.archive,
        enabled: false, // Phase 11 — we have no archived field yet.
        child: ListTile(
          leading: Icon(Icons.archive_outlined),
          title: Text('Archive (coming)'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
      const PopupMenuItem<ProjectAction>(
        value: ProjectAction.delete,
        child: ListTile(
          leading: Icon(Icons.delete_outline, color: AppColors.tempHot),
          title: Text('Delete', style: TextStyle(color: AppColors.tempHot)),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    ],
  );
  if (action == null) return;
  if (!context.mounted) return;

  switch (action) {
    case ProjectAction.rename:
      final String? newTitle = await showTitleEditor(
        context: context,
        currentTitle: project.title,
      );
      if (newTitle != null) {
        await ref
            .read(planItemMutationsProvider.notifier)
            .updateTitle(project.id, newTitle);
      }
    case ProjectAction.archive:
    // Disabled menu item — should never fire. Defensive no-op.
      break;
    case ProjectAction.delete:
      final bool? confirmed = await _confirmDelete(context, project.title);
      if (confirmed == true) {
        await ref.read(planItemRepositoryProvider).delete(project.id);
        if (context.mounted) onDeleted();
      }
  }
}

Future<bool?> _confirmDelete(BuildContext context, String title) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext _) {
      return AlertDialog(
        title: const Text('Delete this project?'),
        content: Text(
          'This removes "$title" and every sub-item underneath it. '
              'Disposition history for these items will also be removed. '
              'No undo.',
          style: AppTypography.body,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.tempHot,
            ),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
}