import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/item_time.dart';

/// Opens a recurrence editor. Returns:
///   - An [ItemTime.recurring] when the user picks a recurrence.
///   - An [ItemTime.untimed] when the user picks "No recurrence" — the
///     caller decides whether to swap the existing time with this.
///   - null on cancel.
Future<ItemTime?> showRecurrenceEditor({
  required BuildContext context,
  required ItemTime currentTime,
}) {
  return showModalBottomSheet<ItemTime?>(
    context: context,
    backgroundColor: AppColors.surfacePrimary,
    barrierColor: AppColors.scrim,
    useSafeArea: true,
    builder: (BuildContext _) {
      return _RecurrenceEditorSheet(currentTime: currentTime);
    },
  );
}

class _RecurrenceEditorSheet extends StatefulWidget {
  const _RecurrenceEditorSheet({required this.currentTime});

  final ItemTime currentTime;

  @override
  State<_RecurrenceEditorSheet> createState() =>
      _RecurrenceEditorSheetState();
}

class _RecurrenceEditorSheetState extends State<_RecurrenceEditorSheet> {
  late _Freq _freq;
  Set<String> _weekdays = <String>{}; // BYDAY codes

  @override
  void initState() {
    super.initState();
    final Recurring? rec = widget.currentTime is Recurring
        ? widget.currentTime as Recurring
        : null;
    if (rec == null) {
      _freq = _Freq.none;
    } else if (rec.rrule == 'FREQ=DAILY') {
      _freq = _Freq.daily;
    } else if (rec.rrule == 'FREQ=WEEKLY') {
      _freq = _Freq.weekly;
    } else if (rec.rrule.startsWith('FREQ=WEEKLY;BYDAY=')) {
      _freq = _Freq.weekly;
      _weekdays = rec.rrule
          .substring('FREQ=WEEKLY;BYDAY='.length)
          .split(',')
          .toSet();
    } else {
      _freq = _Freq.custom;
    }
  }

  void _save() {
    final DateTime now = DateTime.now().toUtc();
    switch (_freq) {
      case _Freq.none:
        Navigator.of(context).pop<ItemTime>(const ItemTime.untimed());
      case _Freq.daily:
        Navigator.of(context).pop<ItemTime>(ItemTime.recurring(
          rrule: 'FREQ=DAILY',
          referenceTime: now,
        ));
      case _Freq.weekly:
        final String rrule = _weekdays.isEmpty
            ? 'FREQ=WEEKLY'
            : 'FREQ=WEEKLY;BYDAY=${_weekdays.join(",")}';
        Navigator.of(context).pop<ItemTime>(ItemTime.recurring(
          rrule: rrule,
          referenceTime: now,
        ));
      case _Freq.custom:
      // Custom RRULE entry is deferred to a later phase; advanced
      // users with unusual schedules are a small audience for v1.0.
        Navigator.of(context).pop<ItemTime>(null);
    }
  }

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
            Center(child: Text('RECURRENCE', style: AppTypography.eyebrow)),
            const SizedBox(height: AppSpacing.md),
            _FreqRow(
              label: 'No recurrence',
              selected: _freq == _Freq.none,
              onTap: () => setState(() => _freq = _Freq.none),
            ),
            const SizedBox(height: AppSpacing.sm),
            _FreqRow(
              label: 'Daily',
              selected: _freq == _Freq.daily,
              onTap: () => setState(() => _freq = _Freq.daily),
            ),
            const SizedBox(height: AppSpacing.sm),
            _FreqRow(
              label: 'Weekly',
              selected: _freq == _Freq.weekly,
              onTap: () => setState(() => _freq = _Freq.weekly),
            ),
            if (_freq == _Freq.weekly) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              _WeekdayGrid(
                selected: _weekdays,
                onChanged: (Set<String> next) =>
                    setState(() => _weekdays = next),
              ),
            ],
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
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _Freq { none, daily, weekly, custom }

class _FreqRow extends StatelessWidget {
  const _FreqRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.body.copyWith(
                      color: selected
                          ? AppColors.brandDark
                          : AppColors.textPrimary,
                      fontWeight:
                      selected ? FontWeight.w500 : FontWeight.w400,
                    ),
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

class _WeekdayGrid extends StatelessWidget {
  const _WeekdayGrid({required this.selected, required this.onChanged});

  final Set<String> selected;
  final void Function(Set<String>) onChanged;

  static const List<({String code, String label})> _days =
  <({String code, String label})>[
    (code: 'MO', label: 'M'),
    (code: 'TU', label: 'T'),
    (code: 'WE', label: 'W'),
    (code: 'TH', label: 'T'),
    (code: 'FR', label: 'F'),
    (code: 'SA', label: 'S'),
    (code: 'SU', label: 'S'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        for (final d in _days) _DayChip(
          code: d.code,
          label: d.label,
          selected: selected.contains(d.code),
          onTap: () {
            final Set<String> next = <String>{...selected};
            if (next.contains(d.code)) {
              next.remove(d.code);
            } else {
              next.add(d.code);
            }
            onChanged(next);
          },
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const Map<String, String> _accessible = <String, String>{
    'MO': 'Monday', 'TU': 'Tuesday', 'WE': 'Wednesday',
    'TH': 'Thursday', 'FR': 'Friday', 'SA': 'Saturday', 'SU': 'Sunday',
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${_accessible[code]}${selected ? ", selected" : ""}',
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.brandPrimary : AppColors.surfaceTertiary,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: Text(
                label,
                style: AppTypography.body.copyWith(
                  color: selected
                      ? AppColors.surfacePrimary
                      : AppColors.textPrimary,
                  fontWeight:
                  selected ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}