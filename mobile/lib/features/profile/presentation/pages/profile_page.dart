import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/wallet_navigation.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/premium_2026/premium_motion.dart';
import '../../../../core/ui/responsive/responsive_layout.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../shell/presentation/widgets/branch_quick_actions.dart';
import '../../../fortune/presentation/providers/fortune_access_providers.dart';
import '../providers/profile_providers.dart';
import '../widgets/premium/profile_admin_section.dart';
import '../widgets/premium/profile_fortune_teller_panel.dart';
import '../widgets/premium/profile_broadcaster_panel.dart';
import '../widgets/premium/profile_gifts_row.dart';
import '../widgets/premium/profile_fortune_access_badges.dart';
import '../widgets/premium/profile_neon_header.dart';
import '../widgets/premium/profile_premium_banner.dart';
import '../widgets/premium/profile_settings_menu.dart';
import '../widgets/profile_content_tabs.dart';
import '../widgets/premium/profile_wallet_section.dart';
import '../widgets/premium/profile_glass.dart';

/// Profil — responsive ortalanmış içerik, premium neon düzen.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final wallet = ref.watch(walletBalancesProvider);
    final accessAsync = ref.watch(fortuneAccessStateProvider);
    final stats = ref.watch(profileStatsProvider);
    final top = MediaQuery.paddingOf(context).top;

    Future<void> refresh() async {
      await ref.read(authControllerProvider.notifier).refreshMe();
      await ref.read(walletBalancesProvider.notifier).refresh(force: true);
      ref.invalidate(profileStatsProvider);
      ref.invalidate(giftsReceivedSummaryProvider);
      ref.invalidate(fortuneAccessStateProvider);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: RefreshIndicator(
          color: context.accentPink,
          backgroundColor: context.colors.surfaceContainer,
          onRefresh: refresh,
          child: auth.when(
            loading: () => const Center(child: DiscoverAccentLoader()),
            error: (e, _) => Center(
              child: Padding(
                padding: ResponsiveLayout.pagePadding(context),
                child: DiscoverEmptyState(
                  icon: Icons.error_outline_rounded,
                  message: ApiException.userMessage(e),
                ),
              ),
            ),
            data: (user) {
              if (user == null) {
                return const Center(
                  child: DiscoverEmptyState(
                    icon: Icons.person_off_outlined,
                    message: 'Oturum bulunamadı',
                  ),
                );
              }
              final balances = wallet.maybeWhen(
                data: (b) => b,
                orElse: () => null,
              );
              final jeton = balances?.jeton ?? user.coinBalance;
              final cfc = balances?.cfc ?? 0;
              final adCredits = accessAsync.maybeWhen(
                data: (s) => s.adCredits,
                orElse: () => balances?.fortuneAdCredits ?? 0,
              );
              final membership = balances?.membership;
              final membershipDays = balances?.membershipDaysRemaining;

              final statData = stats.maybeWhen(
                data: (s) => s,
                orElse: () => null,
              );
              final liveStreams = statData?.liveStreams ?? 0;
              final likes = statData?.likes ?? 0;
              final followers = statData?.followers ?? user.followersCount;
              final following = statData?.following ?? user.followingCount;

              return CustomScrollView(
                physics: PremiumMotion.listPhysics,
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: top + 8)),
                  SliverToBoxAdapter(
                    child: ResponsiveConstrained(
                      child: Padding(
                        padding: ResponsiveLayout.pagePadding(
                          context,
                          bottom: 120,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ProfileNeonHeader(
                              displayName: user.display,
                              username: user.username,
                              avatarUrl: user.avatarUrl,
                              followers: followers,
                              following: following,
                              liveStreams: liveStreams,
                              likes: likes,
                              bio: user.bio ??
                                  '🎵 Müzik, sohbet ve eğlence dolu yayınlar…',
                              diamondBalance: jeton,
                              cfcBalance: cfc,
                              onLogout: () => ref
                                  .read(authControllerProvider.notifier)
                                  .logout(),
                              onEdit: () => context.push('/profile/edit'),
                              onAvatarTap: () => context.push('/profile/edit'),
                              onFollowersTap: () => context.push(
                                '/profile/followers?userId=${user.id}',
                              ),
                              onFollowingTap: () => context.push(
                                '/profile/following?userId=${user.id}',
                              ),
                            ),
                            const SizedBox(height: 16),
                            ProfileFortuneAccessBadges(
                              adCredits: adCredits,
                              jeton: jeton,
                            ),
                            const SizedBox(height: 16),
                            const ProfileBranchQuickActions(),
                            const SizedBox(height: 20),
                            ProfilePremiumBanner(
                              membership: membership,
                              daysRemaining: membershipDays,
                              onViewPrivileges: () => context.push('/vip-gold'),
                            ),
                            const SizedBox(height: 22),
                            ProfileWalletSection(
                              jeton: jeton,
                              cfc: cfc,
                              onTopUp: () => openJetonStore(context, ref: ref),
                              onCfcTopUp: () => openCfcStore(context, ref: ref),
                              onEarnings: () =>
                                  context.push('/profile/earnings'),
                              onTransactions: () =>
                                  context.push('/profile/transactions'),
                              onPaymentNotice: () =>
                                  context.push('/profile/payment-notice'),
                              onSubscriptions: () => context.push('/wallet'),
                            ),
                            const SizedBox(height: 22),
                            const ProfileAdminSection(),
                            const ProfileFortuneTellerPanel(),
                            const SizedBox(height: 22),
                            ProfileBroadcasterPanel(
                              onHistory: () =>
                                  context.push('/profile/broadcast-history'),
                              onSchedule: () => context.push('/live/type'),
                              onStats: () =>
                                  context.push('/profile/broadcaster-stats'),
                              onEquipment: () =>
                                  context.push('/profile/equipment'),
                              onSettings: () => context.push('/live/type'),
                            ),
                            const SizedBox(height: 22),
                            ProfileGiftsRow(
                              onViewAll: () => context.push('/profile/gifts'),
                            ),
                            const SizedBox(height: 22),
                            ProfileSectionTitle(title: 'İçeriklerim'),
                            ProfileContentTabs(userId: user.id),
                            const SizedBox(height: 16),
                            ProfileSettingsMenu(
                              onEditProfile: () => context.push('/profile/edit'),
                              onSecurity: () => context.push('/settings'),
                              onNotifications: () =>
                                  context.push('/notifications'),
                              onHelp: () => context.push('/profile/help'),
                              onAbout: () => context.push('/profile/about'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
