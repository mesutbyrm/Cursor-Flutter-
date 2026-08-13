import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../feed/domain/entities/platform_stats_entity.dart';
import '../../../feed/presentation/providers/platform_stats_providers.dart';
import '../../domain/entities/home_user_liker_entity.dart';
import '../providers/home_providers.dart';
import '../theme/home_approved_design.dart';
import 'approved/home_section_title.dart';

enum _SocialTab { recentLogins, likers }

/// Son girişler ve profil beğenenler — tek sekmeli sosyal şerit.
class HomeSocialStripSection extends ConsumerStatefulWidget {
  const HomeSocialStripSection({super.key});

  @override
  ConsumerState<HomeSocialStripSection> createState() =>
      _HomeSocialStripSectionState();
}

class _HomeSocialStripSectionState extends ConsumerState<HomeSocialStripSection> {
  _SocialTab? _selectedTab;

  _SocialTab _resolveTab(List<_SocialTab> tabs) {
    if (_selectedTab != null && tabs.contains(_selectedTab)) {
      return _selectedTab!;
    }
    return tabs.first;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final stats = ref.watch(platformStatsProvider);
    final likers = user != null ? ref.watch(homeUserLikersProvider) : null;

    final logins = stats.valueOrNull?.recentLogins ?? const <RecentLoginEntity>[];
    final likerItems = likers?.valueOrNull ?? const <HomeUserLikerEntity>[];

    final hasLogins = logins.isNotEmpty;
    final hasLikers = likerItems.isNotEmpty;

    if (!hasLogins && !hasLikers) {
      if (stats.isLoading || (likers?.isLoading ?? false)) {
        return const SizedBox.shrink();
      }
      return const SizedBox.shrink();
    }

    final tabs = <_SocialTab>[
      if (hasLogins) _SocialTab.recentLogins,
      if (hasLikers) _SocialTab.likers,
    ];
    final tab = _resolveTab(tabs);

    final showTabs = tabs.length > 1;

    void openFull() {
      if (tab == _SocialTab.likers) {
        context.push('/profile');
      } else {
        context.push('/social');
      }
    }

    return Column(
      children: [
        HomeSectionTitle(
          emoji: tab == _SocialTab.likers ? '❤️' : '👋',
          title: tab == _SocialTab.likers ? 'Seni Beğenenler' : 'Son Girişler',
          actionLabel: tab == _SocialTab.likers ? 'Profil >' : 'Sosyal >',
          onAction: openFull,
        ),
        if (showTabs)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
            child: Row(
              children: [
                if (hasLogins)
                  _TabChip(
                    label: 'Son Girişler',
                    selected: tab == _SocialTab.recentLogins,
                    onTap: () => setState(() => _selectedTab = _SocialTab.recentLogins),
                  ),
                if (hasLogins && hasLikers) const SizedBox(width: 8),
                if (hasLikers)
                  _TabChip(
                    label: 'Beğenenler',
                    selected: tab == _SocialTab.likers,
                    onTap: () => setState(() => _selectedTab = _SocialTab.likers),
                  ),
              ],
            ),
          ),
        if (showTabs) const SizedBox(height: 8),
        SizedBox(
          height: 108,
          child: tab == _SocialTab.likers
              ? _LikersRow(items: likerItems.take(10).toList())
              : _LoginsRow(logins: logins.take(8).toList()),
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
          ? HomeApprovedDesign.pink.withValues(alpha: 0.16)
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
                  ? HomeApprovedDesign.pink.withValues(alpha: 0.5)
                  : HomeApprovedDesign.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected
                  ? HomeApprovedDesign.pink
                  : HomeApprovedDesign.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginsRow extends StatelessWidget {
  const _LoginsRow({required this.logins});

  final List<RecentLoginEntity> logins;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
      itemCount: logins.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, i) => _LoginChip(login: logins[i]),
    );
  }
}

class _LikersRow extends StatelessWidget {
  const _LikersRow({required this.items});

  final List<HomeUserLikerEntity> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, i) => _LikerChip(liker: items[i]),
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

class _LikerChip extends StatelessWidget {
  const _LikerChip({required this.liker});

  final HomeUserLikerEntity liker;

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
                  HomeApprovedDesign.pink.withValues(alpha: 0.9),
                  HomeApprovedDesign.liveRed.withValues(alpha: 0.85),
                ],
              ),
            ),
            child: UserAvatar(url: liker.avatarUrl, radius: 26),
          ),
          const SizedBox(height: 6),
          Text(
            liker.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: HomeApprovedDesign.textPrimary,
            ),
          ),
          if (liker.timeLabel?.trim().isNotEmpty == true)
            Text(
              liker.timeLabel!,
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
