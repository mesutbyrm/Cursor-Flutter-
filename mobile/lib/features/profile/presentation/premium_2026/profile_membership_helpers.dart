import 'package:intl/intl.dart';

import '../../../membership/domain/membership_model.dart';
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

  /// Süresi dolmuş ücretli plan (kalan gün biliniyorsa ve ≤ 0).
  bool get isExpired =>
      hasPaidTier && daysRemaining != null && daysRemaining! <= 0;

  /// Rozet / VIP erişimi için geçerli tier (süresi dolmuşsa basic).
  VipTier get effectiveTier =>
      hasActiveSubscription ? tier : VipTier.basic;

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

/// Katalog / API için wire kimliği (`basic`, `gold`, …).
/// Sosyal akış / yorum `author.role` — ücretli üyelik rozeti gösterilsin mi?
bool shouldShowSocialMembershipBadge(String? role) {
  if (role == null || role.trim().isEmpty) return false;
  final r = role.toLowerCase();
  if (r == 'fortune_teller' || r == 'agency') return false;
  return resolveProfileMembership(rawMembership: role).hasPaidTier;
}

String membershipWireId(String? rawMembership) {
  final info = resolveProfileMembership(rawMembership: rawMembership);
  if (!info.hasPaidTier) return 'basic';
  final wire = rawMembership?.toLowerCase().trim() ?? '';
  return switch (wire) {
    'svip' || 'super_vip' => 'svip',
    'diamond' => 'diamond',
    'gold' => 'gold',
    'premium' => 'premium',
    _ => wire.isNotEmpty ? wire : 'basic',
  };
}

/// Katalog tier listesinden kullanıcının planına karşılık gelen birleşik tier.
MembershipTierModel? catalogTierForMembership(
  ProfileMembershipInfo info,
  List<MembershipTierModel> tiers,
) {
  final wire = membershipWireId(info.raw);
  for (final t in tiers) {
    if (t.wireId == wire) return t;
  }
  return null;
}

/// Profil hub / banner alt başlığı — kalan gün + katalog süre/fal indirimi.
/// ISO bitiş tarihini kısa TR etiket (ör. 15.08.2026).
String? formatMembershipExpiryLabel(String? expiresAtIso) {
  final raw = expiresAtIso?.trim();
  if (raw == null || raw.isEmpty) return null;
  final exp = DateTime.tryParse(raw);
  if (exp == null) return null;
  return DateFormat('dd.MM.yyyy').format(exp.toLocal());
}

String formatMembershipPlanDuration({
  required ProfileMembershipInfo info,
  MembershipTierModel? catalogTier,
  int? daysRemaining,
  String? expiresAt,
}) {
  if (info.isExpired) return 'Yenile';
  final days = daysRemaining ?? info.daysRemaining;
  if (days != null && days > 0) {
    if (catalogTier != null &&
        catalogTier.durationDays > 0 &&
        catalogTier.durationDays != 30) {
      return '$days / ${catalogTier.durationDays} gün';
    }
    return '$days gün';
  }
  final expiry = formatMembershipExpiryLabel(expiresAt);
  if (expiry != null) return 'Bitiş: $expiry';
  if (catalogTier != null && catalogTier.durationDays > 0) {
    return catalogTier.durationLabel;
  }
  return '—';
}

String buildMembershipCatalogHintSubtitle({
  required ProfileMembershipInfo info,
  MembershipTierModel? catalogTier,
  String? expiresAt,
}) {
  final parts = <String>[];
  final expired = info.isExpired;
  final active = info.hasActiveSubscription;
  final days = info.daysRemaining;

  if (expired) {
    parts.add('${info.tierLabel} planınız sona erdi · yenileyin');
  } else if (active) {
    if (days != null && days > 0) {
      parts.add('$days gün kaldı');
    } else {
      final expiry = formatMembershipExpiryLabel(expiresAt);
      parts.add(expiry != null ? 'Bitiş: $expiry' : 'Aktif üyelik');
    }
  } else if (info.hasPaidTier) {
    parts.add('Rozetler, öncelikli destek ve VIP odalar');
  } else {
    parts.add('Gold, Diamond ve SVIP planlarını keşfedin');
  }

  if (catalogTier != null) {
    if (catalogTier.durationDays > 0 && catalogTier.durationDays != 30) {
      parts.add('${catalogTier.durationLabel} plan');
    }
    if (catalogTier.falDiscountPercent > 0) {
      parts.add('%${catalogTier.falDiscountPercent} fal indirimi');
    }
  }

  return parts.join(' · ');
}

/// Görevler merkezi üyelik kartı alt başlığı.
String buildGrowthHubMembershipSubtitle({
  required ProfileMembershipInfo info,
  MembershipTierModel? catalogTier,
  String? expiresAt,
}) {
  if (info.hasActiveSubscription) {
    final plan = formatMembershipPlanDuration(
      info: info,
      catalogTier: catalogTier,
      daysRemaining: info.daysRemaining,
      expiresAt: expiresAt,
    );
    return '$plan · görev bonusları aktif';
  }
  return buildMembershipCatalogHintSubtitle(
    info: info,
    catalogTier: catalogTier,
    expiresAt: expiresAt,
  );
}
