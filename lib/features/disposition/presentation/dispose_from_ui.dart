import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_typography.dart';
import '../../../domain/models/plan_item.dart';
import '../providers/disposition_controller.dart';
import '../providers/question_rotator.dart';
import 'disposition_action.dart';
import 'show_disposition_sheet.dart';

/// Result of a [disposeFromUi] call.
sealed class DispositionFlowOutcome {
  const DispositionFlowOutcome();
}

class DispositionFlowCancelled extends DispositionFlowOutcome {
  const DispositionFlowCancelled();
}

class DispositionFlowApplied extends DispositionFlowOutcome {
  const DispositionFlowApplied(this.action);
  final DispositionAction action;
}

class DispositionFlowConflict extends DispositionFlowOutcome {
  const DispositionFlowConflict(this.message);
  final String message;
}

class DispositionFlowFailed extends DispositionFlowOutcome {
  const DispositionFlowFailed(this.error);
  final Object error;
}

/// One canonical way to ask the user to disposition a plan item.
///
/// The flow:
///   1. Pick a non-repeating question via [QuestionRotator].
///   2. Show the disposition sheet (`showDispositionSheet`).
///   3. On a chosen action, call [DispositionController.dispose].
///   4. Return an outcome describing what happened.
///
/// The caller does not need to show a toast — the controller emits it
/// via [DispositionToasts] and the screen layer's `ref.listen` shows it.
/// The caller is responsible only for any **screen-local** UX:
///   - If `outcome` is [DispositionFlowConflict], the caller's view is
///     showing stale data; refresh it.
///   - If `outcome` is [DispositionFlowFailed], surface a "couldn't
///     save" message (or rely on a higher-level error boundary).
///
/// The [prompted] flag distinguishes proactive vs notification-driven
/// dispositions for gamification (SRS FR-4.6).
///
/// [questionOverride], when supplied, is used verbatim. Callers in
/// special contexts (e.g. the leftover view's "From yesterday: ..."
/// phrasing) bypass the rotator.
Future<DispositionFlowOutcome> disposeFromUi({
  required BuildContext context,
  required WidgetRef ref,
  required PlanItem item,
  required bool prompted,
  String? questionOverride,
}) async {
  final String question = questionOverride ??
      ref
          .read(questionRotatorProvider.notifier)
          .questionFor(item.title);

  final DispositionAction? choice = await showDispositionSheet(
    context: context,
    question: question,
  );
  if (choice == null) {
    return const DispositionFlowCancelled();
  }

  try {
    await ref.read(dispositionControllerProvider.notifier).dispose(
      planItemId: item.id,
      action: choice,
      prompted: prompted,
    );
    return DispositionFlowApplied(choice);
  } on StateError catch (e) {
    // Stale priorState — another device beat us to the change, or the
    // user has multiple tabs open. The repository's rejection is the
    // signal. We do NOT swallow it: surface a calm note and let the
    // caller decide.
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This item changed in the meantime. Refresh and try again.',
            style: AppTypography.body,
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    return DispositionFlowConflict(e.message);
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "We couldn't save that. Please try again.",
            style: AppTypography.body,
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    return DispositionFlowFailed(error);
  }
}