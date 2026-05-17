import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';

part 'conversation_stage.g.dart';

/// Where the conversation panel is in its raise/collapse lifecycle.
///
/// The widget tree consults this to lay out the panel and dim the plan.
enum ConversationStageState {
  collapsed,
  expanding,
  expanded,
  collapsing,
}

/// Pure-state notifier for the conversation panel's open/close gesture.
///
/// `keepAlive: true` so a back-button dismiss followed by another tap
/// preserves the controller; auto-disposing would re-create the
/// notifier each rebuild and lose any pending animation state.
@Riverpod(keepAlive: true)
class ConversationStage extends _$ConversationStage {
  @override
  ConversationStageState build() => ConversationStageState.collapsed;

  /// Begin opening the panel. Called by the island's onExpand.
  void expand() {
    if (state == ConversationStageState.collapsed) {
      state = ConversationStageState.expanding;
    }
  }

  /// Begin closing the panel.
  void collapse() {
    if (state == ConversationStageState.expanded) {
      state = ConversationStageState.collapsing;
    }
  }

  /// Reach a steady-state after an animation completes. The animated
  /// shell calls this; consumers don't.
  void settle({required bool expanded}) {
    state = expanded
        ? ConversationStageState.expanded
        : ConversationStageState.collapsed;
  }

  bool get isOpen =>
      state == ConversationStageState.expanded ||
          state == ConversationStageState.expanding;
}

/// Stage shell that hosts the landing content underneath and the
/// conversation panel above. Manages the open/close animation,
/// dimming, focus, and back-gesture interception.
///
/// Render the landing content (header, date train, today peek, island)
/// as [planContent]. When the panel is open, the shell:
///   - Dims [planContent] to 35% opacity.
///   - Blocks taps on [planContent] (touch passes through to the
///     barrier scrim instead, which closes the panel).
///   - Raises the panel from the bottom into the lower ~55% of the
///     visible height.
///   - Intercepts the system back button so the back gesture closes
///     the panel instead of popping the route.
class ConversationStageShell extends ConsumerStatefulWidget {
  const ConversationStageShell({
    super.key,
    required this.planContent,
    required this.panelBody,
  });

  /// The landing screen's regular content — header, train, peek, island.
  final Widget planContent;

  /// What the panel hosts. In v1.0 Phase 07 fills this with the
  /// chat history + input bar; in this part we ship a placeholder.
  final Widget panelBody;

  @override
  ConsumerState<ConversationStageShell> createState() => _ConversationStageShellState();
}

class _ConversationStageShellState extends ConsumerState<ConversationStageShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _curve;
  late final Animation<double> _scrimOpacity;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: AppMotion.reveal,
      reverseDuration: AppMotion.dismiss,
    );
    // The position curve uses easeOut on open (settling at the top),
    // easeIn on close (accelerating off-screen).
    _curve = CurvedAnimation(
      parent: _ctl,
      curve: AppMotion.revealCurve,
      reverseCurve: AppMotion.dismissCurve,
    );
    // The scrim opacity rides the same curve but is slightly muted
    // — the plan never goes fully behind the scrim, it dims.
    _scrimOpacity = Tween<double>(begin: 0, end: 0.65).animate(_curve);

    _ctl.addStatusListener(_onStatusChanged);


  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      ref.read(conversationStageProvider.notifier).settle(expanded: true);
    } else if (status == AnimationStatus.dismissed) {
      ref.read(conversationStageProvider.notifier).settle(expanded: false);
    }
  }

  @override
  void dispose() {
    _ctl
      ..removeStatusListener(_onStatusChanged)
      ..dispose();
    super.dispose();
  }

  /// Drives the animation forward/reverse based on the desired state.
  void _syncToState(ConversationStageState desired) {
    switch (desired) {
      case ConversationStageState.expanding:
        if (!_ctl.isAnimating && _ctl.status != AnimationStatus.completed) {
          _ctl.forward();
        }
        break;
      case ConversationStageState.collapsing:
        if (!_ctl.isAnimating && _ctl.status != AnimationStatus.dismissed) {
          _ctl.reverse();
        }
        break;
      case ConversationStageState.expanded:
        _ctl.value = 1; // already there
        break;
      case ConversationStageState.collapsed:
        _ctl.value = 0; // already there
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen so we drive the controller when the state-notifier flips.
    ref.listen<ConversationStageState>(
      conversationStageProvider,
          (ConversationStageState? prev, ConversationStageState curr) {
        if (prev == curr) return;
        _syncToState(curr);
      },
    );

    final ConversationStageState current = ref.watch(conversationStageProvider);

    // PopScope intercepts the system back button.
    return PopScope(
      canPop: current == ConversationStageState.collapsed,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (didPop) return;
        // Back was pressed while expanded — collapse instead of popping.
        ref.read(conversationStageProvider.notifier).collapse();
      },
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double panelHeight = constraints.maxHeight * 0.55;
          return Stack(
            children: <Widget>[
              // ── Plan content underneath — dims and disables hit testing ──
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _curve,
                  builder: (BuildContext context, Widget? child) {
                    final double opacity = 1 - (_curve.value * 0.65);
                    return IgnorePointer(
                      ignoring: current != ConversationStageState.collapsed,
                      child: Opacity(opacity: opacity, child: child),
                    );
                  },
                  child: widget.planContent,
                ),
              ),

              // ── Scrim — tap-outside-to-close ─────────────────────────────
              AnimatedBuilder(
                animation: _scrimOpacity,
                builder: (BuildContext context, Widget? child) {
                  if (_scrimOpacity.value == 0) return const SizedBox.shrink();
                  return Positioned.fill(
                    child: IgnorePointer(
                      ignoring: current == ConversationStageState.collapsed,
                      child: GestureDetector(
                        onTap: () {
                          ref
                              .read(conversationStageProvider.notifier)
                              .collapse();
                        },
                        child: Container(
                          color: AppColors.scrim
                              .withAlpha((255 * _scrimOpacity.value).round()),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // // ── Panel ────────────────────────────────────────────────────
              AnimatedBuilder(
                animation: _curve,
                builder: (BuildContext context, Widget? child) {

                  final double dy = (1 - _curve.value) * panelHeight;
                  return Transform.translate(
                    offset: Offset(
                      0,
                      (1 - _curve.value) * panelHeight,
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        height: panelHeight,
                        width: double.infinity,
                        child: child,
                      ),
                    ),
                  );
                },
                child: _PanelChrome(
                  body: widget.panelBody,
                  onDragDismiss: () => ref
                      .read(conversationStageProvider.notifier)
                      .collapse(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The panel's white card chrome — rounded top corners, drag handle,
/// and the body the host supplied.
class _PanelChrome extends StatefulWidget {
  const _PanelChrome({required this.body, required this.onDragDismiss});

  final Widget body;
  final VoidCallback onDragDismiss;

  @override
  State<_PanelChrome> createState() => _PanelChromeState();
}

class _PanelChromeState extends State<_PanelChrome> {
  // Track drag distance. Past ~80 px downward, treat it as a dismiss.
  double _dragOffset = 0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfacePrimary,
      borderRadius: AppSpacing.borderRadiusSheetTop,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (DragUpdateDetails details) {
              setState(() {
                _dragOffset =
                    (_dragOffset + details.delta.dy).clamp(0.0, 240.0);
              });
            },
            onVerticalDragEnd: (DragEndDetails details) {
              if (_dragOffset > 80 || details.primaryVelocity != null &&
                  details.primaryVelocity! > 700) {
                widget.onDragDismiss();
              }
              setState(() => _dragOffset = 0);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: widget.body),
        ],
      ),
    );
  }
}