import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../features/disposition/presentation/disposition_action.dart';
import '../../features/disposition/presentation/disposition_copy.dart';
import 'disposition_button.dart';

/// The disposition prompt body — PDD §17.
///
/// Lays out:
///   - The CHECK-IN eyebrow
///   - The question (caller-supplied — rotated by the provider layer)
///   - The reassurance
///   - Four [DispositionButton]s stacked
///
/// Bottom-sheet chrome (drag handle, rounded top corners, scrim) is the
/// concern of [showModalBottomSheet]'s sheet theme — see
/// `app_theme.dart`'s `_bottomSheetTheme`. This widget renders only the
/// body.
///
/// ### Behavior
///
/// Each button calls back through [onAction]. The widget does not itself
/// dismiss the sheet — the host (the route or modal-show call) is
/// responsible for `Navigator.of(context).pop()` after persisting the
/// action. Decoupling means the sheet stays open during async work and
/// can show errors in place if the persist fails.
class DispositionSheetContent extends StatelessWidget {
  const DispositionSheetContent({
    super.key,
    required this.question,
    required this.onAction,
  });

  /// The fully composed opening question — e.g. "Still planning to
  /// pick up the dry cleaning?". Use [DispositionCopy.composeQuestion]
  /// to produce this.
  final String question;

  /// Called when the user picks an action.
  final void Function(DispositionAction action) onAction;

  @override
  Widget build(BuildContext context) {
    // The sheet content lives inside an inherited bottom sheet with
    // sheet padding from the theme. We add our own internal vertical
    // spacing.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _headerBlock(),
            const SizedBox(height: AppSpacing.xl),
            _DispositionActionsList(onAction: onAction),
          ],
        ),
      ),
    );
  }

  Widget _headerBlock() {
    // Wrap the eyebrow + question + reassurance in a single Semantics
    // node so VoiceOver reads them as one utterance — PDD §17 a11y note.
    return MergeSemantics(
      child: Semantics(
        container: true,
        label: '${DispositionCopy.eyebrow}. $question ${DispositionCopy.reassurance}',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              DispositionCopy.eyebrow,
              style: AppTypography.eyebrow.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              question,
              textAlign: TextAlign.center,
              style: AppTypography.heading.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              DispositionCopy.reassurance,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Stacks the four action buttons. Pulled out as its own widget so the
/// list can be tested independently from the header.
class _DispositionActionsList extends StatelessWidget {
  const _DispositionActionsList({required this.onAction});

  final void Function(DispositionAction action) onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DispositionButton(
          icon: Icons.check,
          label: DispositionCopy.doneLabel,
          subExplanation: DispositionCopy.doneSub,
          onTap: () => onAction(DispositionAction.done),
        ),
        const SizedBox(height: AppSpacing.sm),
        DispositionButton(
          icon: Icons.more_horiz,
          label: DispositionCopy.onItLabel,
          subExplanation: DispositionCopy.onItSub,
          onTap: () => onAction(DispositionAction.onIt),
        ),
        const SizedBox(height: AppSpacing.sm),
        DispositionButton(
          icon: Icons.bedtime_outlined,
          label: DispositionCopy.pushLabel,
          subExplanation: DispositionCopy.pushSub,
          onTap: () => onAction(DispositionAction.pushToTomorrow),
        ),
        const SizedBox(height: AppSpacing.sm),
        DispositionButton(
          icon: Icons.radio_button_unchecked,
          label: DispositionCopy.skipLabel,
          subExplanation: DispositionCopy.skipSub,
          onTap: () => onAction(DispositionAction.skipIt),
        ),
      ],
    );
  }
}