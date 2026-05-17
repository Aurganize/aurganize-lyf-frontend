import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/auth_providers.dart';

/// Top-of-settings profile card.
///
/// In v1.0 there's no real account — the user-id is a locally-minted UUID
/// (Phase 04 Part 01). We show its short prefix as the "name" and a
/// brand initials avatar. Phase 12 (auth) replaces this with the real
/// display name + photo.
class ProfileCard extends ConsumerWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(currentUserIdProvider).when(
      loading: () => const _ProfileCardSkeleton(),
      error: (Object e, _) => _ProfileCardError(error: e),
      data: (String userId) {
        // First 8 chars of the UUID make a stable, recognizable
        // pseudonym; the full UUID is shown small below for "this is
        // your account" confidence.
        final String shortId = userId.split('-').first;
        final String initials = shortId.substring(0, 2).toUpperCase();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.brandLight,
              borderRadius: AppSpacing.borderRadiusMedium,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.brandPrimary,
                  child: Text(
                    initials,
                    style: AppTypography.body.copyWith(
                      color: AppColors.surfacePrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Local account',
                        style: AppTypography.title.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userId,
                        style: AppTypography.caption.copyWith(
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileCardSkeleton extends StatelessWidget {
  const _ProfileCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0,
      ),
      child: Container(
        height: 76,
        decoration: const BoxDecoration(
          color: AppColors.surfaceTertiary,
          borderRadius: AppSpacing.borderRadiusMedium,
        ),
      ),
    );
  }
}

class _ProfileCardError extends StatelessWidget {
  const _ProfileCardError({required this.error});
  final Object error;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(
        'Couldn\'t load account: $error',
        style: AppTypography.bodyMuted,
      ),
    );
  }
}