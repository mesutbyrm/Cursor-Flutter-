import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/user_avatar.dart';
import '../../../feed/domain/entities/platform_stats_entity.dart';
import '../../../feed/presentation/providers/platform_stats_providers.dart';
import '../theme/home_approved_design.dart';
import 'approved/home_section_title.dart';

/// Son giriş yapanlar — `GET /api/public-stats` → `recentLogins`.
class HomeRecentLoginsSection extends ConsumerWidget {
  const HomeRecentLoginsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(platformStatsProvider);
    return stats.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        final logins = data.recentLogins;
        if (logins.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            HomeSectionTitle(
              emoji: '👋',
              title: 'Son Girişler',
              actionLabel: 'Sosyal >',
              onAction: () => context.push('/social'),
            ),
            SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: HomeApprovedDesign.hPad,
                ),
                itemCount: logins.length.clamp(0, 8),
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _LoginChip(login: logins[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LoginChip extends StatelessWidget {
  const _LoginChip({required this.login});

  final RecentLoginEntity login;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  HomeApprovedDesign.purple.withValues(alpha: 0.9),
                  HomeApprovedDesign.pink.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: UserAvatar(url: login.user.avatarUrl, radius: 26),
          ),
          const SizedBox(height: 6),
          Text(
            login.user.display,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: HomeApprovedDesign.textPrimary,
            ),
          ),
          Text(
            login.timeLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              color: HomeApprovedDesign.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
