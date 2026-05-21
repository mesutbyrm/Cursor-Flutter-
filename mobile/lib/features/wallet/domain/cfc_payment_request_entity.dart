import '../../../core/util/json_util.dart';

class CfcPaymentRequestEntity {
  const CfcPaymentRequestEntity({
    required this.id,
    required this.amount,
    required this.method,
    required this.status,
    this.senderInfo,
    this.notes,
    this.reviewNote,
    this.createdAt,
  });

  factory CfcPaymentRequestEntity.fromJson(Map<String, dynamic> json) {
    return CfcPaymentRequestEntity(
      id: json['id']?.toString() ?? '',
      amount: asInt(json['amount']),
      method: json['method']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
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
  final String? senderInfo;
  final String? notes;
  final String? reviewNote;
  final String? createdAt;
}
