import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/home_providers.dart';
import '../theme/home_approved_design.dart';
import 'approved/home_section_title.dart';

/// Günlük görevler, davet ve reklam teaser'ları — yatay kart şeridi.
class HomeGrowthTeasersSection extends ConsumerWidget {
  const HomeGrowthTeasersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final cards = <_GrowthCardData>[];

    final tasks = ref.watch(userDailyTasksProvider);
    final pending = tasks.valueOrNull
            ?.where((t) => !t.completed && t.current < t.target)
            .length ??
        0;
    if (!tasks.hasError || pending > 0) {
      final subtitle = tasks.when(
        loading: () => 'Günlük görevler yükleniyor…',
        error: (_, _) => 'Görevleri tamamla, jeton ve XP kazan',
        data: (items) {
          if (items.isEmpty) return 'Görevleri tamamla, jeton ve XP kazan';
          if (pending > 0) return '$pending bekleyen görev';
          return 'Tüm görevler tamamlandı 🎉';
        },
      );
      cards.add(
        _GrowthCardData(
          emoji: '🎯',
          title: 'Günlük Görevler',
          subtitle: subtitle,
          accent: HomeApprovedDesign.gold,
          icon: Icons.emoji_events_rounded,
          route: '/profile/growth',
        ),
      );
    }

    if (user != null) {
      final referral = ref.watch(referralInfoProvider);
      if (referral case AsyncData(:final value)) {
        final invited = value.invitedCount ?? 0;
        final subtitle = value.rewardHint?.trim().isNotEmpty == true
            ? value.rewardHint!
            : invited > 0
                ? '$invited arkadaş davet edildi'
                : 'Arkadaşlarını davet et, jeton kazan';
        cards.add(
          _GrowthCardData(
            emoji: '🎁',
            title: value.headline?.trim().isNotEmpty == true
                ? value.headline!
                : 'Arkadaşını Davet Et',
            subtitle: subtitle,
            accent: const Color(0xFF06B6D4),
            icon: Icons.group_add_rounded,
            route: '/invite-friends',
          ),
        );
      }

      final ads = ref.watch(homeActiveAdsProvider);
      if (ads case AsyncData(:final value) when value.isNotEmpty) {
        // POST /api/user/watch-ad yalnızca reklam izlendikten sonra atılır.
        cards.add(
          _GrowthCardData(
            emoji: '📺',
            title: 'Jeton Kazan',
            subtitle: 'Reklam izle, jeton kazan',
            accent: const Color(0xFFFF8A3D),
            icon: Icons.play_circle_rounded,
            route: '/profile/growth',
          ),
        );
      }
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        HomeSectionTitle(
          emoji: '✨',
          title: 'Büyüme & Ödüller',
          actionLabel: 'Merkez >',
          onAction: () => context.push('/profile/growth'),
        ),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: HomeApprovedDesign.hPad,
            ),
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _GrowthCard(data: cards[i]),
          ),
        ),
      ],
    );
  }
}

class _GrowthCardData {
  const _GrowthCardData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.route,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final String route;
}

class _GrowthCard extends StatelessWidget {
  const _GrowthCard({required this.data});

  final _GrowthCardData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeApprovedDesign.surface,
      borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
      child: InkWell(
        onTap: () => context.push(data.route),
        borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
            border: Border.all(color: HomeApprovedDesign.border),
            gradient: LinearGradient(
              colors: [
                data.accent.withValues(alpha: 0.18),
                HomeApprovedDesign.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(data.emoji, style: const TextStyle(fontSize: 16)),
                  const Spacer(),
                  Icon(data.icon, size: 18, color: data.accent),
                ],
              ),
              const Spacer(),
              Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: HomeApprovedDesign.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: HomeApprovedDesign.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
