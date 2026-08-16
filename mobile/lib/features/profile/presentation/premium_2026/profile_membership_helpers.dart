import 'package:intl/intl.dart';

import '../../../membership/domain/membership_catalog_merge.dart';
import '../../../membership/domain/membership_model.dart';
import '../../../membership/domain/membership_package_entity.dart';
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
    final expiry = formatMembershipExpiryLabel(expiresAt);
    if (expiry != null) {
      parts.add('${info.tierLabel} planınız $expiry tarihinde sona erdi');
    } else {
      parts.add('${info.tierLabel} planınız sona erdi · yenileyin');
    }
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

/// Süresi dolmuş plan başlığı — kart / istatistik satırı (ör. Gold · 15.08.2026).
String buildMembershipExpiredPlanLabel({
  required ProfileMembershipInfo info,
  String? expiresAt,
}) {
  final expiry = formatMembershipExpiryLabel(expiresAt);
  if (expiry != null) return '${info.tierLabel} · $expiry';
  return '${info.tierLabel} · süresi doldu';
}

/// Cüzdan / banner süresi dolmuş metni.
String buildMembershipExpiredBannerText({
  required ProfileMembershipInfo info,
  String? expiresAt,
}) {
  final expiry = formatMembershipExpiryLabel(expiresAt);
  if (expiry != null) {
    return '${info.tierLabel} planınız sona erdi · $expiry';
  }
  return '${info.tierLabel} planınız sona erdi · yenileyin';
}

/// Ücretsiz kullanıcı teaser — API popular tier + katalog ipuçları.
String buildFreeUserMembershipTeaserSubtitle({
  required List<MembershipTierModel> tiers,
  List<MembershipPackageEntity> packages = const [],
}) {
  final parts = <String>[];
  final recommendedId = recommendedTierFromPackages(packages);
  MembershipTierModel? featured;
  if (recommendedId != null) {
    for (final tier in tiers) {
      if (tier.id == recommendedId) {
        featured = tier;
        break;
      }
    }
  }
  featured ??= () {
    for (final tier in tiers) {
      if (tier.popular) return tier;
    }
    return null;
  }();
  if (featured != null) {
    parts.add('${featured.title} öne çıkan');
    if (featured.durationDays > 0 && featured.durationDays != 30) {
      parts.add('${featured.durationLabel} plan');
    }
    if (featured.falDiscountPercent > 0) {
      parts.add('%${featured.falDiscountPercent} fal indirimi');
    }
  } else {
    parts.add('Gold, Diamond ve SVIP planlarını keşfedin');
  }
  return parts.join(' · ');
}

/// Profil hub VIP Gold kısayol alt başlığı.
String buildVipGoldShortcutSubtitle(ProfileMembershipInfo info) {
  if (info.isVip && info.hasActiveSubscription) {
    return '${info.tierLabel} · VIP odalar aktif';
  }
  if (info.isVip && info.isExpired) {
    return 'VIP erişimi için planı yenileyin';
  }
  return 'Gold ve üzeri planlarda';
}

/// Üyelik sayfası süresi dolmuş banner metni.
String buildMembershipPageExpiredBannerText({
  required ProfileMembershipInfo info,
  String? expiresAt,
}) {
  return '${buildMembershipExpiredBannerText(info: info, expiresAt: expiresAt)} · planı yenile';
}

/// Premium kart / cüzdan hub başlığı.
String buildMembershipPremiumCardTitle({
  required ProfileMembershipInfo info,
  String? expiresAt,
}) {
  if (info.isExpired) {
    return buildMembershipExpiredPlanLabel(info: info, expiresAt: expiresAt);
  }
  if (info.hasPaidTier) return '${info.tierLabel} Üyelik';
  return 'Premium Üyelik';
}

/// Profil cüzdan kartı abonelik satırı.
String buildMembershipWalletSubscriptionStatLabel({
  required ProfileMembershipInfo info,
  MembershipTierModel? catalogTier,
  int? daysRemaining,
  String? expiresAt,
}) {
  if (!info.hasPaidTier) return '—';
  if (info.isExpired) {
    return buildMembershipExpiredPlanLabel(info: info, expiresAt: expiresAt);
  }
  return formatMembershipPlanDuration(
    info: info,
    catalogTier: catalogTier,
    daysRemaining: daysRemaining,
    expiresAt: expiresAt,
  );
}

