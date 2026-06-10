import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/native_site_routes.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/premium_2026/premium_motion.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../home/domain/entities/home_game_entity.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../domain/entities/growth_progress_entity.dart';
import '../../domain/entities/profile_stats_entity.dart';
import '../providers/profile_providers.dart';
import '../widgets/premium/profile_glass.dart';

class GrowthHubPage extends ConsumerWidget {
  const GrowthHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final statsAsync = ref.watch(profileStatsProvider);
    final rewardsAsync = ref.watch(homeDailyRewardsProvider);
    final walletAsync = ref.watch(walletBalancesProvider);
    final referralAsync = ref.watch(referralInfoProvider);

    final user = auth.valueOrNull;
    final stats = statsAsync.valueOrNull ?? const ProfileStatsEntity();
    final rewards =
        rewardsAsync.valueOrNull ?? const <DailyRewardEntity>[];
    final wallet = walletAsync.valueOrNull;
    final referral = referralAsync.valueOrNull;
    final hasPremium = (wallet?.membership ?? '').trim().isNotEmpty;
    final progress = GrowthProgressEntity.fromSignals(
      stats: stats,
      dailyRewards: rewards,
      jeton: wallet?.jeton ?? user?.coinBalance ?? 0,
      cfc: wallet?.cfc ?? 0,
      invitedCount: referral?.invitedCount ?? 0,
      hasPremium: hasPremium,
    );
    final loading = auth.isLoading ||
        statsAsync.isLoading ||
        rewardsAsync.isLoading ||
        walletAsync.isLoading ||
        referralAsync.isLoading;
    final errorCount = [
      statsAsync,
      rewardsAsync,
      walletAsync,
      referralAsync,
    ].where((value) => value.hasError).length;

