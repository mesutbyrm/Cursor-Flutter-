import 'package:flutter/material.dart';

/// Üyelik kademesi — UI kartları ve tablo için tek kaynak.
enum MembershipTierId { basic, gold, premium, diamond, svip }

class MembershipTierModel {
  const MembershipTierModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.monthlyTokens,
    required this.monthlyPriceTry,
    required this.accent,
    required this.badgeIcon,
    required this.glow,
    this.popular = false,
    this.isActivePlan = false,
    this.durationDays = 30,
    this.falDiscountPercent = 0,
    this.planId,
  });

  final MembershipTierId id;
  final String title;
  final String subtitle;
  final int monthlyTokens;
  final int monthlyPriceTry;
  final Color accent;
  final IconData badgeIcon;
  final Color glow;
  final bool popular;
  final bool isActivePlan;
  final int durationDays;
  final int falDiscountPercent;

  /// Backend plan kimliği (API varsa); yoksa [id.name].
  final String? planId;

  String get wireId => id.name;

  String get resolvedPlanId =>
      (planId != null && planId!.trim().isNotEmpty) ? planId! : wireId;

  String get durationLabel => '$durationDays gün';
}

/// Özellik tablosu hücresi.
sealed class MembershipFeatureValue {
  const MembershipFeatureValue();
}

class MembershipFeatureText extends MembershipFeatureValue {
  const MembershipFeatureText(this.text);
  final String text;
}

class MembershipFeatureBool extends MembershipFeatureValue {
  const MembershipFeatureBool(this.enabled);
  final bool enabled;
}

class MembershipFeatureRow {
  const MembershipFeatureRow({
    required this.label,
    required this.values,
  });

  final String label;

  /// Sıra: Basic, Gold, Premium, Diamond, SVIP
  final List<MembershipFeatureValue> values;
}

class MembershipTokenPackageModel {
  const MembershipTokenPackageModel({
    required this.tierId,
    required this.title,
    required this.tokens,
    required this.priceTry,
    this.oldPriceTry,
    this.discountLabel,
    this.savingsTry,
  });

  final MembershipTierId tierId;
  final String title;
  final int tokens;
  final int priceTry;
  final int? oldPriceTry;
  final String? discountLabel;
  final int? savingsTry;

  bool get hasDiscount =>
      (discountLabel != null && discountLabel!.isNotEmpty) ||
      (oldPriceTry != null && oldPriceTry! > priceTry);
}

