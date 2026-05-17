import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/plan_item.dart';
import '../../disposition/providers/disposition_toast.dart';
import '../providers/project_subtree_provider.dart';
import 'project_actions.dart';
import 'project_children_list.dart';
import 'project_header.dart';

/// PDD §19. Hosted at `/plan/:rootId`.
///
/// Listens to [projectSubtreeProvider] for a live recursive snapshot,
/// renders the header and children list, supports recursive navigation
/// into child sub-projects.
class ProjectScreen extends ConsumerWidget {
  const ProjectScreen({super.key, required this.rootId});

  final String rootId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Toast handling: same pattern as the landing screen.
    ref.listen(
      dispositionToastsProvider,
          (prev, curr) {
        if (curr == null || curr == prev) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(curr.message),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        ref.read(dispositionToastsProvider.notifier).clear();
      },
    );

    final AsyncValue<PlanItem?> projectAsync =
    ref.watch(projectSubtreeProvider(rootId: rootId));

    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      appBar: AppBar(
        title: const Text('Project'),
        actions: <Widget>[
          projectAsync.maybeWhen(
            data: (PlanItem? p) {
              if (p == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.more_vert),
                tooltip: 'More actions',
                onPressed: () async {
                  await handleProjectAction(
                    context: context,
                    ref: ref,
                    project: p,
                    onDeleted: () => GoRouter.of(context).pop(),
                  );
                },
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: projectAsync.when(
        loading: () => const Center(
          child: SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ),
        error: (Object e, _) => _ErrorBody(error: e),
        data: (PlanItem? p) {
          if (p == null) return const _DeletedOrMissingBody();
          return _ProjectBody(project: p);
        },
      ),
    );
  }
}

class _ProjectBody extends StatelessWidget {
  const _ProjectBody({required this.project});

  final PlanItem project;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ProjectHeader(project: project),
            ProjectChildrenList(project: project),
          ],
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
          'Couldn\'t load this project. $error',
          style: AppTypography.bodyMuted,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _DeletedOrMissingBody extends StatelessWidget {
  const _DeletedOrMissingBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'This project isn\'t available.',
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: () => GoRouter.of(context).pop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}