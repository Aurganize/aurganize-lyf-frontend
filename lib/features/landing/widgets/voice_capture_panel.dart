import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// In-panel voice-capture indicator with live transcript and a stop
/// button. Shown in place of the input bar while listening.
class VoiceCapturePanel extends StatefulWidget {
  const VoiceCapturePanel({
    super.key,
    required this.transcript,
    required this.onStop,
  });

  final String transcript;
  final VoidCallback onStop;

  @override
  State<VoiceCapturePanel> createState() => _VoiceCapturePanelState();
}

class _VoiceCapturePanelState extends State<VoiceCapturePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(color: AppColors.surfacePrimary),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.brandLight,
            borderRadius: AppSpacing.borderRadiusPill,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
          child: Row(
            children: <Widget>[
              _ListeningDots(controller: _ctl),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  widget.transcript.isEmpty
                      ? 'Listening…'
                      : widget.transcript,
                  style: AppTypography.body.copyWith(
                    color: AppColors.brandDark,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.fade,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StopButton(onTap: widget.onStop),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three small animated dots that pulse in a wave — a calm "listening"
/// indicator that doesn't compete with the transcript.
class _ListeningDots extends StatelessWidget {
  const _ListeningDots({required this.controller});

  final Animation<double> controller;

  static const int _count = 3;
  static const double _radius = 3;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 16,
      child: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          return CustomPaint(
            painter: _DotsPainter(progress: controller.value),
          );
        },
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter({required this.progress});

  final double progress;

  static const int _count = 3;
  static const double _radius = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()..color = AppColors.brandDark;
    final double spacing = size.width / (_count + 1);
    for (int i = 0; i < _count; i++) {
      final double phase = (progress * 2 * 3.14159) - (i * 0.6);
      // Sin-driven vertical bob — gentle, no jitter.
      final double bob =
          1.0 - 0.5 * (1.0 - _sin(phase).clamp(-1, 1) * 0.5 - 0.5);
      final double y = size.height / 2 - 2 + bob * 4;
      final double x = (i + 1) * spacing;
      // Slight alpha modulation in sync with the bob.
      p.color = AppColors.brandDark.withOpacity(0.5 + bob * 0.5);
      canvas.drawCircle(Offset(x, y), _radius, p);
    }
  }

  double _sin(double v) {
    // dart:math.sin via a local alias avoids importing dart:math when
    // we don't need anything else from it.
    return _localSin(v);
  }

  @override
  bool shouldRepaint(covariant _DotsPainter old) => old.progress != progress;
}

double _localSin(double v) {
  // Tiny Taylor approx good for visualization (≤2% error in the range
  // we use). Beats importing dart:math for the sole purpose.
  // Reduce to [-π, π].
  const double twoPi = 6.283185307179586;
  double x = v - twoPi * (v ~/ twoPi);
  if (x > 3.141592653589793) x -= twoPi;
  if (x < -3.141592653589793) x += twoPi;
  // Bhaskara approximation.
  final double absX = x.abs();
  final double sign = x.isNegative ? -1.0 : 1.0;
  return sign * 16 * absX * (3.141592653589793 - absX) /
      (5 * 3.141592653589793 * 3.141592653589793 - 4 * absX * (3.141592653589793 - absX));
}

class _StopButton extends StatelessWidget {
  const _StopButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Stop listening',
      excludeSemantics: true,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Material(
          color: AppColors.brandPrimary,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const Icon(
              Icons.stop,
              size: 18,
              color: AppColors.surfacePrimary,
            ),
          ),
        ),
      ),
    );
  }
}