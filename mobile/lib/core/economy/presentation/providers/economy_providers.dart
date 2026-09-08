import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../network/dio_provider.dart';
import '../../data/currency_branding_remote_datasource.dart';
import '../../data/economy_wallet_remote_datasource.dart';
import '../../data/referral_economy_remote_datasource.dart';
import '../../domain/agency_invite_earnings_snapshot.dart';
import '../../domain/currency_brand.dart';
import '../../domain/currency_branding_snapshot.dart';
import '../../domain/economy_wallet_snapshot.dart';
import '../../domain/referral_economy_snapshot.dart';
import '../../domain/topup_bonus_tier.dart';
import '../../services/currency_branding_cache.dart';
import '../../services/economy_wallet_adapter.dart';
import '../../../../features/profile/presentation/providers/profile_providers.dart';

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

/// Yalnızca `GET /api/user/wallet` — fallback yok; UI ekleri için.
final unifiedEconomyWalletProvider =
    FutureProvider<EconomyWalletSnapshot?>((ref) async {
  return ref.watch(economyWalletRemoteProvider).fetchWallet();
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

CurrencyBrand resolveEconomyBrandFromSnapshot(
  CurrencyBrandingSnapshot? snapshot, {
  required String key,
}) {
  if (snapshot != null) {
    return snapshot.brandForKey(key);
  }
  return key.toLowerCase() == 'jeton'
      ? CurrencyBrand.jetonFallback
      : CurrencyBrand.cfcFallback;
}

CurrencyBrand resolveEconomyBrand(
  WidgetRef ref, {
  required String key,
}) {
  return resolveEconomyBrandFromSnapshot(
    ref.watch(currencyBrandingProvider).valueOrNull,
    key: key,
  );
}

/// Notifier / provider bağlamında — `read` ile tek seferlik etiket.
CurrencyBrand resolveEconomyBrandRead(
  Ref ref, {
  required String key,
}) {
  return resolveEconomyBrandFromSnapshot(
    ref.read(currencyBrandingProvider).valueOrNull,
    key: key,
  );
}

String economyCurrencyLabelFromBrand(
  CurrencyBrand brand, {
  Locale? locale,
}) {
  final loc = locale ?? const Locale('tr');
  return brand.labelForLocale(loc);
}

String economyCurrencyLabel(
  WidgetRef ref, {
  required String key,
  Locale? locale,
}) {
  final brand = resolveEconomyBrand(ref, key: key);
  return economyCurrencyLabelFromBrand(brand, locale: locale);
}

/// Notifier içinde markalı etiket — WidgetRef gerekmez.
String economyCurrencyLabelRead(
  Ref ref, {
  required String key,
  Locale? locale,
}) {
  final brand = resolveEconomyBrandRead(ref, key: key);
  return economyCurrencyLabelFromBrand(brand, locale: locale);
}

/// Hızlı işlem karosu: «Jeton\nyükle».
String economyJetonTopUpTileLabel(WidgetRef ref, {Locale? locale}) {
  final label = economyCurrencyLabel(ref, key: 'jeton', locale: locale);
  return '$label\nyükle';
}

/// Tek satır: «Jeton Yükle» / «Jeton Al».
String economyJetonTopUpShortLabel(WidgetRef ref, {Locale? locale}) {
  final label = economyCurrencyLabel(ref, key: 'jeton', locale: locale);
  return '$label Yükle';
}

String economyJetonBuyActionLabel(WidgetRef ref, {Locale? locale}) {
  final label = economyCurrencyLabel(ref, key: 'jeton', locale: locale);
  return '$label Al';
}

/// Tek satır: «CFC Yükle» (markalı).
String economyCfcTopUpShortLabel(WidgetRef ref, {Locale? locale}) {
  final label = economyCurrencyLabel(ref, key: 'cfc', locale: locale);
  return '$label Yükle';
}

/// Jeton mağazası sayfa başlığı.
String economyJetonPurchasePageTitle(WidgetRef ref, {Locale? locale}) {
  final label = economyCurrencyLabel(ref, key: 'jeton', locale: locale);
  return '$label Satın Al';
}

/// Jeton mağazası alt başlık.
String economyJetonPurchasePageSubtitle(WidgetRef ref, {Locale? locale}) {
  final label = economyCurrencyLabel(ref, key: 'jeton', locale: locale);
  return 'İstediğiniz tutarı girin — $label otomatik hesaplanır';
}

/// Bakiye kartı başlığı: «Jeton Bakiye».
String economyJetonBalanceHeaderLabel(WidgetRef ref, {Locale? locale}) {
  final label = economyCurrencyLabel(ref, key: 'jeton', locale: locale);
  return '$label Bakiye';
}

/// Profil hızlı menü: «Jeton Geçmişim».
String economyJetonHistoryMenuLabel(WidgetRef ref, {Locale? locale}) {
  final label = economyCurrencyLabel(ref, key: 'jeton', locale: locale);
  return '$label Geçmişim';
}

/// Üyelik sayfası paket bölümü: «Jeton Paketleri».
String economyJetonPackagesSectionTitle(WidgetRef ref, {Locale? locale}) {
  final label = economyCurrencyLabel(ref, key: 'jeton', locale: locale);
  return '$label Paketleri';
}

/// CFC bakiye kartı: «CFC Bakiyeniz».
String economyCfcBalanceHeaderLabel(WidgetRef ref, {Locale? locale}) {
  final label = economyCurrencyLabel(ref, key: 'cfc', locale: locale);
  return '$label Bakiyeniz';
}

/// Yetersiz bakiye — genel (müzik isteği, fal vb.).
String economyInsufficientJetonMessage(
  WidgetRef ref, {
  required int required,
  Locale? locale,
}) {
  final label = economyCurrencyLabel(ref, key: 'jeton', locale: locale);
  return 'Yetersiz $label. Gerekli: $required';
}

String economyInsufficientJetonMessageRead(
  Ref ref, {
  required int required,
  Locale? locale,
}) {
  final label = economyCurrencyLabelRead(ref, key: 'jeton', locale: locale);
  return 'Yetersiz $label. Gerekli: $required';
}

/// Sesli oda duyuru — yetersiz bakiye.
String economyInsufficientJetonForDuyuruMessage(
  WidgetRef ref, {
  required int cost,
  Locale? locale,
}) {
  final label = economyCurrencyLabel(ref, key: 'jeton', locale: locale);
  return 'Yetersiz $label. Duyuru için $cost $label gerekir.';
}

String economyInsufficientJetonForDuyuruMessageRead(
  Ref ref, {
  required int cost,
  Locale? locale,
}) {
  final label = economyCurrencyLabelRead(ref, key: 'jeton', locale: locale);
  return 'Yetersiz $label. Duyuru için $cost $label gerekir.';
}

/// Müzik / şarkı isteği — minimum bakiye.
String economyMinimumJetonForMusicRequestMessage(
  WidgetRef ref, {
  required int requiredCost,
  Locale? locale,
}) {
  final label = economyCurrencyLabel(ref, key: 'jeton', locale: locale);
  return 'Şarkı isteği için en az $requiredCost $label gerekir.';
}

String economyMinimumJetonForMusicRequestMessageRead(
  Ref ref, {
  required int requiredCost,
  Locale? locale,
}) {
  final label = economyCurrencyLabelRead(ref, key: 'jeton', locale: locale);
  return 'Şarkı isteği için en az $requiredCost $label gerekir.';
}

/// Hediye toast: «120 Jeton gönderdi».
String economyJetonGiftSentLine(
  WidgetRef ref, {
  required int amount,
  Locale? locale,
}) {
  final label = economyCurrencyLabel(ref, key: 'jeton', locale: locale);
  return '$amount $label gönderdi';
}

/// DM composer: «🪙 Jeton göndermek istiyor.» (markalı).
String economyJetonSendIntentMessage(WidgetRef ref, {Locale? locale}) {
  final label = economyCurrencyLabel(ref, key: 'jeton', locale: locale);
  return '🪙 $label göndermek istiyor.';
}

/// Bahşiş / bakiye satırı: «💰 Jeton bakiyeniz: 200».
String economyJetonBalanceLine(
  WidgetRef ref, {
  required int balance,
  Locale? locale,
}) {
  final label = economyCurrencyLabel(ref, key: 'jeton', locale: locale);
  return '💰 $label bakiyeniz: $balance';
}

String economyJetonBalanceLineRead(
  Ref ref, {
  required int balance,
  Locale? locale,
}) {
  final label = economyCurrencyLabelRead(ref, key: 'jeton', locale: locale);
  return '💰 $label bakiyeniz: $balance';
}

/// İade bildirimi: «Jeton bakiyeniz iade edilir».
String economyJetonBalanceRefundNotice(WidgetRef ref, {Locale? locale}) {
  final label = economyCurrencyLabel(ref, key: 'jeton', locale: locale);
  return '$label bakiyeniz iade edilir';
}

String economyJetonBalanceRefundNoticeRead(Ref ref, {Locale? locale}) {
  final label = economyCurrencyLabelRead(ref, key: 'jeton', locale: locale);
  return '$label bakiyeniz iade edilir';
}
