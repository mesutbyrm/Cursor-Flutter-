import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/premium_2026/premium_2026.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../moderation/domain/entities/report_target.dart';
import '../../../moderation/presentation/utils/open_report_flow.dart';
import '../providers/profile_providers.dart';
import '../widgets/user_posts_tiktok_grid.dart';

class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(userId));
    final me = ref.watch(authControllerProvider).valueOrNull;
    final isSelf = me != null && me.id == userId;

    return DiscoverSubPage(
      title: 'Kullanıcı',
      subtitle: 'Profil detayı',
      actions: [
        DiscoverIconButton(
          icon: Icons.flag_outlined,
          tooltip: 'Bildir',
          onPressed: () => openReportFlow(
            context,
            ReportTarget(
              type: ReportTargetType.user,
              targetId: userId,
              displayTitle: 'Kullanıcı profili',
            ),
          ),
        ),
      ],
      body: userAsync.when(
        loading: () => const DiscoverAccentLoader(),
        error: (e, _) => DiscoverEmptyState(
          icon: Icons.person_off_outlined,
          message: e.toString(),
        ),
        data: (user) {
          return ListView(
            physics: PremiumMotion.listPhysics,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              LiquidGlassCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: context.colors.brandGradient,
                      ),
                      child: UserAvatar(url: user.avatarUrl, radius: 36),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.display,
                            style: PremiumTypography.headline(context),
                          ),
                          Text(
                            '@${user.username}',
                            style: TextStyle(
                              color: context.colors.onSurfaceMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14),
              LiquidGlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Stat(label: 'Takipçi', value: '${user.followersCount}'),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    _Stat(label: 'Takip', value: '${user.followingCount}'),
                  ],
                ),
              ),
              SizedBox(height: 20),
              if (!isSelf) ...[
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          final repo = ref.read(profileRepositoryProvider);
                          if (user.isFollowing) {
                            await repo.unfollow(user.id);
                          } else {
                            await repo.follow(user.id);
                          }
                          ref.invalidate(userProfileProvider(userId));
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: user.isFollowing
                              ? Colors.white.withValues(alpha: 0.12)
                              : AppThemeColors.accentPink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          user.isFollowing ? 'Takipten çık' : 'Takip et',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _openDirectMessage(context, ref),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          foregroundColor: AppThemeColors.accentCyan,
                          side: BorderSide(
                            color: AppThemeColors.accentCyan.withValues(alpha: 0.65),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Mesaj',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else
                FilledButton(
                  onPressed: null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    disabledBackgroundColor:
                        Colors.white.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Bu sizin profiliniz',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              if (user.bio != null && user.bio!.isNotEmpty) ...[
                SizedBox(height: 14),
                LiquidGlassCard(
                  child: Text(
                    user.bio!,
                    style: PremiumTypography.body(context).copyWith(
                      height: 1.45,
                    ),
                  ),
                ),
              ],
              SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.grid_on_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Paylaşımlar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              UserPostsTikTokGrid(userId: userId),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openDirectMessage(BuildContext context, WidgetRef ref) async {
    context.push('/chat/$userId');
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: context.colors.onSurfaceMuted, fontSize: 13),
        ),
      ],
    );
  }
}
