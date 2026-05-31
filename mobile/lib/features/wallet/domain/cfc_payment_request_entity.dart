import '../../../core/util/json_util.dart';

class CfcPaymentRequestEntity {
  const CfcPaymentRequestEntity({
    required this.id,
    required this.amount,
    required this.method,
    required this.status,
    this.requestType = 'cfc',
    this.coins,
    this.packageTitle,
    this.senderInfo,
    this.notes,
    this.reviewNote,
    this.createdAt,
  });

  factory CfcPaymentRequestEntity.fromJson(Map<String, dynamic> json) {
    final type =
        pick(json, ['requestType', 'type'])?.toString().toLowerCase() ?? 'cfc';
    return CfcPaymentRequestEntity(
      id: json['id']?.toString() ?? '',
      amount: asInt(json['amount']),
      method: json['method']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      requestType: type,
      coins: asInt(pick(json, ['coins'])),
      packageTitle: pick(json, ['packageTitle'])?.toString(),
      senderInfo: json['senderInfo']?.toString(),
      notes: json['notes']?.toString(),
      reviewNote: json['reviewNote']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }

  final String id;
  final int amount;
  final String method;
  final String status;
  final String requestType;
  final int? coins;
  final String? packageTitle;
  final String? senderInfo;
  final String? notes;
  final String? reviewNote;
  final String? createdAt;

  bool get isCfc => requestType != 'jeton';

  bool get isJeton => requestType == 'jeton';

  String get displayLine {
    if (isJeton) {
      final c = coins ?? amount;
      final title = packageTitle ?? '$c Jeton';
      return '$title · ${_methodTr(method)}';
    }
    return '$amount CFC · ${_methodTr(method)}';
  }

  static String _methodTr(String m) => switch (m) {
        'whatsapp' => 'WhatsApp',
        'papara' => 'Papara',
        'bank_transfer' => 'Havale/EFT',
        'havale' => 'Havale/EFT',
        _ => m,
      };
}
