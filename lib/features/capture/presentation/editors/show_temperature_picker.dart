import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/enums/temperature.dart';
import '../../../../shared/widgets/temperature_dot.dart';

Future<Temperature?> showTemperaturePicker({
  required BuildContext context,
  required Temperature currentTemperature,
}) {
  return showModalBottomSheet<Temperature?>(
    context: context,
    backgroundColor: AppColors.surfacePrimary,
    barrierColor: AppColors.scrim,
    useSafeArea: true,
    builder: (BuildContext sheetCtx) {
      return _TemperaturePickerSheet(current: currentTemperature);
    },
  );
}

class _TemperaturePickerSheet extends StatelessWidget {
  const _TemperaturePickerSheet({required this.current});

  final Temperature current;

  static const List<({Temperature t, String label, String desc})>
  _options = <({Temperature t, String label, String desc})>[
    (
    t: Temperature.hot,
    label: 'Hot',
    desc: 'Hard time — medication, appointments, alarms.',
    ),
    (
    t: Temperature.warm,
    label: 'Warm',
    desc: 'Soft deadline — this week, by Friday.',
    ),
    (
    t: Temperature.cool,
    label: 'Cool',
    desc: 'Drifting — sometime, whenever feels good.',
    ),
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
            Center(child: Text('TEMPERATURE', style: AppTypography.eyebrow)),
            const SizedBox(height: AppSpacing.md),
            for (int i = 0; i < _options.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              _TemperatureOptionRow(
                temperature: _options[i].t,
                label: _options[i].label,
                description: _options[i].desc,
                selected: _options[i].t == current,
                onTap: () => Navigator.of(context).pop(_options[i].t),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TemperatureOptionRow extends StatelessWidget {
  const _TemperatureOptionRow({
    required this.temperature,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final Temperature temperature;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label temperature. $description${selected ? " Currently selected." : ""}',
      excludeSemantics: true,
      child: Material(
        color: selected
            ? AppColors.brandLight
            : AppColors.surfaceTertiary,
        borderRadius: AppSpacing.borderRadiusMedium,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                TemperatureDot(temperature: temperature, size: 12),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(label,
                          style: AppTypography.body.copyWith(
                            color: selected
                                ? AppColors.brandDark
                                : AppColors.textPrimary,
                            fontWeight: selected
                                ? FontWeight.w500
                                : FontWeight.w400,
                          )),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check,
                      size: 18, color: AppColors.brandDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}