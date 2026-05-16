import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Dev-only gallery of the component primitives. Not shipped — guarded
/// behind a debug-only route in `main.dart` (Phase 04). Useful through
/// Phase 03 as we add each widget.
class DevGalleryScreen extends StatelessWidget {
  const DevGalleryScreen({super.key, required this.sections});

  /// Each section is rendered as an eyebrow label + an arbitrary widget.
  final List<DevGallerySection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dev gallery')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        itemCount: sections.length,
        separatorBuilder: (_, __) =>
        const SizedBox(height: AppSpacing.xl),
        itemBuilder: (BuildContext context, int index) {
          final DevGallerySection section = sections[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(section.title.toUpperCase(),
                  style: AppTypography.eyebrow),
              const SizedBox(height: AppSpacing.sm),
              if (section.description != null) ...<Widget>[
                Text(section.description!, style: AppTypography.bodyMuted),
                const SizedBox(height: AppSpacing.md),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: AppSpacing.borderRadiusMedium,
                  border: Border.all(
                    color: AppColors.borderDefault,
                    width: 0.5,
                  ),
                ),
                child: section.child,
              ),
            ],
          );
        },
      ),
    );
  }
}

class DevGallerySection {
  const DevGallerySection({
    required this.title,
    required this.child,
    this.description,
  });

  final String title;
  final String? description;
  final Widget child;
}