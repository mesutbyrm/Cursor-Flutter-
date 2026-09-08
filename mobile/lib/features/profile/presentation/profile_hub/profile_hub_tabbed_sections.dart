import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../inbox/presentation/inbox_routes.dart';
import '../../../inbox/presentation/providers/inbox_unread_providers.dart';
import '../premium_2026/profile_screen_state.dart';
import '../premium_2026/profile_theme.dart';
import '../premium_2026/widgets/profile_settings_section.dart';
import '../premium_2026/widgets/staff_profile_card.dart';
import 'profile_hub_about_stats_row.dart';
import 'profile_hub_badges_section.dart';
import 'profile_hub_currency_card.dart';
import 'profile_hub_membership_badges_section.dart';
import 'profile_hub_membership_section.dart';
import 'profile_hub_membership_shortcuts.dart';
import 'profile_hub_quick_menu.dart';
import 'profile_hub_services_row.dart';
import 'profile_hub_share_card.dart';
import 'profile_hub_top_gifts_section.dart';
import '../../../shorts/presentation/widgets/shorts_profile_content.dart';
import '../premium_2026/profile_lazy_sections.dart';

/// Profil içeriği — kart/accordion düzeni; mobilde üst üste binme önlenir.
class ProfileHubTabbedSections extends ConsumerStatefulWidget {
  const ProfileHubTabbedSections({
    super.key,
    required this.state,
    required this.userId,
    this.onRefresh,
    this.showAdmin = false,
    this.showPublisher = false,
    this.showStaff = false,
    this.onLogout,
  });

  final ProfileScreenState state;
  final String userId;
  final VoidCallback? onRefresh;
  final bool showAdmin;
  final bool showPublisher;
  final bool showStaff;
  final VoidCallback? onLogout;

  @override
  ConsumerState<ProfileHubTabbedSections> createState() =>
      _ProfileHubTabbedSectionsState();
}

class _ProfileHubTabbedSectionsState
    extends ConsumerState<ProfileHubTabbedSections> {
  int _openSection = 0;

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(inboxUnreadCountProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileHubCurrencyCard(state: widget.state)
            .animate()
            .fadeIn(duration: 280.ms)
            .slideY(begin: 0.04, end: 0),
        const SizedBox(height: 12),
        _ProfileSectionCard(
          index: 0,
          openIndex: _openSection,
          icon: Icons.account_balance_wallet_rounded,
          title: 'Bakiye & Üyelik',
          subtitle: 'Jeton ${widget.state.jeton} · CFC ${widget.state.cfc}',
          onToggle: (i) => setState(() => _openSection = i),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileHubMembershipSection(state: widget.state),
              const SizedBox(height: 12),
              const ProfileHubQuickMenu(),
              const SizedBox(height: 10),
              const ProfileHubMembershipShortcuts(),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _ProfileSectionCard(
          index: 1,
          openIndex: _openSection,
          icon: Icons.insights_rounded,
          title: 'İstatistikler & Sosyal',
          subtitle:
              '${widget.state.followers} takipçi · Seviye ${widget.state.level.level}',
          onToggle: (i) => setState(() => _openSection = i),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileHubAboutStatsRow(
                user: widget.state.user,
                stats: widget.state.stats,
              ),
              const SizedBox(height: 12),
              ProfileHubShareCard(
                username: widget.state.user.username,
                displayName: widget.state.user.display,
              ),
              const SizedBox(height: 12),
              const ProfileHubMembershipBadgesSection(),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, c) {
                  final wide = c.maxWidth >= 600;
                  const badges = ProfileHubBadgesSection();
                  const gifts = ProfileHubTopGiftsSection();
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(child: badges),
                        const SizedBox(width: 12),
                        const Expanded(child: gifts),
                      ],
                    );
                  }
                  return const Column(
                    children: [badges, SizedBox(height: 12), gifts],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _ProfileSectionCard(
          index: 2,
          openIndex: _openSection,
          icon: Icons.mic_rounded,
          title: 'Yayın & Sesli Oda',
          subtitle: widget.state.liveStreams > 0
              ? '${widget.state.liveStreams} yayın kaydı'
              : 'Yayın ve oda bilgileri',
          onToggle: (i) => setState(() => _openSection = i),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ProfileHubServicesRow(),
              if (widget.showPublisher) ...[
                const SizedBox(height: 14),
                const ProfileLazyPublisher(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _ProfileSectionCard(
          index: 3,
          openIndex: _openSection,
          icon: Icons.settings_rounded,
          title: 'Ayarlar & Güvenlik',
          subtitle: 'Hesap, bildirimler, destek',
          badge: unread > 0 ? unread : null,
          onToggle: (i) => setState(() => _openSection = i),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _QuickChip(
                    icon: Icons.person_outline_rounded,
                    label: 'Profil Düzenle',
                    onTap: () => context.push('/profile/edit'),
                  ),
                  _QuickChip(
                    icon: Icons.shield_outlined,
                    label: 'Güvenlik',
                    onTap: () => context.push('/profile/security'),
                  ),
                  _QuickChip(
                    icon: Icons.inbox_rounded,
                    label: 'Bildirimler',
                    badge: unread,
                    onTap: () => InboxRoutes.open(context),
                  ),
                  _QuickChip(
                    icon: Icons.settings_outlined,
                    label: 'Tüm Ayarlar',
                    onTap: () => context.push('/settings'),
                  ),
                ],
              ),
              if (widget.onLogout != null) ...[
                const SizedBox(height: 16),
                ProfileLazySettings(onLogout: widget.onLogout!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        ProfileLazyContent(userId: widget.userId),
        if (widget.showStaff) ...[
          const SizedBox(height: 16),
          const ProfileLazyStaff(),
        ],
        if (widget.showAdmin) ...[
          const SizedBox(height: 16),
          const ProfileLazyAdmin(),
        ],
      ],
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({
    required this.index,
    required this.openIndex,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onToggle,
    required this.child,
    this.badge,
  });

  final int index;
  final int openIndex;
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<int> onToggle;
  final Widget child;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final open = openIndex == index;
    return Material(
      color: ProfilePremiumTheme.deepBg.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(ProfilePremiumTheme.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(ProfilePremiumTheme.radiusLg),
        onTap: () => onToggle(open ? -1 : index),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ProfilePremiumTheme.radiusLg),
            border: Border.all(
              color: Colors.white.withValues(alpha: open ? 0.18 : 0.08),
            ),
          ),
          padding: EdgeInsets.fromLTRB(14, 12, 14, open ? 14 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppThemeColors.accentPink, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (badge != null && badge! > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppThemeColors.liveRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge! > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  Icon(
                    open
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ],
              ),
              if (open) ...[
                const SizedBox(height: 14),
                child,
              ],
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 60).ms).fadeIn(duration: 260.ms);
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.85)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (badge != null && badge! > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppThemeColors.liveRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
