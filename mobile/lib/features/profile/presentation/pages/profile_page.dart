import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../shell/presentation/widgets/branch_quick_actions.dart';
import '../providers/profile_providers.dart';
import '../widgets/premium/profile_broadcaster_panel.dart';
import '../widgets/premium/profile_gifts_row.dart';
import '../widgets/premium/profile_neon_header.dart';
import '../widgets/premium/profile_premium_banner.dart';
import '../widgets/premium/profile_settings_menu.dart';
import '../widgets/premium/profile_wallet_section.dart';

/// Ultra premium neon profil — canlı yayın uygulaması.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final coins = ref.watch(coinBalanceProvider);
    final top = MediaQuery.paddingOf(context).top;

    Future<void> refresh() async {
      await ref.read(authControllerProvider.notifier).refreshMe();
      ref.invalidate(coinBalanceProvider);
    }

    return Scaffold(
      backgroundColor: AppDesign.bgBase,
      body: DiscoverBackground(
        child: RefreshIndicator(
          color: AppDesign.accentPink,
          backgroundColor: AppDesign.bgPurpleGlow,
          onRefresh: refresh,
          child: auth.when(
            loading: () => const Center(child: DiscoverAccentLoader()),
            error: (e, _) => Center(
              child: DiscoverEmptyState(
                icon: Icons.error_outline_rounded,
                message: ApiException.userMessage(e),
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
              final balance = coins.maybeWhen(
                data: (c) => c,
                orElse: () => user.coinBalance,
              );

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: top + 8)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        ProfileNeonHeader(
                          displayName: user.display,
                          username: user.username,
                          avatarUrl: user.avatarUrl,
                          followers: user.followersCount,
                          following: user.followingCount,
                          bio: user.bio ??
                              '🎵 Müzik, sohbet ve eğlence dolu yayınlar…',
                          diamondBalance: balance,
                          onNotifications: () =>
                              context.push('/notifications'),
                          onLogout: () => ref
                              .read(authControllerProvider.notifier)
                              .logout(),
                          onEdit: () => _openPublicProfile(context, user),
                        ),
                        const SizedBox(height: 16),
                        const ProfileBranchQuickActions(),
                        const SizedBox(height: 20),
                        ProfilePremiumBanner(
                          onViewPrivileges: () => _showSnack(
                            context,
                            'Premium ayrıcalıkları yakında',
                          ),
                        ),
                        const SizedBox(height: 22),
                        ProfileWalletSection(
                          coinBalance: balance,
                          onTopUp: () => context.push('/jeton-store'),
                          onEarnings: () => _showSnack(
                            context,
                            'Kazançlar yakında',
                          ),
                          onTransactions: () => ref.invalidate(
                            coinBalanceProvider,
                          ),
                          onSubscriptions: () => context.go('/social'),
                        ),
                        const SizedBox(height: 22),
                        const ProfileBroadcasterPanel(),
                        const SizedBox(height: 22),
                        ProfileGiftsRow(
                          onViewAll: () => _showSnack(
                            context,
                            'Hediye koleksiyonu yakında',
                          ),
                        ),
                        const SizedBox(height: 16),
                        ProfileSettingsMenu(
                          onEditProfile: () =>
                              _openPublicProfile(context, user),
                          onNotifications: () =>
                              context.push('/notifications'),
                        ),
                        const SizedBox(height: 120),
                      ]),
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

  static void _openPublicProfile(BuildContext context, UserEntity user) {
    context.push('/user/${user.id}');
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
