import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: AppTypography.eyebrow),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceTertiary,
              borderRadius: AppSpacing.borderRadiusMedium,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                for (int i = 0; i < children.length; i++) ...<Widget>[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      thickness: 0.5,
                      color: AppColors.borderDefault,
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsToggleRow extends StatelessWidget {
  const SettingsToggleRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppTypography.body.copyWith(
                          color: enabled
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                        ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: AppTypography.caption),
                      ],
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: enabled ? onChanged : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsActionRow extends StatelessWidget {
  const SettingsActionRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.enabled = true,
    this.trailingIcon = Icons.chevron_right,
    this.titleColor,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool enabled;
  final IconData trailingIcon;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppTypography.body.copyWith(
                          color: !enabled
                              ? AppColors.textTertiary
                              : (titleColor ?? AppColors.textPrimary),
                        ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: AppTypography.caption),
                      ],
                    ],
                  ),
                ),
                Icon(
                  trailingIcon,
                  size: 18,
                  color:
                  enabled ? AppColors.iconMuted : AppColors.iconDisabled,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsSliderRow extends StatelessWidget {
  const SettingsSliderRow({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueLabel,
    required this.onChanged,
  });

  final String title;
  final int value;
  final int min;
  final int max;
  final int divisions;
  final String valueLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(title, style: AppTypography.body)),
              Text(valueLabel, style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.brandPrimary,
              )),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: divisions,
            onChanged: (double v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}