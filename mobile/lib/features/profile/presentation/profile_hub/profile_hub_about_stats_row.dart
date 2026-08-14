import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/profile_extended_entity.dart';
import '../../domain/entities/profile_stats_entity.dart';
import '../../../membership/presentation/controllers/membership_controller.dart';
import '../premium_2026/profile_membership_helpers.dart';
import '../providers/profile_hub_providers.dart';
import '../widgets/premium/profile_glass.dart';
import '../premium_2026/profile_theme.dart';

/// Hakkımda + İstatistiklerim — iki sütun.
class ProfileHubAboutStatsRow extends ConsumerWidget {
  const ProfileHubAboutStatsRow({
    super.key,
    required this.user,
    required this.stats,
  });

  final UserEntity user;
  final ProfileStatsEntity stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extAsync = ref.watch(profileExtendedProvider);
    final statsAsync = ref.watch(profileUserStatisticsProvider);
    final ext = extAsync.valueOrNull ?? const ProfileExtendedEntity();
    final detail = statsAsync.valueOrNull ?? const ProfileUserStatisticsEntity();

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 600;
        final about = _AboutCard(user: user, ext: ext, loading: extAsync.isLoading);
        final statistics = _StatisticsCard(
          stats: stats,
          detail: detail,
          loading: statsAsync.isLoading,
        );
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: about),
              const SizedBox(width: 12),
              Expanded(child: statistics),
            ],
          );
        }
        return Column(
          children: [
            about,
            const SizedBox(height: 12),
            statistics,
          ],
        );
      },
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({
    required this.user,
    required this.ext,
    required this.loading,
  });

  final UserEntity user;
  final ProfileExtendedEntity ext;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ProfileGlass(
      padding: const EdgeInsets.all(16),
      borderRadius: ProfilePremiumTheme.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Hakkımda',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/profile/edit'),
                child: const Text('Düzenle'),
              ),
            ],
          ),
          if (loading)
            const PremiumSkeleton(height: 80, width: double.infinity)
          else ...[
            if (user.bio != null && user.bio!.trim().isNotEmpty)
              Text(
                user.bio!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 10),
            if (ext.city != null && ext.city!.trim().isNotEmpty)
              _InfoRow(Icons.location_on_rounded, ext.city!),
            if (ext.zodiacSign != null && ext.zodiacSign!.trim().isNotEmpty)
              _InfoRow(Icons.star_rounded, _zodiacTr(ext.zodiacSign!)),
            if (ext.birthDate != null)
              _InfoRow(
                Icons.cake_rounded,
                DateFormat('d MMMM yyyy', 'tr').format(ext.birthDate!.toLocal()),
              ),
            if (ext.joinedAt != null)
              _InfoRow(
                Icons.calendar_month_rounded,
                'Üyelik: ${DateFormat('d MMMM yyyy', 'tr').format(ext.joinedAt!.toLocal())}',
              ),
          ],
        ],
      ),
    );
  }
}

String _zodiacTr(String raw) {
  final value = raw.trim();
  final key = value.toLowerCase();
  return switch (key) {
    'aries' => 'Koç',
    'taurus' => 'Boğa',
    'gemini' => 'İkizler',
    'cancer' => 'Yengeç',
    'leo' => 'Aslan',
    'virgo' => 'Başak',
    'libra' => 'Terazi',
    'scorpio' => 'Akrep',
    'sagittarius' => 'Yay',
    'capricorn' => 'Oğlak',
    'aquarius' => 'Kova',
    'pisces' => 'Balık',
    _ => value,
  };
}

class _StatisticsCard extends ConsumerWidget {
  const _StatisticsCard({
    required this.stats,
    required this.detail,
    required this.loading,
  });

  final ProfileStatsEntity stats;
  final ProfileUserStatisticsEntity detail;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(profileMembershipInfoProvider);
    final ui = ref.watch(membershipControllerProvider);
    final catalogTier = catalogTierForMembership(membership, ui.tiers);
    final planDurationValue = membership.isExpired
        ? 'Yenile'
        : membership.hasActiveSubscription &&
                membership.daysRemaining != null &&
                membership.daysRemaining! > 0
            ? catalogTier != null &&
                    catalogTier.durationDays > 0 &&
                    catalogTier.durationDays != 30
                ? '${membership.daysRemaining} / ${catalogTier.durationDays} gün'
                : '${membership.daysRemaining} gün'
            : catalogTier != null && catalogTier.durationDays > 0
                ? catalogTier.durationLabel
                : '—';
    final rows = <({IconData icon, String label, String value})>[
      (
        icon: Icons.workspace_premium_outlined,
        label: 'Üyelik Planı',
        value: membership.isExpired
            ? 'Süresi doldu'
            : membership.hasPaidTier
                ? membership.tierLabel
                : 'Standart',
      ),
      (
        icon: Icons.timer_outlined,
        label: 'Plan süresi',
        value: planDurationValue,
      ),
      (
        icon: Icons.auto_awesome_rounded,
        label: 'Fal Baktırdığım',
        value: '${detail.fortunesReceived}',
      ),
      (
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Fal Yorumlarım',
        value: '${detail.fortuneComments}',
      ),
      (
        icon: Icons.videocam_rounded,
        label: 'Canlı Yayın İzlemem',
        value: detail.liveWatchMinutes > 0
            ? detail.liveWatchLabel
            : '${stats.liveStreams} yayın',
      ),
      (
        icon: Icons.favorite_border_rounded,
        label: 'Beğendiğim Gönderiler',
        value: '${detail.likedPosts > 0 ? detail.likedPosts : stats.likes}',
      ),
      (
        icon: Icons.mode_comment_outlined,
        label: 'Yorumlarım',
        value: '${detail.commentsCount}',
      ),
      (
        icon: Icons.ios_share_rounded,
        label: 'Paylaşımlarım',
        value: '${detail.sharesCount}',
      ),
    ];

    return ProfileGlass(
      padding: const EdgeInsets.all(16),
      borderRadius: ProfilePremiumTheme.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'İstatistiklerim',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/profile/growth'),
                child: const Text('Tümü >'),
              ),
            ],
          ),
          if (loading)
            const PremiumSkeleton(height: 120, width: double.infinity)
          else
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(row.icon, size: 16, color: Colors.white54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        row.label,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      row.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
