import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../moderation/domain/entities/report_target.dart';
import '../../../moderation/presentation/utils/open_report_flow.dart';
import '../providers/profile_providers.dart';

class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(userId));

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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              DiscoverGlassCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.brandGradient,
                      ),
                      child: UserAvatar(url: user.avatarUrl, radius: 36),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.display,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '@${user.username}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              DiscoverGlassCard(
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
              const SizedBox(height: 20),
              FilledButton(
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
                      : AppColors.accentPink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  user.isFollowing ? 'Takipten çık' : 'Takip et',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (user.bio != null && user.bio!.isNotEmpty) ...[
                const SizedBox(height: 14),
                DiscoverGlassCard(
                  child: Text(
                    user.bio!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
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
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ],
    );
  }
}
