import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'onboarding_copy.dart';
import 'onboarding_providers.dart';

/// The first screen the user sees — PDD §12.
///
/// Shown exactly once. After [onboardingCompletedProvider] flips to
/// `true`, the router routes future launches directly to the landing
/// screen.
///
/// ### Navigation contract
///
/// The screen pushes responsibility for "where to go next" onto its
/// host. The widget calls [onGetStarted] after [onboardingCompletedProvider]
/// has been updated. The router consumes the flag change and rebuilds
/// to the landing route; the widget itself does not call `Navigator.of`.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onGetStarted});

  /// Called after [OnboardingCompleted.markComplete] has resolved.
  /// The host (router) is expected to navigate to the landing screen.
  final VoidCallback onGetStarted;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  // Auto-focus the primary action so a connected keyboard can submit
  // via Enter without an extra tab cycle — PDD §12 accessibility.
  final FocusNode _primaryFocusNode = FocusNode();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _primaryFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _primaryFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onGetStarted() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(onboardingCompletedProvider.notifier).markComplete();
      if (mounted) widget.onGetStarted();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            // Spec asks for the brand mark roughly 1/4 down the screen.
            // Compute it from the available height so the layout adapts
            // to small/large screens.
            final double topPadding = constraints.maxHeight * 0.10;
            final double midGap = constraints.maxHeight * 0.05;

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
              ),
              child: Column(
                children: <Widget>[
                  SizedBox(height: topPadding),
                  const _BrandHeader(),
                  SizedBox(height: midGap),
                  const _PrinciplesList(),
                  const Spacer(),
                  _PrimaryAction(
                    focusNode: _primaryFocusNode,
                    busy: _busy,
                    onPressed: _onGetStarted,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _SignInOptionsLine(),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Brand header — logo + name + tagline
// ─────────────────────────────────────────────────────────────────────────────

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // SvgPicture.asset gives us crisp scaling on any DPI.
        // semanticsLabel turns the otherwise decorative graphic into
        // a meaningful element for screen readers.
        SvgPicture.asset(
          'assets/icons/cairn_logo.svg',
          width: 60,
          height: 80,
          semanticsLabel: 'Aurganize lyf logo',
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          OnboardingCopy.appName,
          style: AppTypography.display,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          OnboardingCopy.tagline,
          style: AppTypography.bodyMuted,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// The three principle blocks
// ─────────────────────────────────────────────────────────────────────────────

class _PrinciplesList extends StatelessWidget {
  const _PrinciplesList();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Screen-reader announces this group; each row is a list item.
      container: true,
      explicitChildNodes: true,
      label: 'Three principles',
      child: Column(
        children: <Widget>[
          for (int i = 0; i < OnboardingCopy.principles.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.lg),
            _PrincipleRow(block: OnboardingCopy.principles[i]),
          ],
        ],
      ),
    );
  }
}

class _PrincipleRow extends StatelessWidget {
  const _PrincipleRow({required this.block});

  final PrincipleBlock block;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        label: '${block.heading}, ${block.body}',
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Brand dot — visually similar to the temperature dot but
            // intentionally larger (10px) so it pairs with the heading
            // typography. Decorative-only; the parent Semantics carries
            // the meaning.
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(block.heading, style: AppTypography.heading),
                  const SizedBox(height: 2),
                  Text(block.body, style: AppTypography.bodyMuted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Primary "Get started" action
// ─────────────────────────────────────────────────────────────────────────────

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.focusNode,
    required this.busy,
    required this.onPressed,
  });

  final FocusNode focusNode;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        focusNode: focusNode,
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.surfacePrimary,
            ),
          ),
        )
            : const Text(OnboardingCopy.getStartedLabel),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign-in options line
// ─────────────────────────────────────────────────────────────────────────────

class _SignInOptionsLine extends StatelessWidget {
  const _SignInOptionsLine();

  @override
  Widget build(BuildContext context) {
    return Text(
      OnboardingCopy.signInOptions,
      style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
      textAlign: TextAlign.center,
    );
  }
}