/// Profil hub / ayarlar üyelik bölüm başlığı (ör. Gold Üyelik).
String buildMembershipHubSectionTitle({
  required ProfileMembershipInfo info,
  String? expiresAt,
}) {
  if (info.isExpired) {
    return buildMembershipExpiredPlanLabel(info: info, expiresAt: expiresAt);
  }
  if (info.hasPaidTier) return '${info.tierLabel} Üyelik';
  return 'Üyelik Planları';
}

/// Görevler merkezi üyelik kartı başlığı.
String buildGrowthHubMembershipTitle({
  required ProfileMembershipInfo info,
  String? expiresAt,
}) {
  if (info.isExpired) {
    return buildMembershipExpiredPlanLabel(info: info, expiresAt: expiresAt);
  }
  if (info.hasPaidTier) return '${info.tierLabel} üyeliği';
  return 'Üyelik planları';
}

/// Hub üyelik kartı sağ CTA etiketi.
String buildMembershipHubActionLabel({
  required ProfileMembershipInfo info,
  String freeLabel = 'Planlar',
}) {
  if (info.isExpired) return 'Yenile';
  if (info.hasPaidTier) return 'Yönet';
  return freeLabel;
}

/// Üyelik tier kartı üst rozeti.
enum MembershipTierCardBadge { none, active, popular, expired }

MembershipTierCardBadge resolveMembershipTierCardBadge({
  required MembershipTierModel tier,
  required ProfileMembershipInfo info,
  List<MembershipPackageEntity> packages = const [],
}) {
  final wire = membershipWireId(info.raw);
  if (info.hasPaidTier && tier.wireId == wire) {
    if (info.hasActiveSubscription) return MembershipTierCardBadge.active;
    if (info.isExpired) return MembershipTierCardBadge.expired;
  }
  if (tier.isActivePlan) return MembershipTierCardBadge.active;
  if (tier.popular) return MembershipTierCardBadge.popular;
  final recommended = recommendedTierFromPackages(packages);
  if (recommended == tier.id && !info.hasActiveSubscription) {
    return MembershipTierCardBadge.popular;
  }
  return MembershipTierCardBadge.none;
}

/// Profil hub başlık VIP pill etiketi (null = gösterme).
String? buildMembershipHubVipPillLabel({
  required ProfileMembershipInfo info,
  String? membershipExpiresAt,
  String? extVipLevel,
  bool fallbackStateIsVip = false,
  String? levelVipTier,
}) {
  if (info.isExpired) {
    final expiry = formatMembershipExpiryLabel(membershipExpiresAt);
    return expiry != null
        ? '⏳ ${info.tierLabel} · $expiry'
        : '⏳ ${info.tierLabel} · doldu';
  }
  if (info.hasActiveSubscription) {
    final expiry = formatMembershipExpiryLabel(membershipExpiresAt);
    if ((info.daysRemaining == null || info.daysRemaining! <= 0) &&
        expiry != null) {
      return '💎 ${info.tierLabel} · $expiry';
    }
    if (info.hasPaidTier) return '💎 ${info.tierLabel}';
  }
  final v = extVipLevel?.trim();
  if (v != null && v.isNotEmpty) {
    final extInfo = resolveProfileMembership(rawMembership: v);
    if (extInfo.hasPaidTier) return '💎 ${extInfo.tierLabel}';
  }
  if (fallbackStateIsVip) return '💎 VIP';
  final levelTier = levelVipTier?.trim();
  if (levelTier != null && levelTier.isNotEmpty) {
    final levelInfo = resolveProfileMembership(rawMembership: levelTier);
    if (levelInfo.hasPaidTier) return '💎 ${levelInfo.tierLabel}';
  }
  return null;
}

/// Cüzdan merkezi / hub currency kart üyelik alt başlığı.
String buildMembershipWalletHubSubtitle({
  required ProfileMembershipInfo info,
  required List<MembershipTierModel> tiers,
  List<MembershipPackageEntity> packages = const [],
  MembershipTierModel? catalogTier,
  int? daysRemaining,
  String? expiresAt,
}) {
  if (info.hasActiveSubscription) {
    return '${info.tierLabel} · ${formatMembershipPlanDuration(
      info: info,
      catalogTier: catalogTier,
      daysRemaining: daysRemaining ?? info.daysRemaining,
      expiresAt: expiresAt,
    )}';
  }
  if (info.isExpired) {
    return buildMembershipCatalogHintSubtitle(
      info: info,
      catalogTier: catalogTier,
      expiresAt: expiresAt,
    );
  }
  return buildFreeUserMembershipTeaserSubtitle(
    tiers: tiers,
    packages: packages,
  );
}

