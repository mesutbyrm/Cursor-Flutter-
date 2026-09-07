import 'package:equatable/equatable.dart';

import '../../util/json_util.dart';

/// Yükleme bonus kademesi — backend hesaplar; mobil bilgilendirme amaçlı.
class TopupBonusTier extends Equatable {
  const TopupBonusTier({
    required this.minAmount,
    required this.bonusPercent,
    this.label,
    this.currency = 'all',
    this.sourceType = 'all',
    this.maxBonus = 0,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory TopupBonusTier.fromJson(Map<String, dynamic> json) {
    return TopupBonusTier(
      label: pick(json, ['label'])?.toString(),
      minAmount: asInt(pick(json, ['minAmount'])),
      bonusPercent: (pick(json, ['bonusPercent']) as num?)?.toDouble() ?? 0,
      currency: pick(json, ['currency'])?.toString() ?? 'all',
      sourceType: pick(json, ['sourceType'])?.toString() ?? 'all',
      maxBonus: asInt(pick(json, ['maxBonus'])),
      isActive: json['isActive'] != false,
      sortOrder: asInt(pick(json, ['sortOrder'])),
    );
  }

  /// ZIP varsayılan kademeler — endpoint yoksa bilgilendirme için.
  static const defaultTiers = <TopupBonusTier>[
    TopupBonusTier(
      label: '10.000 ve üzeri',
      minAmount: 10000,
      bonusPercent: 5,
      sortOrder: 1,
    ),
    TopupBonusTier(
      label: '25.000 ve üzeri',
      minAmount: 25000,
      bonusPercent: 7,
      sortOrder: 2,
    ),
    TopupBonusTier(
      label: '50.000 ve üzeri',
      minAmount: 50000,
      bonusPercent: 10,
      sortOrder: 3,
    ),
  ];

  final String? label;
  final int minAmount;
  final double bonusPercent;
  final String currency;
  final String sourceType;
  final int maxBonus;
  final bool isActive;
  final int sortOrder;

  String get displayLabel =>
      label?.trim().isNotEmpty == true ? label!.trim() : '$minAmount+';

  @override
  List<Object?> get props =>
      [label, minAmount, bonusPercent, currency, sourceType, maxBonus, isActive, sortOrder];
}
