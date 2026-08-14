import '../../../vip_gold/domain/vip_tier.dart';
import '../../../wallet/domain/wallet_balances.dart';

/// Profil ekranında üyelik tier / etiket çözümlemesi.
class ProfileMembershipInfo {
  const ProfileMembershipInfo({
    required this.raw,
    required this.tier,
    this.daysRemaining,
  });

  final String? raw;
  final VipTier tier;
  final int? daysRemaining;

  /// `free`, `basic` veya boş — ücretli plan yok.
  bool get hasPaidTier => tier.index > VipTier.basic.index;

  /// Gold ve üzeri (VIP odalar, çerçeve vb.).
  bool get isVip => tier.isVip;

  /// Süresi dolmamış ücretli abonelik.
  bool get hasActiveSubscription =>
      hasPaidTier && (daysRemaining == null || daysRemaining! > 0);

  /// UI'da gösterilecek kısa etiket (ör. Gold, Premium).
  String get tierLabel => tier.label;

  /// Ham API değeri yerine okunabilir etiket; ücretsizde `null`.
  String? get displayMembership => hasPaidTier ? tierLabel : null;
}

ProfileMembershipInfo resolveProfileMembership({
  String? rawMembership,
  int? daysRemaining,
}) {
  final raw = rawMembership?.trim();
  final normalized = (raw == null || raw.isEmpty) ? null : raw;
  return ProfileMembershipInfo(
    raw: normalized,
    tier: VipTier.fromMembership(normalized),
    daysRemaining: daysRemaining,
  );
}

/// Kısa yol — ham API üyelik değerinden ücretli plan var mı?
bool hasPaidMembershipRaw(String? rawMembership) =>
    resolveProfileMembership(rawMembership: rawMembership).hasPaidTier;

/// Cüzdan ham değeri öncelikli üyelik çözümlemesi (profil state etiketi yedek).
ProfileMembershipInfo profileMembershipFromWallet(
  WalletBalances? wallet,
) {
  return resolveProfileMembership(
    rawMembership: wallet?.membership,
    daysRemaining: wallet?.membershipDaysRemaining,
  );
}