/// Jeton / CFC mağaza üyelik teaser alt başlığı.
enum MembershipStoreKind { jeton, cfc }

String buildMembershipStoreTeaserSubtitle({
  required ProfileMembershipInfo info,
  required MembershipStoreKind store,
  required List<MembershipTierModel> tiers,
  List<MembershipPackageEntity> packages = const [],
  MembershipTierModel? catalogTier,
  String? expiresAt,
}) {
  final storeLabel = store == MembershipStoreKind.jeton ? 'jeton' : 'CFC';
  if (info.isExpired) {
    final expiry = formatMembershipExpiryLabel(expiresAt);
    if (expiry != null) {
      return '${info.tierLabel} planı $expiry tarihinde sona erdi · $storeLabel yüklemeye devam edebilirsiniz';
    }
    return '${info.tierLabel} planınız sona erdi · yenileyin veya $storeLabel yükleyin';
  }
  if (info.hasActiveSubscription) {
    final parts = <String>['${info.tierLabel} üyeliği aktif'];
    if (catalogTier != null && catalogTier.falDiscountPercent > 0) {
      parts.add('%${catalogTier.falDiscountPercent} fal indirimi');
    }
    parts.add('$storeLabel bakiyeniz plan avantajlarıyla kullanılır');
    return parts.join(' · ');
  }
  final teaser = buildFreeUserMembershipTeaserSubtitle(
    tiers: tiers,
    packages: packages,
  );
  return '$teaser · $storeLabel yüklerken üyelik planlarını inceleyin';
}

/// Ayarlar manage tile alt başlığı — cüzdan merkezi ile aynı.
String buildMembershipSettingsManageSubtitle({
  required ProfileMembershipInfo info,
  required List<MembershipTierModel> tiers,
  List<MembershipPackageEntity> packages = const [],
  MembershipTierModel? catalogTier,
  int? daysRemaining,
  String? expiresAt,
}) {
  return buildMembershipWalletHubSubtitle(
    info: info,
    tiers: tiers,
    packages: packages,
    catalogTier: catalogTier,
    daysRemaining: daysRemaining,
    expiresAt: expiresAt,
  );
}

/// Hub istatistikler — üyelik planı satır değeri.
String buildMembershipAboutStatsPlanValue({
  required ProfileMembershipInfo info,
  String? expiresAt,
}) {
  if (info.isExpired) {
    return buildMembershipExpiredPlanLabel(info: info, expiresAt: expiresAt);
  }
  if (info.hasPaidTier) return info.tierLabel;
  return 'Standart';
}

/// Hub istatistikler — plan süresi satır değeri.
String buildMembershipAboutStatsPlanDurationValue({
  required ProfileMembershipInfo info,
  MembershipTierModel? catalogTier,
  int? daysRemaining,
  String? expiresAt,
}) {
  return formatMembershipPlanDuration(
    info: info,
    catalogTier: catalogTier,
    daysRemaining: daysRemaining ?? info.daysRemaining,
    expiresAt: expiresAt,
  );
}

/// Hub istatistikler / growth hub — süresi dolmuş pill etiketi.
String? buildMembershipStatusPillLabel({
  required ProfileMembershipInfo info,
  String? expiresAt,
}) {
  if (info.isExpired) {
    return buildMembershipExpiredPlanLabel(info: info, expiresAt: expiresAt);
  }
  if (info.hasActiveSubscription && info.hasPaidTier) {
    return info.tierLabel;
  }
  return null;
}

/// Cüzdan header aktif üyelik banner metni.
String buildMembershipWalletActiveBannerText({
  required ProfileMembershipInfo info,
  MembershipTierModel? catalogTier,
  int? daysRemaining,
  String? expiresAt,
}) {
  final plan = formatMembershipPlanDuration(
    info: info,
    catalogTier: catalogTier,
    daysRemaining: daysRemaining ?? info.daysRemaining,
    expiresAt: expiresAt,
  );
  return '${info.tierLabel} üyesiniz · $plan';
}

/// Cüzdan header aktif üyelik banner gösterilsin mi?
bool shouldShowMembershipWalletActiveBanner({
  required ProfileMembershipInfo info,
  int? daysRemaining,
  String? expiresAt,
}) {
  return info.hasActiveSubscription &&
      ((daysRemaining != null && daysRemaining! > 0) ||
          (expiresAt != null && expiresAt.trim().isNotEmpty));
}

