import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/responsive/responsive_layout.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../shell/presentation/widgets/branch_quick_actions.dart';
import '../providers/profile_providers.dart';
import '../widgets/premium/profile_admin_section.dart';
import '../widgets/premium/profile_broadcaster_panel.dart';
import '../widgets/premium/profile_gifts_row.dart';
import '../widgets/premium/profile_neon_header.dart';
import '../widgets/premium/profile_premium_banner.dart';
import '../widgets/premium/profile_settings_menu.dart';
import '../widgets/premium/profile_wallet_section.dart';

/// Profil — responsive ortalanmış içerik, premium neon düzen.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final wallet = ref.watch(walletBalancesProvider);
    final stats = ref.watch(profileStatsProvider);
    final top = MediaQuery.paddingOf(context).top;

    Future<void> refresh() async {
      await ref.read(authControllerProvider.notifier).refreshMe();
      ref.invalidate(walletBalancesProvider);
      ref.invalidate(coinBalanceProvider);
      ref.invalidate(profileStatsProvider);
      ref.invalidate(giftsReceivedSummaryProvider);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DiscoverBackground(
        child: RefreshIndicator(
          color: AppColors.accentPink,
          backgroundColor: AppColors.bgPurpleGlow,
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
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
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
                            const ProfileBranchQuickActions(),
                            const SizedBox(height: 20),
                            ProfilePremiumBanner(
                              membership: membership,
                              daysRemaining: membershipDays,
                              onViewPrivileges: () =>
                                  context.push('/premium-membership'),
                            ),
                            const SizedBox(height: 22),
                            ProfileWalletSection(
                              jeton: jeton,
                              cfc: cfc,
                              onTopUp: () => context.push('/jeton-store'),
                              onCfcTopUp: () => context.push('/cfc-store'),
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
                            ProfileBroadcasterPanel(
                              onHistory: () =>
                                  context.push('/profile/broadcast-history'),
                              onSchedule: () => context.push('/live/prep'),
                              onStats: () =>
                                  context.push('/profile/broadcaster-stats'),
                              onEquipment: () =>
                                  context.push('/profile/equipment'),
                              onSettings: () => context.push('/live/prep'),
                            ),
                            const SizedBox(height: 22),
                            ProfileGiftsRow(
                              onViewAll: () => context.push('/profile/gifts'),
                            ),
                            const SizedBox(height: 16),
                            ProfileSettingsMenu(
                              onEditProfile: () => context.push('/profile/edit'),
                              onSecurity: () =>
                                  context.push('/profile/security'),
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
