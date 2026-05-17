import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/item_time.dart';

/// Opens a multi-step editor for [ItemTime]. The user first picks a
/// variant (Hard time / Window / Recurring / Untimed), then any
/// follow-up sub-pickers fire. Resolves with the new [ItemTime] or
/// null on cancel.
Future<ItemTime?> showTimeEditor({
  required BuildContext context,
  required ItemTime currentTime,
}) async {
  // Step 1 — pick the variant.
  final _Variant? variant = await showModalBottomSheet<_Variant?>(
    context: context,
    backgroundColor: AppColors.surfacePrimary,
    barrierColor: AppColors.scrim,
    useSafeArea: true,
    builder: (BuildContext sheetCtx) {
      return _VariantPickerSheet(current: _classify(currentTime));
    },
  );
  if (variant == null) return null;

  // Step 2 — dispatch to the variant's own editor.
  switch (variant) {
    case _Variant.hardTime:
      if (!context.mounted) return null;
      return _editHardTime(context, currentTime);
    case _Variant.window:
      if (!context.mounted) return null;
      return _editWindow(context, currentTime);
    case _Variant.recurring:
    // Recurring is its own row on the detail screen, but inside the
    // time editor we offer it as a variant. Defer to the recurrence
    // editor — exposed in show_recurrence_editor.dart.
      if (!context.mounted) return null;
      return _editRecurringStub(context);
    case _Variant.untimed:
      return const ItemTime.untimed();
  }
}

enum _Variant { hardTime, window, recurring, untimed }

_Variant _classify(ItemTime t) {
  return t.when<_Variant>(
    hardTime: (_, __) => _Variant.hardTime,
    timeWindow: (_, __) => _Variant.window,
    recurring: (_, __, ___) => _Variant.recurring,
    untimed: () => _Variant.untimed,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — variant picker
// ─────────────────────────────────────────────────────────────────────────────

class _VariantPickerSheet extends StatelessWidget {
  const _VariantPickerSheet({required this.current});

  final _Variant current;

  static const List<({_Variant v, String title, String body, IconData icon})>
  _options = <({_Variant v, String title, String body, IconData icon})>[
    (
    v: _Variant.hardTime,
    title: 'At a fixed time',
    body: 'A specific clock time on a specific day.',
    icon: Icons.access_time_filled_outlined,
    ),
    (
    v: _Variant.window,
    title: 'Within a window',
    body: 'A soft deadline — by Friday, this week.',
    icon: Icons.date_range_outlined,
    ),
    (
    v: _Variant.recurring,
    title: 'Recurring',
    body: 'Repeats — daily, weekly, custom.',
    icon: Icons.refresh,
    ),
    (
    v: _Variant.untimed,
    title: 'No specific time',
    body: 'Drifting — sometime, whenever.',
    icon: Icons.all_inclusive,
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
            Center(child: Text('WHEN', style: AppTypography.eyebrow)),
            const SizedBox(height: AppSpacing.md),
            for (int i = 0; i < _options.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              _VariantOptionRow(
                title: _options[i].title,
                body: _options[i].body,
                icon: _options[i].icon,
                selected: _options[i].v == current,
                onTap: () => Navigator.of(context).pop(_options[i].v),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VariantOptionRow extends StatelessWidget {
  const _VariantOptionRow({
    required this.title,
    required this.body,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String body;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brandLight : AppColors.surfaceTertiary,
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
              Icon(icon,
                  size: 20,
                  color: selected
                      ? AppColors.brandDark
                      : AppColors.iconDefault),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title,
                        style: AppTypography.body.copyWith(
                          color: selected
                              ? AppColors.brandDark
                              : AppColors.textPrimary,
                          fontWeight:
                          selected ? FontWeight.w500 : FontWeight.w400,
                        )),
                    const SizedBox(height: 2),
                    Text(body, style: AppTypography.caption),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 20, color: AppColors.iconMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — variant-specific pickers
// ─────────────────────────────────────────────────────────────────────────────

Future<ItemTime?> _editHardTime(
    BuildContext context,
    ItemTime current,
    ) async {
  // Materialize the current date/time, or fall back to today at 9 AM.
  DateTime initial = current.maybeWhen<DateTime>(
    hardTime: (DateTime at, _) => at.toLocal(),
    orElse: () =>
        DateTime.now().add(const Duration(hours: 1)),
  );

  final DateTime? date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime.now().subtract(const Duration(days: 30)),
    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
  );
  if (date == null || !context.mounted) return null;

  final TimeOfDay? time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return null;

  final DateTime composed = DateTime(
    date.year, date.month, date.day, time.hour, time.minute,
  ).toUtc();
  return ItemTime.hardTime(at: composed);
}

Future<ItemTime?> _editWindow(
    BuildContext context,
    ItemTime current,
    ) async {
  // Window editor: just pick the "until" date. From defaults to "now".
  DateTime initial = current.maybeWhen<DateTime>(
    timeWindow: (DateTime? from, DateTime until) => until.toLocal(),
    orElse: () => DateTime.now().add(const Duration(days: 7)),
  );

  final DateTime? until = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
  );
  if (until == null) return null;

  // Default the window "from" to now.
  return ItemTime.timeWindow(
    from: DateTime.now().toUtc(),
    until: DateTime(until.year, until.month, until.day, 23, 59).toUtc(),
  );
}

Future<ItemTime?> _editRecurringStub(BuildContext context) async {
  // The recurrence editor is its own surface — show_recurrence_editor.dart.
  // From within the time-editor flow we surface a simple bridge.
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfacePrimary,
    builder: (BuildContext _) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'For recurring items, use the Recurrence row on the detail screen.',
          style: AppTypography.bodyMuted,
        ),
      );
    },
  );
  return null;
}