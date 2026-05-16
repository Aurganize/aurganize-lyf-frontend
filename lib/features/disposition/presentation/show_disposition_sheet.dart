import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/disposition_sheet_content.dart';
import 'disposition_action.dart';

/// Shows the disposition prompt sheet and resolves with the user's
/// choice, or `null` if they dismissed the sheet without choosing.
///
/// The host of this call is responsible for:
///   - Computing the [question] (typically via `DispositionCopy.composeQuestion`).
///   - Performing whatever action the result implies (e.g. recording a
///     disposition event via the repository).
///
/// The sheet is `isDismissible: true` so a tap-outside cancels —
/// PDD §17: "Tap-outside dismisses the sheet without changing state.
/// The user cannot accidentally commit by dismissing."
Future<DispositionAction?> showDispositionSheet({
  required BuildContext context,
  required String question,
}) {
  return showModalBottomSheet<DispositionAction?>(
    context: context,
    backgroundColor: AppColors.surfacePrimary,
    barrierColor: AppColors.scrim,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) {
      return DispositionSheetContent(
        question: question,
        onAction: (DispositionAction action) {
          Navigator.of(sheetContext).pop<DispositionAction>(action);
        },
      );
    },
  );
}