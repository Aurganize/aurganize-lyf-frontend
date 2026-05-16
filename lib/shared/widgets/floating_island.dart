import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// The three contextual labels the floating island can carry — PDD §9.5.
enum IslandLabelMode {
  capturePrompt,
  savedParsing,
  cardsReady,
}

/// The collapsed floating island — PDD §9.5 / §13–§15.
///
/// Renders as a 280×42 brand-filled pill anchored at the bottom of the
/// landing screen. The body and the trailing mic are two distinct
/// tap targets:
///
///   - Body tap → [onExpand] — opens the conversation panel.
///   - Mic tap  → [onVoiceCapture] — begins voice capture inline.
///
/// ### The "saved — parsing" pulse
///
/// When [mode] is [IslandLabelMode.savedParsing], the body opacity
/// pulses subtly (0.7 → 1.0 → 0.7) at a slow rate to communicate
/// background work. The animation respects reduced-motion.
///
/// ### Expansion
///
/// This widget owns *no* expansion animation. Expansion is a screen-
/// level concern: the panel in Phase 07 will host a `Hero` or an
/// `AnimatedSwitcher` that morphs the island into the panel. This
/// widget's job is to fire [onExpand] cleanly and let the parent
/// handle the choreography.
class FloatingIsland extends StatefulWidget {
  const FloatingIsland({
    super.key,
    required this.mode,
    this.cardCount = 0,
    this.onExpand,
    this.onVoiceCapture,
  });

  final IslandLabelMode mode;

  /// Number of cards awaiting confirmation. Only consulted when
  /// [mode] is [IslandLabelMode.cardsReady].
  final int cardCount;

  final VoidCallback? onExpand;
  final VoidCallback? onVoiceCapture;

  @override
  State<FloatingIsland> createState() => _FloatingIslandState();
}

class _FloatingIslandState extends State<FloatingIsland>
    with SingleTickerProviderStateMixin {
  // The pulse animation for the saved-parsing mode. Slow, breathable,
  // reverses on completion.
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _pulseAnim = Tween<double>(
      begin: 1,
      end: 0.72,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateAnimationForMode();
  }

  @override
  void didUpdateWidget(covariant FloatingIsland old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) {
      _updateAnimationForMode();
    }
  }

  void _updateAnimationForMode() {
    final bool shouldPulse = widget.mode == IslandLabelMode.savedParsing;
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (shouldPulse && !reduced) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Label resolution ─────────────────────────────────────────────────────

  String _resolveLabel() {
    return switch (widget.mode) {
      IslandLabelMode.capturePrompt => "What's on your mind?",
      IslandLabelMode.savedParsing => 'Saved — parsing…',
      IslandLabelMode.cardsReady => widget.cardCount == 1
          ? '1 card ready'
          : '${widget.cardCount} cards ready',
    };
  }

  String _resolveSemantics() {
    return switch (widget.mode) {
      IslandLabelMode.capturePrompt =>
      'Capture an intention. Double-tap to open. Trailing button: voice capture.',
      IslandLabelMode.savedParsing =>
      'Your capture is saved and being organized. Double-tap to open conversation.',
      IslandLabelMode.cardsReady => widget.cardCount == 1
          ? 'One parsed card ready. Double-tap to open conversation.'
          : '${widget.cardCount} parsed cards ready. Double-tap to open conversation.',
    };
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSpacing.floatingIslandWidth,
      height: AppSpacing.floatingIslandHeight,
      child: Stack(
        children: <Widget>[
          // The body — a full-pill tap target. Behind everything visually,
          // so its ripple paints under the mic.
          Positioned.fill(child: _IslandBody(
            label: _resolveLabel(),
            semanticsLabel: _resolveSemantics(),
            pulse: _pulseAnim,
            mode: widget.mode,
            onTap: widget.onExpand,
          )),
          // The mic — sits over the right edge of the body. Its own
          // tap target, its own semantics. Painted on top so taps land
          // on the mic when they fall on the icon.
          Positioned(
            top: 0,
            bottom: 0,
            right: 4,
            child: Center(
              child: _MicAffordance(onTap: widget.onVoiceCapture),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body — sparkle + label + brand pill
// ─────────────────────────────────────────────────────────────────────────────

class _IslandBody extends StatelessWidget {
  const _IslandBody({
    required this.label,
    required this.semanticsLabel,
    required this.pulse,
    required this.mode,
    this.onTap,
  });

  final String label;
  final String semanticsLabel;
  final Animation<double> pulse;
  final IslandLabelMode mode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: AppColors.brandPrimary,
        borderRadius: AppSpacing.borderRadiusPill,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap?.call();
          },
          splashColor: AppColors.brandDark.withValues(alpha: 0.25),
          highlightColor: AppColors.brandDark.withValues(alpha: 0.15),
          child: Padding(
            // Right padding accounts for the mic affordance, so the
            // label doesn't visually collide with it.
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              48,
              0,
            ),
            child: AnimatedBuilder(
              animation: pulse,
              builder: (BuildContext context, Widget? child) {
                return Opacity(
                  opacity: mode == IslandLabelMode.savedParsing
                      ? pulse.value
                      : 1,
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: AppColors.surfacePrimary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: AppMotion.effectiveStateChange(context),
                      switchInCurve: AppMotion.stateChangeCurve,
                      switchOutCurve: AppMotion.stateChangeCurve,
                      child: Text(
                        label,
                        key: ValueKey<String>(label),
                        style: AppTypography.bodyOnBrand,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Mic affordance — translucent circle on the right edge
// ─────────────────────────────────────────────────────────────────────────────

class _MicAffordance extends StatelessWidget {
  const _MicAffordance({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // The visual circle is 34×34; the tap target is 48×48 (transparent ring).
    return Semantics(
      button: true,
      label: 'Voice capture',
      excludeSemantics: true,
      child: SizedBox(
        width: AppSpacing.minTouchTarget,
        height: AppSpacing.minTouchTarget,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap?.call();
            },
            child: Center(
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfacePrimary.withValues(alpha: 0.18),
                ),
                child: const Icon(
                  Icons.mic_none_outlined,
                  size: 18,
                  color: AppColors.surfacePrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}