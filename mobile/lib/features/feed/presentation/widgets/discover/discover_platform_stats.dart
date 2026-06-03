import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/user_avatar.dart';
import '../../../domain/entities/platform_stats_entity.dart';
import '../../providers/platform_stats_providers.dart';
import 'discover_section_header.dart';

/// Ana sayfa — canlı istatistik kartları + son girişler (mockup).
class DiscoverPlatformStats extends ConsumerWidget {
  const DiscoverPlatformStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(platformStatsProvider);

    return stats.when(
      loading: () => const _StatsSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DiscoverSectionHeader(
            title: 'Canlı İstatistikler',
            actionLabel: '',
            onAction: null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _StatsGrid(stats: data),
          ),
          const SizedBox(height: 16),
          _RecentLoginsSection(logins: data.recentLogins),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final PlatformStatsEntity stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(
        icon: Icons.groups_rounded,
        color: const Color(0xFFB832FF),
        value: stats.onlineUsers,
        title: 'Kişi Sayısı',
        subtitle: 'Şu anda çevrimiçi',
      ),
      _StatItem(
        icon: Icons.sports_esports_rounded,
        color: const Color(0xFFFF8A3D),
        value: stats.inGames,
        title: 'Oyunlarda',
        subtitle: 'Oyun oynayanlar',
      ),
      _StatItem(
        icon: Icons.people_rounded,
        color: const Color(0xFFFF4D8D),
        value: stats.inSocial,
        title: 'Sosyalde',
        subtitle: 'Sohbet edenler',
      ),
      _StatItem(
        icon: Icons.sensors_rounded,
        color: const Color(0xFFFF3D5C),
        value: stats.onLive,
        title: 'Canlı Yayında',
        subtitle: 'Yayında olanlar',
      ),
      _StatItem(
        icon: Icons.mic_rounded,
        color: const Color(0xFF4DA6FF),
        value: stats.inVoiceChat,
        title: 'Sesli Sohbetlerde',
        subtitle: 'Sesli sohbette olanlar',
      ),
      _StatItem(
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFF9B5CFF),
        value: stats.fortuneActive,
        title: 'Fal Baktıranlar',
        subtitle: 'Fal baktıran kullanıcılar',
      ),
      _StatItem(
        icon: Icons.directions_walk_rounded,
        color: const Color(0xFF3DFF8A),
        value: stats.browsing,
        title: 'Dolaşanlar',
        subtitle: 'Sitede gezenler',
      ),
      _StatItem(
        icon: Icons.trending_up_rounded,
        color: const Color(0xFFFFD54F),
        value: stats.todayLogins,
        title: 'Bugünkü Giriş',
        subtitle: 'Bugün siteye girenler',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        const cols = 4;
        final tileW =
            (constraints.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(width: tileW, child: _StatCard(item: item)),
          ],
        );
      },
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final int value;
  final String title;
  final String subtitle;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final _StatItem item;

  static String _formatCount(int n) {
    if (n >= 10000) {
      final k = n / 1000;
      return '${k.toStringAsFixed(k >= 100 ? 0 : 1)}K'.replaceAll('.0K', 'K');
    }
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1).replaceAll('.0', '')}K';
    }
    return _withDots(n);
  }

  static String _withDots(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF140A24).withValues(alpha: 0.92),
        border: Border.all(color: item.color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: item.color, width: 1.5),
                  color: item.color.withValues(alpha: 0.12),
                ),
                child: Icon(item.icon, color: item.color, size: 15),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatCount(item.value),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: item.color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            item.subtitle,
            style: TextStyle(
              fontSize: 8,
              color: context.colors.onSurfaceMuted.withValues(alpha: 0.9),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentLoginsSection extends StatelessWidget {
  const _RecentLoginsSection({required this.logins});

  final List<RecentLoginEntity> logins;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFF12081F).withValues(alpha: 0.88),
          border: Border.all(
            color: AppThemeColors.accentPurple.withValues(alpha: 0.28),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: AppThemeColors.accentCyan.withValues(alpha: 0.95),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Son 5 Giriş Yapan',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/social'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Tümünü Gör >',
                    style: TextStyle(
                      color: AppThemeColors.accentPurple.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (logins.isEmpty)
              Text(
                'Henüz giriş kaydı yok.',
                style: TextStyle(
                  color: context.colors.onSurfaceMuted.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              )
            else
              SizedBox(
                height: 118,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: logins.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final login = logins[i];
                    return _RecentLoginChip(login: login);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecentLoginChip extends StatelessWidget {
  const _RecentLoginChip({required this.login});

  final RecentLoginEntity login;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: context.colors.brandGradient,
            ),
            child: UserAvatar(url: login.user.avatarUrl, radius: 28),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  login.user.display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              if (login.verified) ...[
                const SizedBox(width: 2),
                const Icon(
                  Icons.verified_rounded,
                  size: 12,
                  color: Color(0xFF4DA6FF),
                ),
              ],
            ],
          ),
          Text(
            login.timeLabel,
            style: TextStyle(
              fontSize: 9,
              color: context.colors.onSurfaceMuted.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(login.activityEmoji, style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  login.activityLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppThemeColors.accentPurple.withValues(alpha: 0.95),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppThemeColors.accentPurple.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
