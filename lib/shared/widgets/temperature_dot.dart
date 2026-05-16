import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/enums/temperature.dart';

/// A 7-pixel circle encoding the item's [Temperature].
///
/// PDD §9.2 — appears on every plan item row, left of the title.
/// Never used elsewhere in the UI — this is *the* temperature affordance.
///
/// ### Accessibility
///
/// The dot is wrapped in a [Semantics] node whose label reads as
/// "hot temperature" / "warm temperature" / "cool temperature".
/// The label sits on the dot itself so that when it's read as part of
/// a plan-item row (`{title}, {time hint}, {temperature label}, button`),
/// the row's `MergeSemantics` collapses everything into one utterance.
///
/// ### Painting
///
/// Implemented via a [CustomPaint] rather than a [DecoratedBox] +
/// [BoxDecoration]. The CustomPaint draws a single antialiased circle
/// without composing through a layer tree, which matters because this
/// widget appears 6–15 times per visible screen and we want the
/// per-row paint cost as small as possible.
class TemperatureDot extends StatelessWidget {
  const TemperatureDot({
    super.key,
    required this.temperature,
    this.size = AppSpacing.temperatureDotSize,
  });

  final Temperature temperature;

  /// Diameter in logical pixels. Defaults to the PDD-mandated 7px and
  /// should not be customized in production. The parameter exists so
  /// the dev gallery can render an oversized variant for visual review.
  final double size;

  Color get _color {
    return switch (temperature) {
      Temperature.hot => AppColors.tempHot,
      Temperature.warm => AppColors.tempWarm,
      Temperature.cool => AppColors.tempCool,
    };
  }

  String get _semanticsLabel {
    return switch (temperature) {
      Temperature.hot => 'hot temperature',
      Temperature.warm => 'warm temperature',
      Temperature.cool => 'cool temperature',
    };
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary keeps repaints of the dot from invalidating the
    // surrounding row — relevant when, say, the row's "done" check
    // toggles and would otherwise re-rasterize the dot too.
    return RepaintBoundary(
      child: Semantics(
        label: _semanticsLabel,
        excludeSemantics: true,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _DotPainter(color: _color)),
        ),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  const _DotPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final double radius = size.shortestSide / 2;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DotPainter old) => old.color != color;
}