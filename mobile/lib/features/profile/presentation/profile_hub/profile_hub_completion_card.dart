import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/profile_completeness.dart';
import '../premium_2026/profile_theme.dart';
import '../providers/profile_hub_providers.dart';

/// Kendi profilinde eksik alan varsa en üstte gösterilen "Profilini Tamamla"
/// kartı — kırmızı eksik sayısı + eksik alanların listesi + Düzenle kısayolu.
/// Profil tamamen doluysa hiçbir şey göstermez.
class ProfileHubCompletionCard extends ConsumerWidget {
  const ProfileHubCompletionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();
    final ext = ref.watch(profileExtendedProvider).valueOrNull;

    final missing = missingProfileItems(
      username: user.username,
      avatarUrl: user.avatarUrl,
      displayName: user.displayName,
      bio: user.bio,
      city: ext?.city,
      zodiac: ext?.zodiacSign,
      favoriteTeam: ext?.favoriteTeam,
    );
    if (missing.isEmpty) return const SizedBox.shrink();

    final percent = profileCompletionPercent(missing.length);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: ProfilePremiumTheme.deepBg.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(ProfilePremiumTheme.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(ProfilePremiumTheme.radiusLg),
          onTap: () => context.push('/profile/edit'),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ProfilePremiumTheme.radiusLg),
              border: Border.all(
                color: AppThemeColors.accentPink.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_circle_rounded,
                      color: AppThemeColors.accentPink,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Profilini Tamamla',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '%$percent tamamlandı · ${missing.length} eksik',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Kırmızı eksik sayısı.
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppThemeColors.liveRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${missing.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white54,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation(
                      AppThemeColors.accentPink,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in missing)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppThemeColors.liveRed.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              size: 14,
                              color: AppThemeColors.accentPink,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
