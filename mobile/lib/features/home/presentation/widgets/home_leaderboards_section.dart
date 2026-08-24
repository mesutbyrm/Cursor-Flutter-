import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:intl/intl.dart';

import '../../../agency/domain/entities/agency_leaderboard_entry.dart';
import '../../../gifts/domain/gift_leaderboard_entry.dart';
import '../../../live/domain/pk/pk_leaderboard_models.dart';
import '../providers/home_providers.dart';
import '../theme/home_approved_design.dart';
import 'approved/home_section_title.dart';

enum _LeaderboardTab { gift, pk, agency }

/// Hediye, PK ve ajans liderlik önizlemeleri — tek sekmeli bölüm.
class HomeLeaderboardsSection extends ConsumerStatefulWidget {
  const HomeLeaderboardsSection({super.key});

  @override
  ConsumerState<HomeLeaderboardsSection> createState() =>
      _HomeLeaderboardsSectionState();
}

class _HomeLeaderboardsSectionState extends ConsumerState<HomeLeaderboardsSection> {
  _LeaderboardTab? _selectedTab;

  static String _formatCompact(int n) =>
      NumberFormat.compact(locale: 'tr').format(n);

  _LeaderboardTab _resolveTab(List<_LeaderboardTab> tabs) {
    if (_selectedTab != null && tabs.contains(_selectedTab)) {
      return _selectedTab!;
    }
    return tabs.first;
  }

