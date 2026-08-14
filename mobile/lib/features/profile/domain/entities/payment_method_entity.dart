import '../../../../core/util/json_util.dart';

/// `GET /api/payments/methods` — ödeme kanalı.
class PaymentMethodEntity {
  const PaymentMethodEntity({
    required this.id,
    required this.label,
    this.enabled = true,
    this.recommended = false,
  });

  factory PaymentMethodEntity.fromJson(Map<String, dynamic> json) {
    final id = (pick(json, ['id', 'key', 'method', 'slug', 'code']) ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final label = (pick(json, ['name', 'label', 'title', 'displayName']) ?? id)
        .toString()
        .trim();
    return PaymentMethodEntity(
      id: id.isEmpty ? 'whatsapp' : id,
      label: label.isEmpty ? id : label,
      enabled: json['enabled'] != false && json['isActive'] != false,
      recommended: json['recommended'] == true || json['isDefault'] == true,
    );
  }

  final String id;
  final String label;
  final bool enabled;
  final bool recommended;

  static const defaults = <PaymentMethodEntity>[
    PaymentMethodEntity(
      id: 'whatsapp',
      label: 'WhatsApp',
      recommended: true,
    ),
    PaymentMethodEntity(id: 'papara', label: 'Papara'),
    PaymentMethodEntity(id: 'bank_transfer', label: 'Havale / IBAN'),
  ];

  static List<PaymentMethodEntity> parseList(dynamic data) {
    if (data is! List) return defaults;
    final parsed = data
        .whereType<Map>()
        .map((e) => PaymentMethodEntity.fromJson(asJsonMap(e)))
        .where((m) => m.id.isNotEmpty)
        .toList();
    return parsed.isEmpty ? defaults : parsed;
  }

  /// CFC / jeton checkout — bilinen kanal kimliği.
  static String normalizeCheckoutMethodId(String id) {
    return switch (id.toLowerCase().trim()) {
      'bank' || 'havale' || 'iban' => 'bank_transfer',
      _ => id.toLowerCase().trim(),
    };
  }

  static bool isKnownCheckoutMethod(String id) {
    final k = normalizeCheckoutMethodId(id);
    return k == 'whatsapp' || k == 'papara' || k == 'bank_transfer';
  }
}