/// Hizmetler şeridi üyelik kartı kısa ipucu.
String buildMembershipHubServiceCardHint({
  required ProfileMembershipInfo info,
  required List<MembershipTierModel> tiers,
  List<MembershipPackageEntity> packages = const [],
  MembershipTierModel? catalogTier,
  String? expiresAt,
}) {
  if (info.isExpired) return 'Yenile';
  if (info.hasActiveSubscription) {
    if (catalogTier != null && catalogTier.falDiscountPercent > 0) {
      return '%${catalogTier.falDiscountPercent} fal';
    }
    return info.tierLabel;
  }
  final teaser = buildFreeUserMembershipTeaserSubtitle(
    tiers: tiers,
    packages: packages,
  );
  final first = teaser.split(' · ').first;
  return first.length > 20 ? 'Planlar' : first;
}

/// Hızlı menü üyelik kısayol etiketi.
String buildMembershipQuickMenuLabel({
  required ProfileMembershipInfo info,
}) {
  if (info.isExpired) return 'Yenile';
  if (info.hasPaidTier) return info.tierLabel;
  return 'Üyelik';
}

/// Üyelik sayfası checkout footer ipucu (seçili plan).
String buildMembershipCheckoutFooterHint({
  required ProfileMembershipInfo info,
  required MembershipTierModel selectedTier,
  String? expiresAt,
}) {
  final wire = membershipWireId(info.raw);
  if (info.hasActiveSubscription && wire == selectedTier.wireId) {
    return 'Aktif planınız · ${selectedTier.durationLabel}';
  }
  if (info.isExpired && wire == selectedTier.wireId) {
    return 'Süresi doldu · ${buildMembershipExpiredPlanLabel(
      info: info,
      expiresAt: expiresAt,
    )}';
  }
  final parts = <String>[
    selectedTier.title,
    selectedTier.durationLabel,
    if (selectedTier.falDiscountPercent > 0)
      '%${selectedTier.falDiscountPercent} fal indirimi',
  ];
  return parts.join(' · ');
}

/// Üyelik rozetleri bölümü alt başlığı.
String buildMembershipBadgesSectionSubtitle({
  required ProfileMembershipInfo info,
  required int unlockedCount,
  required int totalCount,
}) {
  if (totalCount <= 0) return '';
  final ratio = '$unlockedCount/$totalCount rozet açık';
  if (info.isExpired) {
    return '$ratio · planı yenileyin';
  }
  if (info.hasActiveSubscription && info.hasPaidTier) {
    return '$ratio · ${info.tierLabel}';
  }
  return '$ratio · plan yükseltin';
}

/// Hizmetler şeridi VIP Gold kartı kısa ipucu.
String buildMembershipHubVipGoldServiceCardHint({
  required ProfileMembershipInfo info,
}) {
  if (info.isExpired) return 'Yenile';
  if (info.isVip && info.hasActiveSubscription) return 'Aktif';
  return 'Odalar';
}

/// Cüzdan kazanç özeti üyelik teaser metni.
String buildMembershipWalletEarningsTeaser({
  required ProfileMembershipInfo info,
  MembershipTierModel? catalogTier,
  int? daysRemaining,
  String? expiresAt,
}) {
  if (info.isExpired) {
    final expiry = formatMembershipExpiryLabel(expiresAt);
    if (expiry != null) {
      return '${info.tierLabel} $expiry tarihinde sona erdi · kazanç çekimine devam edebilirsiniz';
    }
    return '${info.tierLabel} planı sona erdi · üyeliği yenileyin';
  }
  if (info.hasActiveSubscription) {
    final discount = catalogTier?.falDiscountPercent ?? 0;
    if (discount > 0) {
      return '${info.tierLabel} · %$discount fal indirimi · kazançlarınız etkilenmez';
    }
    final plan = formatMembershipPlanDuration(
      info: info,
      catalogTier: catalogTier,
      daysRemaining: daysRemaining ?? info.daysRemaining,
      expiresAt: expiresAt,
    );
    return '${info.tierLabel} üyeliği aktif · $plan';
  }
  return 'Üyelik planlarıyla fal indirimi ve ek avantajlar';
}

