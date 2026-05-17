import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/enums/temperature.dart';
import '../../../domain/models/item_time.dart';
import '../../../shared/widgets/temperature_dot.dart';

/// A leftover-view row — PDD §20.
///
/// Renders an item with three inline action buttons:
///   - Done (brand-filled)
///   - Today (outlined)
///   - Skip (outlined)
///
/// On any action, [_animateOut] runs (180 ms slide-up + fade), then
/// the corresponding callback fires. The parent removes the row from
/// the list; this widget is no longer in the tree by the time the
/// callback's database write completes.
class LeftoverRow extends StatefulWidget {
  const LeftoverRow({
    super.key,
    required this.title,
    required this.temperature,
    required this.time,
    required this.onDone,
    required this.onToday,
    required this.onSkip,
  });

  final String title;
  final Temperature temperature;
  final ItemTime time;
  final Future<void> Function() onDone;
  final Future<void> Function() onToday;
  final Future<void> Function() onSkip;

  @override
  State<LeftoverRow> createState() => _LeftoverRowState();
}

class _LeftoverRowState extends State<LeftoverRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: AppMotion.dismiss,
    );
    _opacity = Tween<double>(begin: 1, end: 0).animate(_ctl);
    _offset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.4),
    ).animate(CurvedAnimation(parent: _ctl, curve: AppMotion.dismissCurve));
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    await _ctl.forward();
    await action(); // the row is already animated out; the parent
    // will remove it on the next stream emission.
  }

  String? _timeHint() {
    return widget.time.when<String?>(
      hardTime: (DateTime at, _) {
        final DateTime local = at.toLocal();
        return '${local.hour.toString().padLeft(2, "0")}:'
            '${local.minute.toString().padLeft(2, "0")}';
      },
      timeWindow: (DateTime? _, DateTime until) {
        final DateTime u = until.toLocal();
        return 'by ${u.month}/${u.day}';
      },
      recurring: (_, __, ___) => 'recurring',
      untimed: () => null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? hint = _timeHint();
    return AnimatedBuilder(
      animation: _ctl,
      builder: (BuildContext context, Widget? child) {
        return Opacity(
          opacity: _opacity.value,
          child: FractionalTranslation(
            translation: _offset.value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: AppSpacing.borderRadiusMedium,
          border: Border.all(
            color: AppColors.borderDefault,
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                TemperatureDot(temperature: widget.temperature),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(widget.title, style: AppTypography.body),
                      if (hint != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(hint, style: AppTypography.caption),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: _ActionPill.filled(
                    label: 'Done',
                    onTap: () => _runAction(widget.onDone),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ActionPill.outlined(
                    label: 'Today',
                    onTap: () => _runAction(widget.onToday),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ActionPill.outlined(
                    label: 'Skip',
                    onTap: () => _runAction(widget.onSkip),
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

/// A pill button used inside the leftover row. Two flavors; visually
/// distinct but both 36 px tall (slightly under the 48 px minimum
/// because the row's outer card is itself a generous tap target — the
/// PDD's three-buttons-per-row layout doesn't fit 48 px buttons at
/// typical phone widths).
class _ActionPill extends StatelessWidget {
  const _ActionPill._({
    required this.label,
    required this.onTap,
    required this.filled,
  });

  factory _ActionPill.filled({
    required String label,
    required VoidCallback onTap,
  }) {
    return _ActionPill._(label: label, onTap: onTap, filled: true);
  }

  factory _ActionPill.outlined({
    required String label,
    required VoidCallback onTap,
  }) {
    return _ActionPill._(label: label, onTap: onTap, filled: false);
  }

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: filled
            ? AppColors.brandPrimary
            : AppColors.surfacePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusPill,
          side: filled
              ? BorderSide.none
              : const BorderSide(color: AppColors.borderStrong, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 36,
            child: Center(
              child: Text(
                label,
                style: AppTypography.body.copyWith(
                  color: filled
                      ? AppColors.surfacePrimary
                      : AppColors.brandPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}