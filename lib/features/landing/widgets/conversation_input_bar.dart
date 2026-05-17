import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/enums/capture_source.dart';
import '../../capture/providers/capture_controller.dart';
import '../../capture/providers/conversation_input.dart';

/// The conversation panel's bottom input bar — PDD §15.
///
/// Three regions, left to right:
///   - Mic button (Phase 07 Part 02 wires its action).
///   - Text field with multiline support (1–4 lines, then scrolls).
///   - Send button — brand-filled when the input has content,
///     muted otherwise.
///
/// The bar:
///   - Pulls/pushes its text via [conversationInputProvider].
///   - Sends on tap of send OR on submission via the keyboard's
///     send action (multi-line keyboards typically include a Send
///     glyph; single-line submission is implicit via the bar's
///     `onSubmitted`).
///   - On a successful send, clears the field and re-focuses for
///     the next thought.
///   - On a failure, surfaces the error via the host (we pass an
///     optional [onError] callback for the host to ScaffoldMessenger).
class ConversationInputBar extends ConsumerStatefulWidget {
  const ConversationInputBar({
    super.key,
    required this.onVoiceCapture,
    this.onError,
    this.autofocus = false,
  });

  /// Fired when the user taps the mic button. Phase 07 Part 02 wires
  /// this to the speech_to_text plugin.
  final VoidCallback onVoiceCapture;

  /// Surfaces a submission error to the host. The bar shows nothing
  /// inline beyond restoring the draft; the host typically
  /// `ScaffoldMessenger.showSnackBar(...)`s.
  final void Function(Object error)? onError;

  /// Whether to auto-focus the field when first mounted. Set by the
  /// conversation panel when it opens so the user can type
  /// immediately.
  final bool autofocus;

  @override
  ConsumerState<ConversationInputBar> createState() =>
      _ConversationInputBarState();
}

class _ConversationInputBarState extends ConsumerState<ConversationInputBar> {
  late final TextEditingController _textCtl;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    // Seed the text controller with whatever draft the provider holds.
    // If the user expanded the panel, typed, collapsed, and re-expanded,
    // they expect the draft to still be there.
    final ConversationInputState seed =
    ref.read(conversationInputProvider);
    _textCtl = TextEditingController(text: seed.draft);
    _focusNode = FocusNode();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _textCtl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    ref.read(conversationInputProvider.notifier).setDraft(value);
  }

  Future<void> _submit() async {
    final ConversationInputState s = ref.read(conversationInputProvider);
    if (!s.hasContent || s.isSubmitting) return;

    final String text = s.draft;
    // Clear the field immediately so the user can keep typing — the
    // capture controller's persistence is sub-100ms and shouldn't
    // block.
    _textCtl.clear();
    ref.read(conversationInputProvider.notifier).clear();
    HapticFeedback.lightImpact();

    ref.read(conversationInputProvider.notifier).setSubmitting(true);
    try {
      await ref.read(captureControllerProvider.notifier).submit(
        rawText: text,
        source: CaptureSource.typed,
      );
    } catch (error) {
      // Restore the draft so the user can retry.
      _textCtl.text = text;
      ref.read(conversationInputProvider.notifier).setDraft(text);
      widget.onError?.call(error);
    } finally {
      // Re-focus for the next thought.
      if (mounted) {
        ref.read(conversationInputProvider.notifier).setSubmitting(false);
        _focusNode.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ConversationInputState s = ref.watch(conversationInputProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfacePrimary,
        // No top border — the panel chrome itself provides separation.
      ),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceTertiary,
            borderRadius: AppSpacing.borderRadiusPill,
            border: Border.all(
              color: AppColors.borderDefault,
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              _MicButton(onTap: widget.onVoiceCapture),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _InputField(
                  controller: _textCtl,
                  focusNode: _focusNode,
                  onChanged: _onChanged,
                  onSubmitted: (_) => _submit(),
                  enabled: !s.isSubmitting,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _SendButton(
                enabled: s.hasContent && !s.isSubmitting,
                busy: s.isSubmitting,
                onTap: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subwidgets
// ─────────────────────────────────────────────────────────────────────────────

class _MicButton extends StatelessWidget {
  const _MicButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Voice capture',
      excludeSemantics: true,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const Icon(
              Icons.mic_none_outlined,
              size: 22,
              color: AppColors.iconMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.enabled,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      minLines: 1,
      maxLines: 4,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.send,
      style: AppTypography.body,
      decoration: const InputDecoration(
        // Strip Material defaults: no borders, no fill — we own those.
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        filled: false,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 10,
        ),
        hintText: "What's on your mind?",
        hintStyle: TextStyle(color: AppColors.textTertiary),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = enabled
        ? AppColors.brandPrimary
        : AppColors.surfaceSecondary;
    final Color foreground =
    enabled ? AppColors.surfacePrimary : AppColors.textTertiary;

    return Semantics(
      button: true,
      enabled: enabled,
      label: enabled ? 'Send capture' : 'Send (input is empty)',
      excludeSemantics: true,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Material(
          color: background,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? onTap : null,
            child: busy
                ? Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(foreground),
                ),
              ),
            )
                : Icon(
              Icons.arrow_upward_rounded,
              size: 20,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}