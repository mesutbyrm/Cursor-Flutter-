import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bootstrap/startup_perf.dart';
import '../../../../core/navigation/wallet_navigation.dart';
import '../../../../core/performance/lazy_screen_section.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../providers/profile_providers.dart';
import 'profile_screen_builder.dart';
import 'profile_screen_state.dart';
import 'widgets/profile_admin_card.dart';
import 'widgets/profile_content_section.dart';
import 'widgets/profile_fortune_teller_card.dart';
import 'widgets/profile_premium_card.dart';
import 'widgets/profile_publisher_card.dart';
import 'widgets/profile_settings_section.dart';
import 'widgets/profile_stats.dart';
import 'widgets/profile_wallet_card.dart';

class ProfileLazyStats extends ConsumerWidget {
  const ProfileLazyStats({
    super.key,
    required this.user,
    required this.base,
  });

  final UserEntity user;
  final ProfileScreenState base;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(
      profileStatsProvider.select((s) => s.valueOrNull ?? base.stats),
    );
    final state = base.copyWith(stats: stats);

    return LazyScreenSection(
      delay: LazyLoadPerf.profileStats,
      placeholder: const PremiumProfileStatsSkeleton(),
      child: ProfileStats(
        state: state,
        onFollowersTap: () =>
            context.push('/profile/followers?userId=${user.id}'),
        onFollowingTap: () =>
            context.push('/profile/following?userId=${user.id}'),
        onVisitorsTap: () => context.push('/profile/visitors'),
      ),
    );
  }
}

class ProfileLazyWallet extends ConsumerWidget {
  const ProfileLazyWallet({
    super.key,
    required this.base,
  });

  final ProfileScreenState base;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(
      walletBalancesProvider.select((w) => w.valueOrNull),
    );
    final state = buildProfileWalletState(base, wallet);

    return LazyScreenSection(
      delay: LazyLoadPerf.profileWallet,
      placeholder: const PremiumProfileWalletSkeleton(),
      child: ProfileWalletCard(
        state: state,
        onTopUp: () => openJetonStore(context, ref: ref),
        onCfcTopUp: () => openCfcStore(context, ref: ref),
        onEarnings: () => context.push('/profile/earnings'),
        onTransactions: () => context.push('/profile/transactions'),
        onPaymentNotice: () => context.push('/profile/payment-notice'),
        onSubscriptions: () => context.push('/wallet'),
      ),
    );
  }
}

class ProfileLazyPremium extends ConsumerWidget {
  const ProfileLazyPremium({super.key, required this.base});

  final ProfileScreenState base;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(
      walletBalancesProvider.select(
        (w) => buildProfileWalletState(base, w.valueOrNull).membership,
      ),
    );
    final daysRemaining = ref.watch(
      walletBalancesProvider.select(
        (w) => buildProfileWalletState(base, w.valueOrNull).membershipDays,
      ),
    );

    return LazyScreenSection(
      delay: LazyLoadPerf.profilePremium,
      child: ProfilePremiumCard(
        membership: membership,
        daysRemaining: daysRemaining,
        onViewPrivileges: () => context.push('/vip-gold'),
      ),
    );
  }
}

class ProfileLazyPublisher extends ConsumerWidget {
  const ProfileLazyPublisher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LazyScreenSection(
      delay: LazyLoadPerf.profilePublisher,
      child: ProfilePublisherCard(
        onHistory: () => context.push('/profile/broadcast-history'),
        onSchedule: () => context.push('/live/schedule'),
        onStats: () => context.push('/profile/broadcaster-stats'),
        onEquipment: () => context.push('/profile/equipment'),
        onSettings: () => context.push('/live/type'),
        onEarnings: () => context.push('/profile/earnings'),
        onGifts: () => context.push('/profile/gifts'),
      ),
    );
  }
}

class ProfileLazyTeller extends ConsumerWidget {
  const ProfileLazyTeller({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LazyScreenSection(
      delay: LazyLoadPerf.profileTeller,
      child: const ProfileFortuneTellerCard(),
    );
  }
}

class ProfileLazyAdmin extends ConsumerWidget {
  const ProfileLazyAdmin({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LazyScreenSection(
      delay: LazyLoadPerf.profileAdmin,
      child: Consumer(
        builder: (context, ref, _) {
          final staff = ref.watch(staffAccessProvider);
          if (!staff.canManagePayments) return const SizedBox.shrink();
          return const ProfileAdminCard();
        },
      ),
    );
  }
}

class ProfileLazyContent extends ConsumerWidget {
  const ProfileLazyContent({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LazyScreenSection(
      delay: LazyLoadPerf.profileContent,
      placeholder: const PremiumProfileContentSkeleton(),
      child: ProfileContentSection(userId: userId),
    );
  }
}

class ProfileLazySettings extends ConsumerWidget {
  const ProfileLazySettings({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LazyScreenSection(
      delay: LazyLoadPerf.profileSettings,
      child: ProfileSettingsSection(onLogout: onLogout),
    );
  }
}

class PremiumProfileStatsSkeleton extends StatelessWidget {
  const PremiumProfileStatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: PremiumSkeleton(
        width: double.infinity,
        height: 72,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    );
  }
}

class PremiumProfileWalletSkeleton extends StatelessWidget {
  const PremiumProfileWalletSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: PremiumSkeleton(
        width: double.infinity,
        height: 120,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    );
  }
}

class PremiumProfileContentSkeleton extends StatelessWidget {
  const PremiumProfileContentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: PremiumSkeleton(
        width: double.infinity,
        height: 220,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    );
  }
}
