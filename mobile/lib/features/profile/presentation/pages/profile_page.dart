import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/wallet_navigation.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/premium_2026/premium_motion.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../core/ui/responsive/responsive_layout.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../fortune/presentation/providers/fortune_access_providers.dart';
import '../providers/profile_providers.dart';
import '../premium_2026/profile_page_layout.dart';
import '../premium_2026/profile_screen_builder.dart';
import '../premium_2026/widgets/profile_admin_card.dart';
import '../premium_2026/widgets/profile_content_section.dart';
import '../premium_2026/widgets/profile_fortune_teller_card.dart';
import '../premium_2026/widgets/profile_header.dart';
import '../premium_2026/widgets/profile_premium_card.dart';
import '../premium_2026/widgets/profile_publisher_card.dart';
import '../premium_2026/widgets/profile_quick_actions.dart';
import '../premium_2026/widgets/profile_settings_section.dart';
import '../premium_2026/widgets/profile_stats.dart';
import '../premium_2026/widgets/profile_wallet_card.dart';

/// Profil — Premium 2026 kişisel kontrol merkezi.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final top = MediaQuery.paddingOf(context).top;

    Future<void> refresh() async {
      await ref.read(authControllerProvider.notifier).refreshMe();
      await ref.read(walletBalancesProvider.notifier).refresh(force: true);
      ref.invalidate(profileStatsProvider);
      ref.invalidate(userLevelProvider);
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
            loading: () => const Center(child: PremiumProfileSkeleton()),
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

              final state = buildProfileScreenState(ref, user);

              return CustomScrollView(
                physics: PremiumMotion.listPhysics,
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: top + 8)),
                  SliverToBoxAdapter(
                    child: ResponsiveConstrained(
                      maxWidth: 1200,
                      child: Padding(
                        padding: ResponsiveLayout.pagePadding(
                          context,
                          bottom: 120,
                        ),
                        child: ProfilePageLayout(
                          header: ProfileHeader(
                            state: state,
                            onEdit: () => context.push('/profile/edit'),
                            onAvatarTap: () => context.push('/profile/edit'),
                            onLogout: () => ref
                                .read(authControllerProvider.notifier)
                                .logout(),
                          ),
                          stats: ProfileStats(
                            state: state,
                            onFollowersTap: () => context.push(
                              '/profile/followers?userId=${user.id}',
                            ),
                            onFollowingTap: () => context.push(
                              '/profile/following?userId=${user.id}',
                            ),
                          ),
                          quickActions: const ProfileQuickActions(),
                          wallet: ProfileWalletCard(
                            state: state,
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
                          premium: ProfilePremiumCard(
                            membership: state.membership,
                            daysRemaining: state.membershipDays,
                            onViewPrivileges: () => context.push('/vip-gold'),
                          ),
                          publisher: ProfilePublisherCard(
                            onHistory: () =>
                                context.push('/profile/broadcast-history'),
                            onSchedule: () => context.push('/live/schedule'),
                            onStats: () =>
                                context.push('/profile/broadcaster-stats'),
                            onEquipment: () =>
                                context.push('/profile/equipment'),
                            onSettings: () => context.push('/live/type'),
                            onEarnings: () =>
                                context.push('/profile/earnings'),
                            onGifts: () => context.push('/profile/gifts'),
                          ),
                          teller: const ProfileFortuneTellerCard(),
                          admin: const ProfileAdminCard(),
                          content: ProfileContentSection(userId: user.id),
                          settings: ProfileSettingsSection(
                            onLogout: () => ref
                                .read(authControllerProvider.notifier)
                                .logout(),
                          ),
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