class MembershipCommonBenefit {
  const MembershipCommonBenefit({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

/// Sabit katalog — kullanıcı fiyatları (indirim yok).
abstract final class MembershipCatalogData {
  static const bg = Color(0xFF09090F);
  static const purple = Color(0xFF8B5CF6);
  static const purpleDeep = Color(0xFF5B21B6);
  static const gold = Color(0xFFFFD54F);
  static const blue = Color(0xFF60A5FA);
  static const glass = Color(0x14FFFFFF);
  static const glassBorder = Color(0x28FFFFFF);

  static const List<MembershipTierModel> tiers = [
    MembershipTierModel(
      id: MembershipTierId.basic,
      title: 'Basic',
      subtitle: 'Başlangıç ayrıcalıkları',
      monthlyTokens: 250,
      monthlyPriceTry: 500,
      accent: Color(0xFF94A3B8),
      badgeIcon: Icons.military_tech_rounded,
      glow: Color(0xFF64748B),
    ),
    MembershipTierModel(
      id: MembershipTierId.gold,
      title: 'Gold',
      subtitle: 'En popüler seçim',
      monthlyTokens: 1500,
      monthlyPriceTry: 1000,
      accent: gold,
      badgeIcon: Icons.workspace_premium_rounded,
      glow: Color(0xFFFFC107),
      popular: true,
    ),
    MembershipTierModel(
      id: MembershipTierId.premium,
      title: 'Premium',
      subtitle: 'Gelişmiş VIP deneyim',
      monthlyTokens: 3500,
      monthlyPriceTry: 1500,
      accent: Color(0xFFA78BFA),
      badgeIcon: Icons.auto_awesome_rounded,
      glow: purple,
    ),
    MembershipTierModel(
      id: MembershipTierId.diamond,
      title: 'Diamond',
      subtitle: 'Maksimum ayrıcalık',
      monthlyTokens: 7500,
      monthlyPriceTry: 2500,
      accent: blue,
      badgeIcon: Icons.diamond_rounded,
      glow: Color(0xFF38BDF8),
    ),
    MembershipTierModel(
      id: MembershipTierId.svip,
      title: 'SVIP',
      subtitle: 'En üst düzey VIP',
      monthlyTokens: 10000,
      monthlyPriceTry: 3500,
      accent: Color(0xFFFF2D7A),
      badgeIcon: Icons.diamond_rounded,
      glow: Color(0xFFB832FF),
    ),
  ];

  /// Jeton alımında indirim yok — tüm kademelerde.
  static const List<MembershipFeatureRow> featureRows = [
    MembershipFeatureRow(
      label: 'Aylık Jeton',
      values: [
        MembershipFeatureText('250'),
        MembershipFeatureText('1500'),
        MembershipFeatureText('3500'),
        MembershipFeatureText('7500'),
        MembershipFeatureText('10000'),
      ],
    ),
    MembershipFeatureRow(
      label: 'Özel Rozet',
      values: [
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
      ],
    ),
    MembershipFeatureRow(
      label: 'Jeton Alımında İndirim',
      values: [
        MembershipFeatureText('Yok'),
        MembershipFeatureText('Yok'),
        MembershipFeatureText('Yok'),
        MembershipFeatureText('Yok'),
        MembershipFeatureText('Yok'),
      ],
    ),
    MembershipFeatureRow(
      label: 'Reklamsız Deneyim',
      values: [
        MembershipFeatureBool(false),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
      ],
    ),
    MembershipFeatureRow(
      label: 'Özel Profil Çerçevesi',
      values: [
        MembershipFeatureBool(false),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
      ],
    ),
    MembershipFeatureRow(
      label: 'Özel Sohbet Balonları',
      values: [
        MembershipFeatureBool(false),
        MembershipFeatureBool(false),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
      ],
    ),
    MembershipFeatureRow(
      label: 'Öncelikli Destek',
      values: [
        MembershipFeatureBool(false),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
      ],
    ),
    MembershipFeatureRow(
      label: 'Özel Hediyeler',
      values: [
        MembershipFeatureBool(false),
        MembershipFeatureBool(false),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
      ],
    ),
    MembershipFeatureRow(
      label: 'Canlı Yayında Öncelik',
      values: [
        MembershipFeatureBool(false),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
      ],
    ),
    MembershipFeatureRow(
      label: 'Sesli Odalarda Öncelik',
      values: [
        MembershipFeatureBool(false),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
      ],
    ),
    MembershipFeatureRow(
      label: 'PK Savaşlarında Avantaj',
      values: [
        MembershipFeatureBool(false),
        MembershipFeatureBool(false),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
      ],
    ),
    MembershipFeatureRow(
      label: 'Gönderi Görünürlüğü',
      values: [
        MembershipFeatureBool(false),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
      ],
    ),
    MembershipFeatureRow(
      label: 'Aylık Özel Etkinlik',
      values: [
        MembershipFeatureBool(false),
        MembershipFeatureBool(false),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
      ],
    ),
    MembershipFeatureRow(
      label: 'Özel İsim Rengi',
      values: [
        MembershipFeatureBool(false),
        MembershipFeatureBool(false),
        MembershipFeatureBool(false),
        MembershipFeatureBool(true),
        MembershipFeatureBool(true),
      ],
    ),
    MembershipFeatureRow(
      label: 'SVIP Giriş Efekti',
      values: [
        MembershipFeatureBool(false),
        MembershipFeatureBool(false),
        MembershipFeatureBool(false),
        MembershipFeatureBool(false),
        MembershipFeatureBool(true),
      ],
    ),
  ];

  /// Üyelik jeton paketleri — indirim etiketi yok (kullanıcı kuralı).
  static List<MembershipTokenPackageModel> get tokenPackages => [
        for (final t in tiers)
          MembershipTokenPackageModel(
            tierId: t.id,
            title: t.title,
            tokens: t.monthlyTokens,
            priceTry: t.monthlyPriceTry,
          ),
      ];

  static const commonBenefits = [
    MembershipCommonBenefit(
      icon: Icons.verified_user_rounded,
      label: 'Güvenli ödeme',
    ),
    MembershipCommonBenefit(
      icon: Icons.cancel_schedule_send_rounded,
      label: 'Dilediğin zaman iptal',
    ),
    MembershipCommonBenefit(
      icon: Icons.bolt_rounded,
      label: 'Anında aktifleşme',
    ),
    MembershipCommonBenefit(
      icon: Icons.lock_rounded,
      label: '%100 güvenli',
    ),
  ];

  static MembershipTierModel tierById(MembershipTierId id) =>
      tiers.firstWhere((t) => t.id == id);
}
