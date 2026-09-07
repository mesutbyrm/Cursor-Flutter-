import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/dio_provider.dart';
import '../data/currency_branding_remote_datasource.dart';
import '../data/economy_wallet_remote_datasource.dart';
import '../data/referral_economy_remote_datasource.dart';
import '../domain/agency_invite_earnings_snapshot.dart';
import '../domain/currency_brand.dart';
import '../domain/currency_branding_snapshot.dart';
import '../domain/economy_wallet_snapshot.dart';
import '../domain/referral_economy_snapshot.dart';
import '../domain/topup_bonus_tier.dart';
import '../services/currency_branding_cache.dart';
import '../services/economy_wallet_adapter.dart';
import '../../../features/profile/presentation/providers/profile_providers.dart';

final currencyBrandingRemoteProvider =
    Provider<CurrencyBrandingRemoteDataSource>((ref) {
  return CurrencyBrandingRemoteDataSource(ref.watch(dioProvider));
});

final economyWalletRemoteProvider =
    Provider<EconomyWalletRemoteDataSource>((ref) {
  return EconomyWalletRemoteDataSource(ref.watch(dioProvider));
});

final referralEconomyRemoteProvider =
    Provider<ReferralEconomyRemoteDataSource>((ref) {
  return ReferralEconomyRemoteDataSource(ref.watch(dioProvider));
});

final currencyBrandingCacheProvider = Provider<CurrencyBrandingCache>((ref) {
  return CurrencyBrandingCache(ref.watch(currencyBrandingRemoteProvider));
});

final economyWalletAdapterProvider = Provider<EconomyWalletAdapter>((ref) {
  return EconomyWalletAdapter(ref.watch(economyWalletRemoteProvider));
});

/// Uygulama genelinde markalama — endpoint yoksa varsayılan.
final currencyBrandingProvider =
    FutureProvider<CurrencyBrandingSnapshot>((ref) async {
  ref.keepAlive();
  return ref.watch(currencyBrandingCacheProvider).load();
});

/// Birleşik cüzdan — yeni uç yoksa mevcut bakiyeye düşer.
final economyWalletProvider =
    FutureProvider<EconomyWalletSnapshot>((ref) async {
  final branding = await ref.watch(currencyBrandingProvider.future);
  final adapter = ref.watch(economyWalletAdapterProvider);
  return adapter.fetchWithFallback(
    legacyFetch: () => ref.read(walletRepositoryProvider).balances(),
    branding: branding,
  );
});

/// Yeni referral ucu — başarısızsa null (mevcut referral akışı korunur).
final referralEconomyProvider =
    FutureProvider<ReferralEconomySnapshot?>((ref) async {
  return ref.watch(referralEconomyRemoteProvider).fetchUserReferralEarnings();
});

/// Ajans davet kazancı — ajans yoksa null.
final agencyInviteEarningsProvider =
    FutureProvider<AgencyInviteEarningsSnapshot?>((ref) async {
  return ref.watch(referralEconomyRemoteProvider).fetchAgencyInviteEarnings();
});

/// Bilgilendirme amaçlı varsayılan bonus kademeleri.
final topupBonusTiersProvider = Provider<List<TopupBonusTier>>((ref) {
  return TopupBonusTier.defaultTiers;
});

CurrencyBrand resolveEconomyBrand(
  WidgetRef ref, {
  required String key,
}) {
  final async = ref.watch(currencyBrandingProvider);
  return async.maybeWhen(
    data: (snapshot) => snapshot.brandForKey(key),
    orElse: () => key.toLowerCase() == 'jeton'
        ? CurrencyBrand.jetonFallback
        : CurrencyBrand.cfcFallback,
  );
}

String economyCurrencyLabel(
  WidgetRef ref, {
  required String key,
  Locale? locale,
}) {
  final brand = resolveEconomyBrand(ref, key: key);
  final loc = locale ?? const Locale('tr');
  return brand.labelForLocale(loc);
}
