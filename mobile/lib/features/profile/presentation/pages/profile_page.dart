import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/performance/network_perf.dart';
import '../../../../core/performance/profile_load_perf.dart';
import '../../../../core/performance/scroll_perf.dart';
import '../../../../core/ui/premium_2026/premium_motion.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../core/ui/responsive/responsive_layout.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../fortune/presentation/providers/fortune_access_providers.dart';
import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../providers/profile_providers.dart';
import '../../../social/presentation/providers/user_social_posts_notifier.dart';
import '../premium_2026/profile_page_layout.dart';
import '../premium_2026/profile_lazy_sections.dart';
import '../premium_2026/profile_screen_builder.dart';
import '../premium_2026/widgets/profile_header.dart';
import '../premium_2026/widgets/profile_quick_actions.dart';
import '../widgets/profile_guest_sign_in_card.dart';

/// Profil — Premium 2026 kişisel kontrol merkezi.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final guest = ref.watch(guestModeProvider);
    final top = MediaQuery.paddingOf(context).top;

    Future<void> refresh() async {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
      ref.invalidate(profileStatsProvider);
      ref.invalidate(userLevelProvider);
      ref.invalidate(giftsReceivedSummaryProvider);
      ref.invalidate(fortuneAccessStateProvider);
      final userId = ref.read(authControllerProvider).valueOrNull?.id;
      if (userId != null) {
        ref.invalidate(userSocialPostsNotifierProvider(userId));
      }
      await NetworkPerf.waitSilent([
        ref.read(authControllerProvider.notifier).refreshMe(),
        ref.read(walletBalancesProvider.notifier).refresh(force: true),
        ref.read(profileStatsProvider.future),
        ref.read(userLevelProvider.future),
        ref.read(giftsReceivedSummaryProvider.future),
        ref.read(fortuneAccessStateProvider.future),
        if (userId != null)
          ref.read(userSocialPostsNotifierProvider(userId).future),
      ]);
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
              if (user == null && guest) {
                return const ProfileGuestSignInCard();
              }
              if (user == null) {
                return const Center(
                  child: DiscoverEmptyState(
                    icon: Icons.person_off_outlined,
                    message: 'Oturum bulunamadı',
                  ),
                );
              }

              final base = profileScreenStateFromUser(user);
              ProfileLoadPerf.prefetchOnOpen(ref, user.id);
              final onLogout =
                  () => ref.read(authControllerProvider.notifier).logout();
              final staff = ref.watch(staffAccessProvider);
              final showPublisher = staff.showAdminPanel ||
                  staff.canManagePayments;

              return CustomScrollView(
                cacheExtent: ScrollPerf.feedCacheExtent,
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
                          showAdmin: staff.showAdminPanel,
                          showPublisher: showPublisher,
                          header: ProfileHeader(
                            state: base,
                            onEdit: () => context.push('/profile/edit'),
                            onAvatarTap: () => context.push('/profile/edit'),
                            onLogout: onLogout,
                          ),
                          stats: ProfileLazyStats(user: user, base: base),
                          quickActions: const ProfileQuickActions(),
                          wallet: ProfileLazyWallet(base: base),
                          premium: ProfileLazyPremium(base: base),
                          publisher: showPublisher
                              ? const ProfileLazyPublisher()
                              : const SizedBox.shrink(),
                          teller: const ProfileLazyTeller(),
                          admin: staff.showAdminPanel
                              ? const ProfileLazyAdmin()
                              : const SizedBox.shrink(),
                          content: ProfileLazyContent(userId: user.id),
                          settings: ProfileLazySettings(onLogout: onLogout),
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
