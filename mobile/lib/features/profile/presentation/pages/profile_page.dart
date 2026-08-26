import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/performance/profile_load_perf.dart';
import '../../../../core/performance/scroll_perf.dart';
import '../../../../core/ui/premium_2026/premium_motion.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../core/ui/responsive/responsive_layout.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../fortune/presentation/providers/fortune_access_providers.dart';
import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../premium_2026/profile_screen_builder.dart';
import '../profile_hub/profile_hub_layout.dart';
import '../providers/profile_hub_providers.dart';
import '../widgets/profile_guest_sign_in_card.dart';

/// Profil — Premium 2026 kişisel kontrol merkezi.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = ref.watch(authControllerProvider.select((a) => a.valueOrNull));
    final guest = ref.watch(guestModeProvider);
    final top = MediaQuery.paddingOf(context).top;
    if (user != null) {
      ProfileLoadPerf.prefetchOnOpen(ref, user.id);
    }

    Future<void> refresh() async {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
      unawaited(refreshProfileHub(ref, userId: user?.id));
      ref.invalidate(fortuneAccessStateProvider);
      unawaited(ref.read(fortuneAccessStateProvider.future));
    }

    // Not: DiscoverBackground (immersive gradient + RepaintBoundary alt katman)
    // bu cihazda önceki karenin izini bırakıp profil bölümlerini üst üste
    // gösteriyordu (teşhis: routes=1, overlay=0 — yani ikinci sayfa yok,
    // katman raster hayaleti). Her karede tam temizleyen opak zemin kullanılır.
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: RefreshIndicator(
          color: context.accentPink,
          backgroundColor: context.colors.surfaceContainer,
          onRefresh: refresh,
          child: _ProfileScrollBody(
            top: top,
            auth: auth,
            guest: guest,
            user: user,
          ),
        ),
      ),
    );
  }
}

/// Her zaman kaydırılabilir — RefreshIndicator boş ekran üretmez.
class _ProfileScrollBody extends ConsumerWidget {
  const _ProfileScrollBody({
    required this.top,
    required this.auth,
    required this.guest,
    required this.user,
  });

  final double top;
  final AsyncValue<UserEntity?> auth;
  final bool guest;
  final UserEntity? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionUser = user;

    if (auth.hasError && sessionUser == null) {
      return _profileScroll(
        context,
        [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: ResponsiveLayout.pagePadding(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DiscoverEmptyState(
                    icon: Icons.error_outline_rounded,
                    message: ApiException.userMessage(
                      auth.error ?? 'Profil bilgileri yüklenemedi',
                    ),
                    actionLabel: 'Tekrar dene',
                    action: () {
                      ref.invalidate(authControllerProvider);
                      unawaited(
                        ref.read(authControllerProvider.notifier).refreshMe(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (sessionUser == null && auth.isLoading) {
      return _profileScroll(
        context,
        const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: PremiumProfileSkeleton()),
          ),
        ],
      );
    }

    if (sessionUser == null && guest) {
      return _profileScroll(
        context,
        const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: ProfileGuestSignInCard(),
          ),
        ],
      );
    }

    if (sessionUser == null) {
      return _profileScroll(
        context,
        const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: DiscoverEmptyState(
                icon: Icons.person_off_outlined,
                message: 'Oturum bulunamadı',
              ),
            ),
          ),
        ],
      );
    }

    final profileUser = sessionUser;
    final base = buildProfileScreenState(ref, profileUser);
    ProfileLoadPerf.prefetchOnOpen(ref, profileUser.id);
    final onLogout = () => ref.read(authControllerProvider.notifier).logout();
    final staff = ref.watch(staffAccessProvider);
    const showPublisher = true;

    return ProfileRealtimeSync(
      child: _profileScroll(
        context,
        [
          // Kapak durum çubuğunun altına kadar uzanır; ekstra üst boşluk yok.
          SliverToBoxAdapter(
            child: ResponsiveConstrained(
              maxWidth: 1200,
              child: Padding(
                padding: ResponsiveLayout.pagePadding(
                  context,
                  bottom: 120,
                ),
                child: ProfileHubLayout(
                  state: base,
                  userId: profileUser.id,
                  onRefresh: () => refreshProfileHub(ref, userId: profileUser.id),
                  showAdmin: staff.showAdminPanel,
                  showPublisher: showPublisher,
                  onLogout: onLogout,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileScroll(BuildContext context, List<Widget> slivers) {
    return CustomScrollView(
      clipBehavior: Clip.hardEdge,
      scrollCacheExtent: ScrollPerf.scrollCache(ScrollPerf.feedCacheExtent),
      physics: PremiumMotion.listPhysics,
      slivers: slivers,
    );
  }
}
