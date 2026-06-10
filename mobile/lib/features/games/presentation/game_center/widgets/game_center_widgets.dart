import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/ui/premium/premium_skeleton.dart';
import '../../../domain/game_center_models.dart';

/// Jeton bakiyesi chip — hero banner üstü.
class GameCenterJetonChip extends StatelessWidget {
  const GameCenterJetonChip({
    super.key,
    required this.balance,
    this.isLoading = false,
    this.onTopUp,
  });

  final int balance;
  final bool isLoading;
  final VoidCallback? onTopUp;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern('tr');
    return Material(
      color: context.colors.surface.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTopUp ?? () => context.push('/jeton-store'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: context.coinGold.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.monetization_on_rounded, color: context.coinGold, size: 20),
              const SizedBox(width: 6),
              if (isLoading)
                SizedBox(
                  width: 48,
                  height: 14,
                  child: PremiumSkeleton(
                    width: 48,
                    height: 14,
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
              else
                Text(
                  formatter.format(balance),
                  style: TextStyle(
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                Icons.add_circle_rounded,
                size: 18,
                color: context.colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kader çarkı hero banner.
class GameCenterHeroBanner extends StatelessWidget {
  const GameCenterHeroBanner({super.key, required this.onSpin});

  final VoidCallback onSpin;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'game-center-hero',
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFEC4899), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: GameCenterCatalog.purple.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Lottie.asset(
                  'assets/gifts/lottie/star.json',
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KADER ÇARKI ÇEVİR,\nKAZAN!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: onSpin,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: GameCenterCatalog.purple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      child: const Text('HEMEN ÇEVİR'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0);
  }
}

class GameCenterSectionHeader extends StatelessWidget {
  const GameCenterSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: context.colors.onSurface,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// Popüler oyunlar — yatay dairesel ikonlar.
class GameCenterPopularRow extends StatelessWidget {
  const GameCenterPopularRow({
    super.key,
    required this.items,
    required this.onTap,
  });

  final List<GameCenterItem> items;
  final ValueChanged<GameCenterItem> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = items[index];
          return _PopularOrb(item: item, onTap: () => onTap(item));
        },
      ),
    );
  }
}

class _PopularOrb extends StatelessWidget {
  const _PopularOrb({required this.item, required this.onTap});

  final GameCenterItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Hero(
              tag: item.heroTag ?? 'game-${item.id}',
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: item.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: item.gradient.first.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(item.icon, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: context.colors.onSurface,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Canlı oyun kartı.
class GameCenterLiveCard extends StatelessWidget {
  const GameCenterLiveCard({
    super.key,
    required this.item,
    required this.onJoin,
    this.playerCount,
  });

  final GameCenterItem item;
  final VoidCallback onJoin;
  final int? playerCount;

  @override
  Widget build(BuildContext context) {
    final count = playerCount ?? item.liveCount ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onJoin,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                item.gradient.first.withValues(alpha: 0.18),
                item.gradient.last.withValues(alpha: 0.08),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(colors: item.gradient),
                ),
                child: Icon(item.icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (item.badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF2D55),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '$count aktif oyuncu',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colors.onSurfaceMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: onJoin,
                child: const Text('Katıl'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ödüllü oyun kartı.
class GameCenterRewardCard extends StatelessWidget {
  const GameCenterRewardCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final GameCenterItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(colors: item.gradient),
          ),
          child: Icon(item.icon, color: Colors.white, size: 22),
        ),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(item.subtitle ?? ''),
        trailing: item.jetonCost > 0
            ? Text(
                '${item.jetonCost} Jeton',
                style: TextStyle(
                  color: context.coinGold,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              )
            : const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

/// Liderlik önizleme — ana sayfa için top 3.
class GameCenterLeaderboardPreview extends StatelessWidget {
  const GameCenterLeaderboardPreview({
    super.key,
    required this.entries,
    required this.onSeeAll,
    this.isLoading = false,
  });

  final List<LeaderboardEntry> entries;
  final VoidCallback onSeeAll;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: PremiumSkeleton(
          width: double.infinity,
          height: 88,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      );
    }
    final top = entries.take(3).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onSeeAll,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.outline.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.leaderboard_rounded, color: context.colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Liderlik Tablosu',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        top.map((e) => '${e.rank ?? '?'}. ${e.name}').join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Tümü',
                  style: TextStyle(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Oyun merkezi iskelet yükleme.
class GameCenterLoadingBody extends StatelessWidget {
  const GameCenterLoadingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PremiumSkeleton(
          width: double.infinity,
          height: 120,
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        const SizedBox(height: 20),
        Row(
          children: List.generate(
            4,
            (_) => const Padding(
              padding: EdgeInsets.only(right: 14),
              child: PremiumSkeleton(
                width: 64,
                height: 64,
                borderRadius: BorderRadius.all(Radius.circular(32)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: PremiumSkeleton(
              width: double.infinity,
              height: 72,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}
