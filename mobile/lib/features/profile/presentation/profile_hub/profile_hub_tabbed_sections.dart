import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../inbox/presentation/inbox_routes.dart';
import '../../../inbox/presentation/providers/inbox_unread_providers.dart';
import '../premium_2026/profile_screen_state.dart';
import '../premium_2026/profile_theme.dart';
import '../premium_2026/widgets/staff_profile_card.dart';
import '../providers/profile_activity_notifier.dart';
import 'profile_hub_about_stats_row.dart';
import 'profile_hub_badges_section.dart';
import 'profile_hub_completion_card.dart';
import 'profile_hub_currency_card.dart';
import 'profile_hub_membership_badges_section.dart';
import 'profile_hub_membership_section.dart';
import 'profile_hub_membership_shortcuts.dart';
import 'profile_hub_quick_menu.dart';
import 'profile_hub_recent_activity.dart';
import 'profile_hub_services_row.dart';
import 'profile_hub_share_card.dart';
import 'profile_hub_summary_card.dart';
import 'profile_hub_top_gifts_section.dart';
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
  /// Bölüm içeriği alttan açılan sayfada (aşağı uzayan akordeon yerine).
  void _openSection(String title, IconData icon, Widget child) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: ProfilePremiumTheme.surfaceOf(context, darkAlpha: 0.97),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.86,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(icon, color: AppThemeColors.accentPink, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: ProfilePremiumTheme.textOf(ctx),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Kapat',
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(inboxUnreadCountProvider);
    ref.watch(profileActivityNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Profil eksikse en üstte "Profilini Tamamla" (kırmızı eksik sayısı);
        // profil tamsa hiç görünmez.
        const ProfileHubCompletionCard(),
        ProfileHubSummaryCard(
          state: widget.state,
        ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.04, end: 0),
        const SizedBox(height: 12),
        const ProfileHubRecentActivity(),
        const SizedBox(height: 12),
        ProfileHubCurrencyCard(
          state: widget.state,
        ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.04, end: 0),
        const SizedBox(height: 12),
        _ProfileSectionGrid(
          buttons: [
            _ProfileSectionButton(
              key: const Key('profile-section-0'),
              icon: Icons.account_balance_wallet_rounded,
              title: 'Bakiye & Üyelik',
              subtitle: 'Jeton ${widget.state.jeton} · CFC ${widget.state.cfc}',
              onTap: () => _openSection(
                'Bakiye & Üyelik',
                Icons.account_balance_wallet_rounded,
                _balanceSection(),
              ),
            ),
            _ProfileSectionButton(
              key: const Key('profile-section-1'),
              icon: Icons.insights_rounded,
              title: 'İstatistikler & Sosyal',
              subtitle:
                  '${widget.state.followers} takipçi · Seviye ${widget.state.level.level}',
              onTap: () => _openSection(
                'İstatistikler & Sosyal',
                Icons.insights_rounded,
                _statsSection(),
              ),
            ),
            _ProfileSectionButton(
              key: const Key('profile-section-2'),
              icon: Icons.mic_rounded,
              title: 'Yayın & Sesli Oda',
              subtitle: widget.state.liveStreams > 0
                  ? '${widget.state.liveStreams} yayın kaydı'
                  : 'Yayın ve oda bilgileri',
              onTap: () => _openSection(
                'Yayın & Sesli Oda',
                Icons.mic_rounded,
                _broadcastSection(),
              ),
            ),
            _ProfileSectionButton(
              key: const Key('profile-section-3'),
              icon: Icons.settings_rounded,
              title: 'Ayarlar & Güvenlik',
              subtitle: 'Hesap, bildirimler, destek',
              badge: unread > 0 ? unread : null,
              onTap: () => _openSection(
                'Ayarlar & Güvenlik',
                Icons.settings_rounded,
                _settingsSection(unread),
              ),
            ),
          ],
        ),
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

  Widget _balanceSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ProfileHubMembershipSection(state: widget.state),
      const SizedBox(height: 12),
      const ProfileHubQuickMenu(),
      const SizedBox(height: 10),
      const ProfileHubMembershipShortcuts(),
    ],
  );

  Widget _statsSection() => Column(
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
          return const Column(children: [badges, SizedBox(height: 12), gifts]);
        },
      ),
    ],
  );

  Widget _broadcastSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const ProfileHubServicesRow(),
      if (widget.showPublisher) ...[
        const SizedBox(height: 14),
        const ProfileLazyPublisher(),
      ],
    ],
  );

  Widget _settingsSection(int unread) => Builder(
    builder: (context) => Column(
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
  );
}

/// Bölüm düğmeleri — 2 sütun (geniş ekranda 4).
class _ProfileSectionGrid extends StatelessWidget {
  const _ProfileSectionGrid({required this.buttons});

  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 600 ? 4 : 2;
        const gap = 10.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final b in buttons) SizedBox(width: w, child: b)],
        );
      },
    );
  }
}

class _ProfileSectionButton extends StatelessWidget {
  const _ProfileSectionButton({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(ProfilePremiumTheme.radiusLg);
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: ProfilePremiumTheme.surfaceOf(context, darkAlpha: 0.55),
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            height: 104,
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ProfilePremiumTheme.neonPurple.withValues(alpha: 0.22),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppThemeColors.accentPink, size: 24),
                    const Spacer(),
                    if (badge != null && badge! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
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
                      Icons.chevron_right_rounded,
                      color: ProfilePremiumTheme.textSecondaryOf(context),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: ProfilePremiumTheme.textOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: ProfilePremiumTheme.textMutedOf(context),
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
      color: ProfilePremiumTheme.insetOf(context, darkAlpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: ProfilePremiumTheme.textSecondaryOf(context),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ProfilePremiumTheme.textOf(context),
                ),
              ),
              if (badge != null && badge! > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppThemeColors.liveRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$badge',
                    style: TextStyle(
                      color: ProfilePremiumTheme.textOf(context),
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