  @override
  Widget build(BuildContext context) {
    final gift = ref.watch(homeGiftLeaderboardProvider);
    final pk = ref.watch(homePkLeaderboardProvider);
    final agency = ref.watch(homeAgencyLeaderboardProvider);

    final giftData = gift.valueOrNull ?? const <GiftLeaderboardEntry>[];
    final pkData = pk.valueOrNull ?? const <PkLeaderboardEntry>[];
    final agencyData = agency.valueOrNull ?? const <AgencyLeaderboardEntry>[];

    final hasGift = giftData.isNotEmpty;
    final hasPk = pkData.isNotEmpty;
    final hasAgency = agencyData.isNotEmpty;

    if (!hasGift && !hasPk && !hasAgency) {
      if (gift.isLoading || pk.isLoading || agency.isLoading) {
        return const SizedBox.shrink();
      }
      return const SizedBox.shrink();
    }

    final tabs = <_LeaderboardTab>[
      if (hasGift) _LeaderboardTab.gift,
      if (hasPk) _LeaderboardTab.pk,
      if (hasAgency) _LeaderboardTab.agency,
    ];
    final tab = _resolveTab(tabs);

    void openFull() {
      switch (tab) {
        case _LeaderboardTab.gift:
          context.push('/gifts/leaderboard');
        case _LeaderboardTab.pk:
          context.push('/pk/leaderboard');
        case _LeaderboardTab.agency:
          context.push('/ajans/dashboard');
      }
    }

    return Column(
      children: [
        HomeSectionTitle(
          emoji: '🏆',
          title: 'Liderlik Tabloları',
          actionLabel: 'Tümü >',
          onAction: openFull,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
          child: Row(
            children: [
              for (final t in tabs) ...[
                _TabChip(
                  label: switch (t) {
                    _LeaderboardTab.gift => 'Hediye',
                    _LeaderboardTab.pk => 'PK',
                    _LeaderboardTab.agency => 'Ajans',
                  },
                  selected: tab == t,
                  onTap: () => setState(() => _selectedTab = t),
                ),
                if (t != tabs.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 92,
          child: switch (tab) {
            _LeaderboardTab.gift => _GiftRow(entries: giftData.take(3).toList()),
            _LeaderboardTab.pk => _PkRow(entries: pkData.take(3).toList()),
            _LeaderboardTab.agency => _AgencyRow(entries: agencyData.take(3).toList()),
          },
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? HomeApprovedDesign.purple.withValues(alpha: 0.18)
          : HomeApprovedDesign.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? HomeApprovedDesign.purple.withValues(alpha: 0.5)
                  : HomeApprovedDesign.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected
                  ? HomeApprovedDesign.purple
                  : HomeApprovedDesign.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _GiftRow extends StatelessWidget {
  const _GiftRow({required this.entries});

  final List<GiftLeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (_, i) => _RankCard(
        rank: i + 1,
        name: entries[i].displayName.trim().isNotEmpty
            ? entries[i].displayName
            : 'Kullanıcı',
        avatarUrl: entries[i].avatarUrl,
        scoreLabel:
            '${_HomeLeaderboardsSectionState._formatCompact(entries[i].totalCoins)} jeton',
        accent: HomeApprovedDesign.gold,
        onTap: () => context.push('/gifts/leaderboard'),
      ),
    );
  }
}

class _PkRow extends StatelessWidget {
  const _PkRow({required this.entries});

  final List<PkLeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (_, i) => _RankCard(
        rank: i + 1,
        name: entries[i].displayName?.trim().isNotEmpty == true
            ? entries[i].displayName!
            : 'Yayıncı',
        avatarUrl: entries[i].avatarUrl,
        scoreLabel:
            '${_HomeLeaderboardsSectionState._formatCompact(entries[i].score)} puan',
        accent: HomeApprovedDesign.liveRed,
        onTap: () => context.push('/pk/leaderboard'),
      ),
    );
  }
}

class _AgencyRow extends StatelessWidget {
  const _AgencyRow({required this.entries});

  final List<AgencyLeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (_, i) {
        final entry = entries[i];
        final scoreLabel = entry.score > 0
            ? '${_HomeLeaderboardsSectionState._formatCompact(entry.score)} puan'
            : entry.memberCount != null
                ? '${entry.memberCount} üye'
                : 'Ajans';
        return _AgencyCard(
          rank: i + 1,
          name: entry.name,
          logoUrl: entry.logoUrl,
          scoreLabel: scoreLabel,
          onTap: () => context.push('/ajans/dashboard'),
        );
      },
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({
    required this.rank,
    required this.name,
    required this.scoreLabel,
    required this.accent,
    required this.onTap,
    this.avatarUrl,
  });

  final int rank;
  final String name;
  final String? avatarUrl;
  final String scoreLabel;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#$rank',
    };

    return Material(
      color: HomeApprovedDesign.surface,
      borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
        child: Container(
          width: 148,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
            border: Border.all(color: HomeApprovedDesign.border),
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: rank == 1 ? 0.22 : 0.1),
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
                  Text(medal, style: const TextStyle(fontSize: 14)),
                  const Spacer(),
                  Text(
                    scoreLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: HomeApprovedDesign.border,
                    backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                        ? canlifalImageProvider(avatarUrl!)
                        : null,
                    child: avatarUrl == null || avatarUrl!.isEmpty
                        ? Text(
                            name.characters.first.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: HomeApprovedDesign.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgencyCard extends StatelessWidget {
  const _AgencyCard({
    required this.rank,
    required this.name,
    required this.scoreLabel,
    required this.onTap,
    this.logoUrl,
  });

  final int rank;
  final String name;
  final String? logoUrl;
  final String scoreLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#$rank',
    };

    return Material(
      color: HomeApprovedDesign.surface,
      borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
        child: Container(
          width: 148,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
            border: Border.all(color: HomeApprovedDesign.border),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF06B6D4).withValues(alpha: rank == 1 ? 0.2 : 0.1),
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
                  Text(medal, style: const TextStyle(fontSize: 14)),
                  const Spacer(),
                  Text(
                    scoreLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF06B6D4),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: logoUrl != null && logoUrl!.isNotEmpty
                        ? CanlifalNetworkImage(
                            url: logoUrl!,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 32,
                            height: 32,
                            color: HomeApprovedDesign.border,
                            child: const Icon(Icons.apartment_rounded, size: 18),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: HomeApprovedDesign.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
