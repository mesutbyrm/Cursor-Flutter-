import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../wallet/domain/wallet_balances.dart';
import '../../../cosmetics/presentation/providers/cosmetics_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/presentation/premium_2026/profile_membership_helpers.dart';
import '../../data/membership_remote_datasource.dart';
import '../../domain/membership_catalog_merge.dart';
import '../../domain/membership_model.dart';
import '../../domain/membership_package_entity.dart';
import '../../../profile/data/jeton_packages_catalog.dart';

final membershipRemoteProvider = Provider<MembershipRemoteDataSource>((ref) {
  return MembershipRemoteDataSource(ref.watch(dioProvider));
});

final membershipCatalogProvider =
    FutureProvider<MembershipCatalogEntity>((ref) async {
  ref.keepAlive();
  WalletBalances wallet;
  try {
    wallet = await ref.watch(walletBalancesProvider.future).timeout(
          const Duration(seconds: 6),
        );
  } catch (_) {
    wallet = const WalletBalances();
  }
  return ref.watch(membershipRemoteProvider).loadCatalog(wallet);
});

class MembershipUiState {
  const MembershipUiState({
    this.selectedTier = MembershipTierId.gold,
    this.selectedTokenPackage = MembershipTierId.gold,
    this.diamondBalance = 0,
    this.jetonBalance = 0,
    this.cfcBalance = 0,
    this.currentMembership = 'basic',
    this.daysRemaining = 0,
    this.membershipExpiresAt,
    this.apiPackages = const [],
    this.jetonTlRate = kDefaultJetonTlRate,
  });

  final MembershipTierId selectedTier;
  final MembershipTierId selectedTokenPackage;
  final int diamondBalance;
  final int jetonBalance;
  final int cfcBalance;
  final String currentMembership;
  final int daysRemaining;
  final String? membershipExpiresAt;
  final List<MembershipPackageEntity> apiPackages;
  final double jetonTlRate;

  MembershipPackageEntity? apiPackageFor(String wireId) =>
      findMembershipApiPackage(apiPackages, wireId);

  List<MembershipTierModel> get tiers {
    return [
      for (final t in MembershipCatalogData.tiers)
        mergeMembershipTier(
          t,
          apiPackageFor(t.wireId),
          jetonTlRate: jetonTlRate,
        ),
    ];
  }

  List<MembershipTokenPackageModel> get tokenPackages =>
      buildTokenPackagesFromTiers(tiers);

  MembershipTierModel get selectedTierModel =>
      tiers.firstWhere((t) => t.id == selectedTier);

  MembershipTokenPackageModel get selectedTokenModel =>
      tokenPackages.firstWhere((p) => p.tierId == selectedTokenPackage);

  String get formattedDiamondBalance {
    final fmt = NumberFormat.decimalPattern('tr_TR');
    return fmt.format(diamondBalance);
  }

  bool get hasActivePaidMembership {
    return membershipInfo.hasActiveSubscription;
  }

  ProfileMembershipInfo get membershipInfo => resolveProfileMembership(
        rawMembership: currentMembership,
        daysRemaining: daysRemaining,
      );

  String get currentMembershipLabel => membershipInfo.tierLabel;

  bool get isMembershipExpired => membershipInfo.isExpired;

  MembershipUiState copyWith({
    MembershipTierId? selectedTier,
    MembershipTierId? selectedTokenPackage,
    int? diamondBalance,
    int? jetonBalance,
    int? cfcBalance,
    String? currentMembership,
    int? daysRemaining,
    String? membershipExpiresAt,
    List<MembershipPackageEntity>? apiPackages,
    double? jetonTlRate,
  }) {
    return MembershipUiState(
      selectedTier: selectedTier ?? this.selectedTier,
      selectedTokenPackage: selectedTokenPackage ?? this.selectedTokenPackage,
      diamondBalance: diamondBalance ?? this.diamondBalance,
      jetonBalance: jetonBalance ?? this.jetonBalance,
      cfcBalance: cfcBalance ?? this.cfcBalance,
      currentMembership: currentMembership ?? this.currentMembership,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      membershipExpiresAt: membershipExpiresAt ?? this.membershipExpiresAt,
      apiPackages: apiPackages ?? this.apiPackages,
      jetonTlRate: jetonTlRate ?? this.jetonTlRate,
    );
  }
}

class MembershipController extends Notifier<MembershipUiState> {
  @override
  MembershipUiState build() {
    ref.listen<AsyncValue<WalletBalances>>(walletBalancesProvider, (_, next) {
      final wallet = next.valueOrNull;
      if (wallet == null) return;
      state = state.copyWith(
        membershipExpiresAt: wallet.membershipExpiresAt,
        daysRemaining:
            wallet.membershipDaysRemaining ?? state.daysRemaining,
        currentMembership: wallet.membership ?? state.currentMembership,
      );
    });
    ref.listen<AsyncValue<MembershipCatalogEntity>>(
      membershipCatalogProvider,
      (_, next) {
        final cat = next.valueOrNull;
        if (cat == null) return;
        final cur = cat.currentMembership.toLowerCase();
        final selected = switch (cur) {
          'gold' => MembershipTierId.gold,
          'premium' => MembershipTierId.premium,
          'diamond' => MembershipTierId.diamond,
          'svip' || 'super_vip' => MembershipTierId.svip,
          'basic' || 'free' || '' => MembershipTierId.basic,
          _ => MembershipTierId.gold,
        };
        final recommended = recommendedTierFromPackages(cat.packages);
        final initialTier = selected == MembershipTierId.basic
            ? (recommended ?? MembershipTierId.gold)
            : selected;
        state = state.copyWith(
          diamondBalance: cat.jetonBalance,
          jetonBalance: cat.jetonBalance,
          cfcBalance: cat.cfcBalance,
          currentMembership: cat.currentMembership,
          daysRemaining: cat.daysRemaining ?? cat.activePackage?.daysRemaining ?? 0,
          membershipExpiresAt: ref
                  .read(walletBalancesProvider)
                  .valueOrNull
                  ?.membershipExpiresAt ??
              state.membershipExpiresAt,
          apiPackages: cat.packages,
          jetonTlRate: ref.read(walletBalancesProvider).valueOrNull?.jetonTlRate ??
              kDefaultJetonTlRate,
          selectedTier: initialTier,
          selectedTokenPackage: initialTier,
        );
      },
      fireImmediately: true,
    );
    return const MembershipUiState();
  }

  void selectTier(MembershipTierId id) {
    state = state.copyWith(
      selectedTier: id,
      selectedTokenPackage: id,
    );
  }

  void selectTokenPackage(MembershipTierId id) {
    state = state.copyWith(
      selectedTokenPackage: id,
      selectedTier: id,
    );
  }

  Future<void> refresh() async {
    ref.invalidate(membershipCatalogProvider);
    ref.invalidate(membershipBadgesCatalogProvider);
    invalidateWalletCacheFromRef(ref);
    await ref.read(membershipCatalogProvider.future);
  }
}

final membershipControllerProvider =
    NotifierProvider<MembershipController, MembershipUiState>(
  MembershipController.new,
);