/// Premium kart alt başlığı — cüzdan merkezi ile aynı.
String buildMembershipPremiumCardSubtitle({
  required ProfileMembershipInfo info,
  required List<MembershipTierModel> tiers,
  List<MembershipPackageEntity> packages = const [],
  MembershipTierModel? catalogTier,
  int? daysRemaining,
  String? expiresAt,
}) {
  return buildMembershipWalletHubSubtitle(
    info: info,
    tiers: tiers,
    packages: packages,
    catalogTier: catalogTier,
    daysRemaining: daysRemaining,
    expiresAt: expiresAt,
  );
}

/// Premium kart birincil CTA etiketi.
String buildMembershipPremiumCardPrimaryActionLabel({
  required ProfileMembershipInfo info,
}) {
  if (info.hasActiveSubscription) return 'Ayrıcalıklar';
  if (info.isExpired) return 'Yenile';
  return 'Planları Gör';
}

/// Ücretsiz kullanıcı VIP banner başlığı.
String buildMembershipVipBannerTitle({
  required ProfileMembershipInfo info,
  String? expiresAt,
}) {
  return buildMembershipHubSectionTitle(info: info, expiresAt: expiresAt);
}

/// Ücretsiz kullanıcı VIP banner CTA etiketi.
String buildMembershipVipBannerActionLabel({
  required ProfileMembershipInfo info,
}) {
  return '${buildMembershipHubActionLabel(
    info: info,
    freeLabel: 'Planları Gör',
  )} >';
}

/// Cüzdan header üyelik hızlı link etiketi.
String buildMembershipWalletQuickLinkLabel({
  required ProfileMembershipInfo info,
}) {
  if (info.isExpired) return 'Yenile';
  if (info.hasPaidTier) return info.tierLabel;
  return 'Üyelik';
}

/// Profil cüzdan kartı premium mini stat etiketi.
String buildMembershipWalletPremiumStatLabel({
  required ProfileMembershipInfo info,
}) {
  if (info.hasPaidTier) return info.tierLabel;
  return 'Standart';
}

/// Profil cüzdan kartı abonelik aksiyon karo etiketi.
String buildMembershipWalletSubscriptionsTileLabel({
  required ProfileMembershipInfo info,
}) {
  if (info.isExpired) return 'Yenile';
  if (info.hasPaidTier) return 'Abonelikler';
  return 'Planlar';
}

/// Hub üyelik kısayol plan chip ana etiketi.
String buildMembershipShortcutsPlanChipLabel({
  required ProfileMembershipInfo info,
}) {
  if (info.hasPaidTier) return 'Planı Yönet';
  return 'Planlar';
}

/// Jeton/CFC mağaza teaser banner başlığı.
String buildMembershipStoreTeaserBannerTitle({
  required ProfileMembershipInfo info,
  String? expiresAt,
}) {
  if (info.isExpired) {
    return buildMembershipExpiredPlanLabel(info: info, expiresAt: expiresAt);
  }
  return buildMembershipHubSectionTitle(info: info, expiresAt: expiresAt);
}

/// Cüzdan merkezi sayfa alt başlığı.
String buildMembershipWalletCenterPageSubtitle({
  required ProfileMembershipInfo info,
}) {
  if (info.isExpired) return 'Jeton · CFC · Planı yenile';
  if (info.hasActiveSubscription) {
    return 'Jeton · CFC · ${info.tierLabel} üyelik';
  }
  return 'Jeton · CFC · Premium üyelik';
}

/// Premium kart ikincil yönet CTA etiketi.
String buildMembershipPremiumCardManageActionLabel({
  required ProfileMembershipInfo info,
}) {
  if (info.isExpired) return 'Yönet';
  return buildMembershipHubActionLabel(info: info, freeLabel: 'Yönet');
}

/// Hub istatistikler bölümü alt başlığı.
String buildMembershipAboutStatsSectionSubtitle({
  required ProfileMembershipInfo info,
  MembershipTierModel? catalogTier,
  int? daysRemaining,
  String? expiresAt,
}) {
  if (info.isExpired) {
    return '${buildMembershipExpiredPlanLabel(info: info, expiresAt: expiresAt)} · yenileyin';
  }
  if (info.hasActiveSubscription) {
    return '${info.tierLabel} · ${formatMembershipPlanDuration(
      info: info,
      catalogTier: catalogTier,
      daysRemaining: daysRemaining ?? info.daysRemaining,
      expiresAt: expiresAt,
    )}';
  }
  return 'Üyelik planını yükseltin';
}

