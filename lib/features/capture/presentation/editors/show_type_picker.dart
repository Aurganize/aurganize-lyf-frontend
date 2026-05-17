import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/enums/plan_item_type.dart';

/// Opens a picker for [PlanItemType]. Resolves with the chosen type
/// or null on cancel.
Future<PlanItemType?> showTypePicker({
  required BuildContext context,
  required PlanItemType currentType,
}) {
  return showModalBottomSheet<PlanItemType?>(
    context: context,
    backgroundColor: AppColors.surfacePrimary,
    barrierColor: AppColors.scrim,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetCtx) {
      return _TypePickerSheet(currentType: currentType);
    },
  );
}

class _TypePickerSheet extends StatelessWidget {
  const _TypePickerSheet({required this.currentType});

  final PlanItemType currentType;

  static const List<({PlanItemType type, String label, IconData icon})>
  _options = <({PlanItemType type, String label, IconData icon})>[
    (type: PlanItemType.task,
    label: 'Task',
    icon: Icons.check_box_outline_blank),
    (type: PlanItemType.errand,
    label: 'Errand',
    icon: Icons.shopping_bag_outlined),
    (type: PlanItemType.call, label: 'Call', icon: Icons.phone_outlined),
    (type: PlanItemType.appointment,
    label: 'Appointment',
    icon: Icons.event_outlined),
    (type: PlanItemType.medication,
    label: 'Medication',
    icon: Icons.medical_services_outlined),
    (type: PlanItemType.note,
    label: 'Note',
    icon: Icons.sticky_note_2_outlined),
    (type: PlanItemType.project,
    label: 'Project',
    icon: Icons.account_tree_outlined),
    (type: PlanItemType.unknown,
    label: 'Untyped',
    icon: Icons.help_outline),
  ];

  @override
  Widget build(BuildContext context) {
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
          children: <Widget>[
            Center(child: Text('PICK A TYPE', style: AppTypography.eyebrow)),
            const SizedBox(height: AppSpacing.md),
            for (int i = 0; i < _options.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              _TypeOptionRow(
                label: _options[i].label,
                icon: _options[i].icon,
                selected: _options[i].type == currentType,
                onTap: () => Navigator.of(context).pop(_options[i].type),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypeOptionRow extends StatelessWidget {
  const _TypeOptionRow({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? '$label, currently selected' : label,
      excludeSemantics: true,
      child: Material(
        color: selected
            ? AppColors.brandLight
            : AppColors.surfaceTertiary,
        borderRadius: AppSpacing.borderRadiusMedium,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    icon,
                    size: 20,
                    color: selected
                        ? AppColors.brandDark
                        : AppColors.iconDefault,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.body.copyWith(
                        color: selected
                            ? AppColors.brandDark
                            : AppColors.textPrimary,
                        fontWeight: selected
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check,
                      size: 18,
                      color: AppColors.brandDark,
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