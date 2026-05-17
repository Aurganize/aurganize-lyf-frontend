import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_input.g.dart';

/// State of the conversation panel's input bar.
///
/// We hold the **current draft text** in this provider. The widget
/// owns the [TextEditingController] for cursor/composition reasons,
/// but mirrors the text into this provider on every change so the
/// send button (and Part 02's voice wiring) can read it without a
/// widget reference.
///
/// `keepAlive: true` because the conversation panel is in-screen
/// state — dropping it on a navigation back from `/settings` to `/`
/// would lose the draft.
@Riverpod(keepAlive: true)
class ConversationInput extends _$ConversationInput {
  @override
  ConversationInputState build() => const ConversationInputState();

  /// Set the draft text. Called from the widget's `onChanged`.
  void setDraft(String value) {
    if (state.draft == value) return;
    state = state.copyWith(draft: value);
  }

  /// Clear the draft. Called after a successful send.
  void clear() {
    if (state.draft.isEmpty && !state.isSubmitting) return;
    state = const ConversationInputState();
  }

  /// Mark a submission in flight. Called on tap of send; cleared on
  /// success/failure.
  void setSubmitting(bool value) {
    if (state.isSubmitting == value) return;
    state = state.copyWith(isSubmitting: value);
  }
}

class ConversationInputState {
  const ConversationInputState({
    this.draft = '',
    this.isSubmitting = false,
  });

  final String draft;
  final bool isSubmitting;

  bool get hasContent => draft.trim().isNotEmpty;

  ConversationInputState copyWith({
    String? draft,
    bool? isSubmitting,
  }) {
    return ConversationInputState(
      draft: draft ?? this.draft,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}