import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/native_site_routes.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/cfc_reward_overlay.dart';
import '../../../fortune/data/services/rewarded_ad_service.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/premium_2026/premium_motion.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../home/domain/entities/home_game_entity.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../data/datasources/achievements_remote_datasource.dart';
import '../../domain/entities/daily_task_entity.dart';
import '../../domain/entities/growth_progress_entity.dart';
import '../../domain/entities/profile_stats_entity.dart';
import '../../../membership/presentation/widgets/membership_pending_payment_banner.dart';
import '../../../membership/presentation/widgets/membership_status_pill.dart';
import '../providers/payment_requests_notifier.dart';
import '../providers/profile_providers.dart';
import '../../../cosmetics/presentation/providers/cosmetics_providers.dart';
import '../../../membership/presentation/controllers/membership_controller.dart';
import '../../../membership/domain/membership_model.dart';
import '../premium_2026/profile_membership_helpers.dart';
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
    final achievementsAsync = ref.watch(userAchievementsProvider);
    final serverTasksAsync = ref.watch(userDailyTasksProvider);
    final serverLevelAsync = ref.watch(userLevelProvider);

    final user = auth.valueOrNull;
    final stats = statsAsync.valueOrNull ?? const ProfileStatsEntity();
    final rewards =
        rewardsAsync.valueOrNull ?? const <DailyRewardEntity>[];
    final wallet = walletAsync.valueOrNull;
    final referral = referralAsync.valueOrNull;
    final membershipInfo = resolveProfileMembership(
      rawMembership: wallet?.membership,
      daysRemaining: wallet?.membershipDaysRemaining,
    );
    final hasPremium = membershipInfo.hasActiveSubscription;
    final progress = GrowthProgressEntity.fromSignals(
      stats: stats,
      dailyRewards: rewards,
      jeton: wallet?.jeton ?? user?.coinBalance ?? 0,
      cfc: wallet?.cfc ?? 0,
      invitedCount: referral?.invitedCount ?? 0,
      hasPremium: hasPremium,
    );
    final serverLevel = serverLevelAsync.valueOrNull;
    final displayLevel = serverLevel != null && serverLevel.level > 0
        ? serverLevel.level
        : progress.level;
    final displayXp = serverLevel != null && serverLevel.xp > 0
        ? serverLevel.xp
        : progress.xp;
    final serverTasks = serverTasksAsync.valueOrNull ?? const <DailyTaskEntity>[];
    final taskCards = serverTasks.isNotEmpty
        ? serverTasks
            .map(
              (t) => GrowthTaskEntity(
                id: t.id,
                title: t.title,
                description: t.description ?? '',
                current: t.current,
                target: t.target,
                rewardLabel: t.rewardJeton > 0
                    ? '+${t.rewardJeton} Jeton'
                    : (t.rewardXp > 0 ? '+${t.rewardXp} XP' : '+XP'),
                route: t.route ?? '/feed',
                icon: t.icon ?? '✅',
              ),
            )
            .toList()
        : progress.tasks;
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
                    level: displayLevel,
                    xp: displayXp,
                    membershipInfo: membershipInfo,
                    vipTier: serverLevel?.vipTier,
                    isVip: serverLevel?.isVip ?? membershipInfo.isVip,
                  ),
                  const SizedBox(height: 14),
                  const MembershipPendingPaymentBanner(padding: EdgeInsets.zero),
                  const SizedBox(height: 14),
                  _MembershipStatusCard(info: membershipInfo),
                  const SizedBox(height: 20),
                  const ProfileSectionTitle(title: 'Bugünün görevleri'),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverList.builder(
                itemCount: taskCards.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TaskCard(
                    task: taskCards[index],
                    onTap: () => _openTask(context, taskCards[index].route),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
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
                  achievementsAsync.when(
                    data: (apiBadges) {
                      if (apiBadges.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          const ProfileSectionTitle(title: 'Sunucu rozetleri'),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final a in apiBadges)
                                _ApiAchievementChip(achievement: a),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 20),
                  _RoadmapHintCard(
                    info: membershipInfo,
                    onVip: () => context.push('/vip-gold'),
                    onPremium: () => context.push('/premium-membership'),
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
    ref.refreshWalletCache(force: true);
    ref.invalidate(referralInfoProvider);
    ref.invalidate(userAchievementsProvider);
    ref.invalidate(userDailyTasksProvider);
    ref.invalidate(userLevelProvider);
    // Günlük jeton bonusu (zaten alındıysa sessizce atlanır)
    unawaited(
      ref.read(dailyTasksRemoteProvider).claimJetonDailyLoginBonus().then((_) {
        ref.refreshWalletCache(force: true);
      }),
    );
    ref.invalidate(membershipBadgesCatalogProvider);
    ref.invalidate(membershipCatalogProvider);
    ref.invalidate(membershipControllerProvider);
    ref.invalidate(paymentRequestsNotifierProvider);
    ref.invalidate(paymentMethodsProvider);
    await Future.wait([
      _ignore(ref.read(authControllerProvider.notifier).refreshMe()),
      _ignore(ref.read(profileStatsProvider.future)),
      _ignore(ref.read(homeDailyRewardsProvider.future)),
      _ignore(ref.read(walletBalancesProvider.future)),
      _ignore(ref.read(referralInfoProvider.future)),
      _ignore(ref.read(userAchievementsProvider.future)),
      _ignore(ref.read(userDailyTasksProvider.future)),
      _ignore(ref.read(userLevelProvider.future)),
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
      final watched = await RewardedAdService.instance.show();
      if (!watched) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reklam tamamlanmadı; ödül verilmedi.')),
        );
        return;
      }
      var reward = 10;
      try {
        reward = await ref.read(watchAdCreditProvider.future);
        if (reward <= 0) reward = 10;
        ref.invalidate(walletBalancesProvider);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
        return;
      }
      if (!context.mounted) return;
      await CfcRewardOverlay.show(context, amount: reward);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }
}

class _MembershipStatusCard extends ConsumerWidget {
  const _MembershipStatusCard({required this.info});

  final ProfileMembershipInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final paid = info.hasPaidTier;
    final expired = info.isExpired;
    final ui = ref.watch(membershipControllerProvider);
    final catalogTier = catalogTierForMembership(info, ui.tiers);
    final expiresAt =
        ref.watch(walletBalancesProvider).valueOrNull?.membershipExpiresAt;

    final title = buildGrowthHubMembershipTitle(
      info: info,
      expiresAt: expiresAt,
    );

    final subtitle = buildGrowthHubMembershipSubtitle(
      info: info,
      catalogTier: catalogTier,
      expiresAt: expiresAt,
    );
    final statusPill = buildMembershipStatusPillLabel(
      info: info,
      expiresAt: expiresAt,
    );

    final accent = expired
        ? AppThemeColors.accentPink
        : paid
            ? AppThemeColors.coinGold
            : AppThemeColors.accentPurple;

    return ProfileGlass(
      onTap: () => context.push(
        paid && info.isVip ? '/vip-gold' : '/premium-membership',
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              paid ? Icons.workspace_premium_rounded : Icons.card_membership_rounded,
              color: accent,
              size: 22,
            ),
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
                        title,
                        style: TextStyle(
                          color: c.onSurface,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (statusPill != null) ...[
                      MembershipStatusPill(
                        label: statusPill,
                        expired: expired,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: c.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            buildMembershipHubActionLabel(info: info),
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: c.onSurfaceMuted, size: 20),
        ],
      ),
    );
  }
}

class _LevelHero extends StatelessWidget {
  const _LevelHero({
    required this.displayName,
    required this.progress,
    required this.membershipInfo,
    this.level,
    this.xp,
    this.vipTier,
    this.isVip = false,
  });

  final String displayName;
  final GrowthProgressEntity progress;
  final ProfileMembershipInfo membershipInfo;
  final int? level;
  final int? xp;
  final String? vipTier;
  final bool isVip;

  @override
  Widget build(BuildContext context) {
    final vipPillLabel = buildMembershipGrowthHubLevelVipPillLabel(
      info: membershipInfo,
      serverVipTier: vipTier,
    );

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
                  '${level ?? progress.level}',
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
                      '${profileFormatCoins(xp ?? progress.xp)} XP • Sıradaki seviye ${progress.nextLevelXp} XP',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isVip) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          vipPillLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
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
    required this.info,
    required this.onVip,
    required this.onPremium,
    required this.onInvite,
    required this.onAdReward,
  });

  final ProfileMembershipInfo info;
  final VoidCallback onVip;
  final VoidCallback onPremium;
  final VoidCallback onInvite;
  final VoidCallback onAdReward;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final plansLabel = buildMembershipGrowthHubPlansButtonLabel(info: info);
    final vipLabel = buildMembershipGrowthHubVipButtonLabel(info: info);

    return ProfileGlass(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            buildMembershipGrowthHubRoadmapSectionTitle(),
            style: TextStyle(
              color: c.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            buildMembershipGrowthHubRoadmapHintText(),
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
                  onPressed: onPremium,
                  icon: const Icon(Icons.card_membership_rounded),
                  label: Text(plansLabel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onVip,
                  icon: const Icon(Icons.workspace_premium_rounded),
                  label: Text(vipLabel),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
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

class _ApiAchievementChip extends StatelessWidget {
  const _ApiAchievementChip({required this.achievement});

  final AchievementEntity achievement;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = achievement.unlocked
        ? AppThemeColors.onlineGreen
        : AppThemeColors.coinGold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(achievement.icon ?? '🏅', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.title,
                style: TextStyle(
                  color: c.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              if (achievement.description != null)
                Text(
                  achievement.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
            ],
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