/// Para çekme sayfası alt başlığı.
String buildMembershipWithdrawalPageSubtitle({
  required ProfileMembershipInfo info,
}) {
  if (info.isExpired) return 'Banka havalesi · üyeliği yenileyin';
  if (info.hasActiveSubscription) {
    return 'Banka havalesi · ${info.tierLabel} üyelik aktif';
  }
  return 'Banka havalesi ile çekim talebi';
}

/// Cüzdan merkezi jeton/CFC hub kart alt başlığı.
String buildMembershipWalletStoreHubCardSubtitle({
  required ProfileMembershipInfo info,
  required MembershipStoreKind store,
  MembershipTierModel? catalogTier,
}) {
  final storeLabel = store == MembershipStoreKind.jeton ? 'jeton' : 'CFC';
  if (info.isExpired) return 'Paketler · planı yenileyin';
  if (info.hasActiveSubscription) {
    final discount = catalogTier?.falDiscountPercent ?? 0;
    if (discount > 0) {
      return 'Paketler · %$discount fal avantajı';
    }
    return 'Paketler · ${info.tierLabel} üyelik';
  }
  return store == MembershipStoreKind.jeton
      ? 'Paketler ve $storeLabel bakiyesi'
      : 'Paketler ve $storeLabel bakiyesi';
}

/// Hub VIP Gold kısayol chip ana etiketi.
String buildMembershipShortcutsVipChipLabel({
  required ProfileMembershipInfo info,
}) {
  if (info.isExpired && info.hasPaidTier) return 'VIP Yenile';
  return 'VIP Gold';
}

/// Üyelik sayfası aktif plan banner metni.
String buildMembershipPageActiveBannerText({
  required ProfileMembershipInfo info,
  MembershipTierModel? catalogTier,
  int? daysRemaining,
  String? expiresAt,
}) {
  final duration = formatMembershipPlanDuration(
    info: info,
    catalogTier: catalogTier,
    daysRemaining: daysRemaining ?? info.daysRemaining,
    expiresAt: expiresAt,
  );
  return '${info.tierLabel} üyeliğiniz aktif · $duration';
}

/// Ayarlar / yönet tile sol ikon vurgusu.
enum MembershipManageTileLeadingAccent { standard, paid, expired }

MembershipManageTileLeadingAccent resolveMembershipManageTileLeadingAccent({
  required ProfileMembershipInfo info,
}) {
  if (info.isExpired) return MembershipManageTileLeadingAccent.expired;
  if (info.hasPaidTier) return MembershipManageTileLeadingAccent.paid;
  return MembershipManageTileLeadingAccent.standard;
}

/// Profil cüzdan bölümü bakiye açıklaması.
String buildMembershipWalletSectionBalanceHint({
  required ProfileMembershipInfo info,
}) {
  if (info.isExpired) {
    return 'Jeton · CFC bakiyeleri · planı yenileyin';
  }
  if (info.hasActiveSubscription) {
    return 'Jeton: yayın ve hediye · CFC: oyun ve fal · ${info.tierLabel} avantajları';
  }
  return 'Jeton: canlı yayın, sohbet ve hediye · CFC: oyun ve fal';
}

/// Üyelik sayfası yükseltme banner başlığı.
String buildMembershipPageUpgradeBannerTitle({
  required ProfileMembershipInfo info,
}) {
  if (info.hasActiveSubscription) {
    return 'Planını Yükselt, Avantajları Katla!';
  }
  return 'Üyeliğini Yükselt, Avantajları Katla!';
}

/// Üyelik sayfası yükseltme banner alt metni.
String buildMembershipPageUpgradeBannerSubtitle({
  required ProfileMembershipInfo info,
  MembershipTierModel? catalogTier,
}) {
  if (info.isExpired) {
    return 'Planı yenileyin; jeton, fal indirimi ve VIP ayrıcalıkları geri gelsin.';
  }
  if (info.hasActiveSubscription) {
    final discount = catalogTier?.falDiscountPercent ?? 0;
    if (discount > 0) {
      return 'Üst planlarda ek jeton, %$discount+ fal indirimi ve VIP odalar.';
    }
    return 'Daha üst planlarda ek jeton, fal indirimi ve VIP ayrıcalıkları.';
  }
  return 'Daha fazla jeton, daha fazla ayrıcalık ve özel içerikler seni bekliyor.';
}

/// Üyelik sayfası yükseltme banner CTA etiketi.
String buildMembershipPageUpgradeBannerActionLabel() => 'Jeton\nSatın Al';
