import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/create_child_plan_item.dart';

/// Opens the inline create-sub-item dialog. Resolves with `true` if
/// the user created an item, `false` (or null) otherwise.
Future<bool?> showCreateSubitemDialog({
  required BuildContext context,
  required String parentId,
}) {
  return showModalBottomSheet<bool?>(
    context: context,
    backgroundColor: AppColors.surfacePrimary,
    barrierColor: AppColors.scrim,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext _) => _CreateSubitemSheet(parentId: parentId),
  );
}

class _CreateSubitemSheet extends ConsumerStatefulWidget {
  const _CreateSubitemSheet({required this.parentId});

  final String parentId;

  @override
  ConsumerState<_CreateSubitemSheet> createState() =>
      _CreateSubitemSheetState();
}

class _CreateSubitemSheetState extends ConsumerState<_CreateSubitemSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
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

  Future<void> _submit() async {
    final String text = _controller.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(createChildPlanItemProvider.notifier).create(
        parentId: widget.parentId,
        title: text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't add: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Center(child: Text('ADD A SUB-ITEM', style: AppTypography.eyebrow)),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: AppTypography.body,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  hintText: 'What needs doing?',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                      _busy ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.surfacePrimary,
                          ),
                        ),
                      )
                          : const Text('Create'),
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