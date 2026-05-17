import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Opens a modal to edit a plan item's title. Resolves with the new
/// title (trimmed, non-empty), or null on cancel.
Future<String?> showTitleEditor({
  required BuildContext context,
  required String currentTitle,
}) {
  return showModalBottomSheet<String?>(
    context: context,
    backgroundColor: AppColors.surfacePrimary,
    barrierColor: AppColors.scrim,
    isScrollControlled: true, // grow with the keyboard
    useSafeArea: true,
    builder: (BuildContext sheetCtx) {
      return _TitleEditorSheet(initialTitle: currentTitle);
    },
  );
}

class _TitleEditorSheet extends StatefulWidget {
  const _TitleEditorSheet({required this.initialTitle});

  final String initialTitle;

  @override
  State<_TitleEditorSheet> createState() => _TitleEditorSheetState();
}

class _TitleEditorSheetState extends State<_TitleEditorSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final String trimmed = _controller.text.trim();
    if (trimmed.isEmpty) return; // disable empty
    Navigator.of(context).pop(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    // Keyboard inset — the sheet expands with the keyboard.
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
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
              Center(
                child: Text('EDIT TITLE', style: AppTypography.eyebrow),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: AppTypography.body,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  hintText: 'Title',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}