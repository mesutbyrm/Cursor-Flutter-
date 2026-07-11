import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../wallet/domain/wallet_balances.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/membership_remote_datasource.dart';
import '../../domain/membership_model.dart';
import '../../domain/membership_package_entity.dart';

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
    this.apiPackages = const [],
  });

  final MembershipTierId selectedTier;
  final MembershipTierId selectedTokenPackage;
  final int diamondBalance;
  final int jetonBalance;
  final int cfcBalance;
  final String currentMembership;
  final int daysRemaining;
  final List<MembershipPackageEntity> apiPackages;

  List<MembershipTierModel> get tiers {
    return [
      for (final t in MembershipCatalogData.tiers)
        MembershipTierModel(
          id: t.id,
          title: t.title,
          subtitle: t.subtitle,
          monthlyTokens: t.monthlyTokens,
          monthlyPriceTry: t.monthlyPriceTry,
          accent: t.accent,
          badgeIcon: t.badgeIcon,
          glow: t.glow,
          popular: t.popular,
          planId: _planIdFor(t.wireId),
        ),
    ];
  }

  String? _planIdFor(String wireId) {
    for (final p in apiPackages) {
      if (p.id.toLowerCase() == wireId) return p.planId;
    }
    return null;
  }

  MembershipTierModel get selectedTierModel =>
      MembershipCatalogData.tierById(selectedTier);

  MembershipTokenPackageModel get selectedTokenModel =>
      MembershipCatalogData.tokenPackages
          .firstWhere((p) => p.tierId == selectedTokenPackage);

  String get formattedDiamondBalance {
    final fmt = NumberFormat.decimalPattern('tr_TR');
    return fmt.format(diamondBalance);
  }

  bool get hasActivePaidMembership {
    final cur = currentMembership.toLowerCase();
    return daysRemaining > 0 && cur != 'basic' && cur.isNotEmpty;
  }

  MembershipUiState copyWith({
    MembershipTierId? selectedTier,
    MembershipTierId? selectedTokenPackage,
    int? diamondBalance,
    int? jetonBalance,
    int? cfcBalance,
    String? currentMembership,
    int? daysRemaining,
    List<MembershipPackageEntity>? apiPackages,
  }) {
    return MembershipUiState(
      selectedTier: selectedTier ?? this.selectedTier,
      selectedTokenPackage: selectedTokenPackage ?? this.selectedTokenPackage,
      diamondBalance: diamondBalance ?? this.diamondBalance,
      jetonBalance: jetonBalance ?? this.jetonBalance,
      cfcBalance: cfcBalance ?? this.cfcBalance,
      currentMembership: currentMembership ?? this.currentMembership,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      apiPackages: apiPackages ?? this.apiPackages,
    );
  }
}

class MembershipController extends Notifier<MembershipUiState> {
  @override
  MembershipUiState build() {
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
          'basic' => MembershipTierId.basic,
          _ => MembershipTierId.gold,
        };
        state = state.copyWith(
          diamondBalance: cat.jetonBalance,
          jetonBalance: cat.jetonBalance,
          cfcBalance: cat.cfcBalance,
          currentMembership: cat.currentMembership,
          daysRemaining: cat.daysRemaining ?? cat.activePackage?.daysRemaining ?? 0,
          apiPackages: cat.packages,
          selectedTier: selected == MembershipTierId.basic
              ? MembershipTierId.gold
              : selected,
          selectedTokenPackage: selected == MembershipTierId.basic
              ? MembershipTierId.gold
              : selected,
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
    invalidateWalletCacheFromRef(ref);
    await ref.read(membershipCatalogProvider.future);
  }
}

final membershipControllerProvider =
    NotifierProvider<MembershipController, MembershipUiState>(
  MembershipController.new,
);