    return DiscoverSubPage(
      title: 'Görevler & Rozetler',
      subtitle: 'Günlük görev, XP, seviye ve büyüme merkezi',
      body: RefreshIndicator(
        color: context.accentPink,
        backgroundColor: context.colors.surfaceContainer,
        onRefresh: () => _refresh(ref),
        child: CustomScrollView(
          physics: PremiumMotion.listPhysics,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (loading) const LinearProgressIndicator(minHeight: 2),
                  if (loading) const SizedBox(height: 12),
                  if (errorCount > 0) ...[
                    _WarningCard(errorCount: errorCount),
                    const SizedBox(height: 14),
                  ],
                  _LevelHero(
                    displayName: user?.display ?? 'Canlifal üyesi',
                    progress: progress,
                  ),
                  const SizedBox(height: 20),
                  const ProfileSectionTitle(title: 'Bugünün görevleri'),
                  for (final task in progress.tasks) ...[
                    _TaskCard(
                      task: task,
                      onTap: () => _openTask(context, task.route),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 8),
                  ProfileSectionTitle(
                    title: 'Rozet albümü',
                    trailing: Text(
                      '${progress.unlockedBadgeCount}/${progress.badges.length}',
                      style: TextStyle(
                        color: context.colors.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _BadgeWrap(badges: progress.badges),
                  const SizedBox(height: 20),
                  _RoadmapHintCard(
                    onVip: () => context.push('/vip-gold'),
                    onInvite: () => context.push('/invite-friends'),
                    onAdReward: () => _claimAdReward(context, ref),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(profileStatsProvider);
    ref.invalidate(homeDailyRewardsProvider);
    ref.invalidate(walletBalancesProvider);
    ref.invalidate(referralInfoProvider);
    await Future.wait([
      _ignore(ref.read(authControllerProvider.notifier).refreshMe()),
      _ignore(ref.read(profileStatsProvider.future)),
      _ignore(ref.read(homeDailyRewardsProvider.future)),
      _ignore(ref.read(walletBalancesProvider.future)),
      _ignore(ref.read(referralInfoProvider.future)),
    ]);
  }

  static Future<void> _ignore(Future<dynamic> future) async {
    try {
      await future;
    } catch (_) {
      // Kartlar hata durumunu ekranda yumuşak uyarı olarak gösterir.
    }
  }

  static void _openTask(BuildContext context, String route) {
    if (route == '/profile' || route == '/feed' || route == '/live') {
      context.go(route);
      return;
    }
    if (route == '/voice-rooms' ||
        route == '/invite-friends' ||
        route == '/profile/gifts' ||
        route == '/ad-rewards' ||
        route == '/vip-gold') {
      context.push(route);
      return;
    }
    openNativeSitePath(context, route);
  }

  static Future<void> _claimAdReward(BuildContext context, WidgetRef ref) async {
    try {
      final reward = await ref.read(watchAdCreditProvider.future);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reward > 0
                ? 'Reklam ödülü işlendi: +$reward'
                : 'Reklam ödülü işlendi, bakiyeniz yenileniyor.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }
}

class _LevelHero extends StatelessWidget {
  const _LevelHero({
    required this.displayName,
    required this.progress,
  });

  final String displayName;
  final GrowthProgressEntity progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            AppThemeColors.accentPink,
            AppThemeColors.accentPurple,
            AppThemeColors.accentCyan,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: AppThemeColors.glowShadow(
          AppThemeColors.accentPink,
          blur: 32,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.32),
                  ),
                ),
                child: Text(
                  '${progress.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$displayName için seviye yolu',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profileFormatCoins(progress.xp)} XP • Sıradaki seviye ${progress.nextLevelXp} XP',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.levelProgress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroMetric(
                label: 'Tamamlanan',
                value: '${progress.completedTaskCount}/${progress.tasks.length}',
              ),
              const SizedBox(width: 10),
              _HeroMetric(
                label: 'Rozet',
                value: '${progress.unlockedBadgeCount}/${progress.badges.length}',
              ),
              const SizedBox(width: 10),
              _HeroMetric(
                label: 'Kalan XP',
                value: profileFormatCoins(
                  (progress.nextLevelXp - progress.xp)
                      .clamp(0, 999999)
                      .toInt(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Bu ekran mevcut web/API verilerinden hesaplanan motivasyon katmanıdır; ödül toplama ve satın alma akışları var olan endpointlere gider.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onTap,
  });

  final GrowthTaskEntity task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent =
        task.isComplete ? AppThemeColors.onlineGreen : AppThemeColors.coinGold;
    return ProfileGlass(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(task.icon, style: const TextStyle(fontSize: 23)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.onSurface,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      task.progressLabel,
                      style: TextStyle(
                        color: c.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: task.progress,
                          minHeight: 7,
                          backgroundColor: c.outlineVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      task.isComplete ? 'Hazır' : task.rewardLabel,
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: c.onSurfaceMuted),
        ],
      ),
    );
  }
}

class _BadgeWrap extends StatelessWidget {
  const _BadgeWrap({required this.badges});

  final List<GrowthBadgeEntity> badges;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final badge in badges)
          SizedBox(
            width: (MediaQuery.sizeOf(context).width - 50) / 2,
            child: _BadgeCard(badge: badge),
          ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge});

  final GrowthBadgeEntity badge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent =
        badge.unlocked ? AppThemeColors.accentCyan : c.onSurfaceMuted;
    return ProfileGlass(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                badge.icon,
                style: TextStyle(
                  fontSize: 26,
                  color: badge.unlocked ? null : c.onSurfaceMuted,
                ),
              ),
              const Spacer(),
              Icon(
                badge.unlocked
                    ? Icons.verified_rounded
                    : Icons.lock_outline_rounded,
                size: 18,
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            badge.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: c.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: c.onSurfaceVariant,
              fontSize: 12,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadmapHintCard extends StatelessWidget {
  const _RoadmapHintCard({
    required this.onVip,
    required this.onInvite,
    required this.onAdReward,
  });

  final VoidCallback onVip;
  final VoidCallback onInvite;
  final VoidCallback onAdReward;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ProfileGlass(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sıradaki büyüme adımları',
            style: TextStyle(
              color: c.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'VIP avantajları, oda sıralamaları, hediye serileri ve PK turnuvaları roadmap fazlarına alındı. Bu merkez, kullanıcıya ilerleme hissini bugün vermek için ilk katmandır.',
            style: TextStyle(
              color: c.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onVip,
                  icon: const Icon(Icons.workspace_premium_rounded),
                  label: const Text('VIP'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onInvite,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Davet'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onAdReward,
            icon: const Icon(Icons.play_circle_fill_rounded),
            label: const Text('Reklam izle, ödül kazan'),
          ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.errorCount});

  final int errorCount;

  @override
  Widget build(BuildContext context) {
    return ProfileGlass(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: context.coinGold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$errorCount veri kaynağı geçici yanıt vermedi; ekran mevcut önbellek ve güvenli varsayılanlarla açıldı.',
              style: TextStyle(
                color: context.colors.onSurfaceVariant,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
