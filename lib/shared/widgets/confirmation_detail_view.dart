import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/confidence.dart';
import '../../features/capture/presentation/parsed_card_view_model.dart';

/// The full-screen confirmation card — PDD §16.
///
/// Hosted as a route in Phase 05 (`/confirm/:planItemId`). The widget
/// is pure presentation; the route layer supplies the [viewModel] and
/// the action callbacks.
class ConfirmationDetailView extends StatelessWidget {
  const ConfirmationDetailView({
    super.key,
    required this.viewModel,
    required this.onClose,
    required this.onEditTitle,
    required this.onEditAttribute,
    required this.onConfirm,
    required this.onDismiss,
  });

  final ParsedCardViewModel viewModel;

  /// Close the screen without changing anything.
  final VoidCallback onClose;

  /// Open a title editor.
  final VoidCallback onEditTitle;

  /// Open an inline editor for the supplied attribute.
  final void Function(ParsedAttribute attribute) onEditAttribute;

  /// Commit the structured plan item as currently shown.
  final VoidCallback onConfirm;

  /// Discard the structured plan item. The raw intention is retained.
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      appBar: AppBar(
        title: const Text('Confirm intention'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: onClose,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _quoteBlock(),
                    const SizedBox(height: AppSpacing.xl),
                    _parsedBlock(),
                  ],
                ),
              ),
            ),
            _actionBar(),
          ],
        ),
      ),
    );
  }

  // ── Subviews ─────────────────────────────────────────────────────────────

  Widget _quoteBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('YOU TYPED', style: AppTypography.eyebrow),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: AppSpacing.borderRadiusMedium,
          ),
          child: Text(
            '"${viewModel.rawText}"',
            style: AppTypography.body.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _parsedBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('WE UNDERSTOOD', style: AppTypography.eyebrow),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfacePrimary,
            borderRadius: AppSpacing.borderRadiusMedium,
            border: Border.all(
              color: AppColors.borderDefault,
              width: 0.5,
            ),
          ),
          child: Column(
            children: <Widget>[
              _titleRow(),
              const Divider(height: 0, thickness: 0.5),
              for (int i = 0; i < viewModel.attributes.length; i++) ...<Widget>[
                _AttributeRow(
                  attribute: viewModel.attributes[i],
                  onTap: () => onEditAttribute(viewModel.attributes[i]),
                ),
                if (i < viewModel.attributes.length - 1)
                  const Divider(height: 0, thickness: 0.5),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _titleRow() {
    final bool tentative = viewModel.titleConfidence.isTentative;
    return Semantics(
      button: true,
      label: 'Title: ${viewModel.title}. Tap to edit.',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEditTitle,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    viewModel.title,
                    style: AppTypography.title.copyWith(
                      color: tentative
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontStyle: tentative
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ),
                const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.iconMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfacePrimary,
        border: Border(
          top: BorderSide(color: AppColors.borderDefault, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: onDismiss,
                child: const Text('Dismiss'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: onConfirm,
                child: const Text('Add to plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single attribute row in the detail card
// ─────────────────────────────────────────────────────────────────────────────

class _AttributeRow extends StatelessWidget {
  const _AttributeRow({
    required this.attribute,
    required this.onTap,
  });

  final ParsedAttribute attribute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool tentative = attribute.confidence.isTentative;

    final String semanticsLabel = tentative
        ? '${attribute.label}: ${attribute.displayValue}. Tentative — tap to confirm or change.'
        : '${attribute.label}: ${attribute.displayValue}. Tap to edit.';

    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    attribute.icon,
                    size: 18,
                    color: tentative
                        ? AppColors.iconMuted
                        : AppColors.iconDefault,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          attribute.label,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          attribute.displayValue,
                          style: AppTypography.body.copyWith(
                            color: tentative
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            fontStyle: tentative
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                        if (tentative) ...<Widget>[
                          const SizedBox(height: 2),
                          Text(
                            'Tap to confirm or change',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.iconMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}