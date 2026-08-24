import 'package:equatable/equatable.dart';

import '../../../core/util/json_util.dart';

/// Para çekme talebi — `GET/POST /api/withdrawals`.
class WithdrawalRequest extends Equatable {
  const WithdrawalRequest({
    required this.id,
    required this.amount,
    required this.status,
    this.method,
    this.details,
    this.createdAt,
    this.updatedAt,
    this.rejectionReason,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    final detailsRaw = pick(json, ['details', 'bankDetails', 'bank_details']);
    Map<String, dynamic>? details;
    if (detailsRaw is Map) {
      details = Map<String, dynamic>.from(detailsRaw);
    }
    return WithdrawalRequest(
      id: pick(json, ['id', '_id'])?.toString() ?? '',
      amount: asNum(pick(json, ['amount', 'withdrawAmount', 'tlAmount'])),
      status: (pick(json, ['status', 'state']) ?? 'pending').toString(),
      method: pick(json, ['method', 'paymentMethod'])?.toString(),
      details: details,
      createdAt: pick(json, ['createdAt', 'created_at'])?.toString(),
      updatedAt: pick(json, ['updatedAt', 'updated_at'])?.toString(),
      rejectionReason:
          pick(json, ['rejectionReason', 'rejectReason', 'note'])?.toString(),
    );
  }

  final String id;
  final double amount;
  final String status;
  final String? method;
  final Map<String, dynamic>? details;
  final String? createdAt;
  final String? updatedAt;
  final String? rejectionReason;

  String get statusLabel => switch (status.toLowerCase()) {
        'pending' || 'beklemede' => 'Beklemede',
        'approved' || 'onaylandi' || 'onaylandı' => 'Onaylandı',
        'rejected' || 'reddedildi' => 'Reddedildi',
        'paid' || 'odendi' || 'ödendi' => 'Ödendi',
        _ => status,
      };

  @override
  List<Object?> get props =>
      [id, amount, status, method, details, createdAt, updatedAt];
}

double asNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
