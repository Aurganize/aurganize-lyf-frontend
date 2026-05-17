import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

enum BubbleAlignment { user, assistant }

class ConversationBubble extends StatelessWidget {
  const ConversationBubble({
    super.key,
    required this.alignment,
    required this.child,
    this.maxWidthFraction = 0.85,
    this.borderless = false,
  });

  final BubbleAlignment alignment;
  final Widget child;

  /// Bubbles cap at this fraction of the panel width so a long
  /// capture doesn't stretch edge to edge.
  final double maxWidthFraction;

  /// Assistant bubbles draw a thin border to read as a quiet card.
  /// Inline ConfirmationPeekCard already draws its own chrome — we
  /// pass [borderless: true] in that case.
  final bool borderless;

  @override
  Widget build(BuildContext context) {
    final bool isUser = alignment == BubbleAlignment.user;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth * maxWidthFraction;
        return Row(
          mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: <Widget>[
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: isUser
                      ? AppColors.brandLight
                      : AppColors.surfaceTertiary,
                  borderRadius: _bubbleRadius(isUser),
                  border: borderless || isUser
                      ? null
                      : Border.all(
                    color: AppColors.borderDefault,
                    width: 0.5,
                  ),
                ),
                child: DefaultTextStyle(
                  style: AppTypography.body.copyWith(
                    color: isUser
                        ? AppColors.brandDark
                        : AppColors.textPrimary,
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Asymmetric corners. The tail-side corner is slightly tighter so the
  // bubble reads as anchored to its side of the panel.
  BorderRadius _bubbleRadius(bool isUser) {
    const Radius soft = Radius.circular(14);
    const Radius tight = Radius.circular(4);
    return BorderRadius.only(
      topLeft: soft,
      topRight: soft,
      bottomLeft: isUser ? soft : tight,
      bottomRight: isUser ? tight : soft,
    );
  }
}