import '../../../../core/util/json_util.dart';

/// Kullanıcının ödeme bildirimi — `GET /api/payments/notify` (sunucu
/// `decoratePaymentNotification` ile etiketleri hazırlar).
class PaymentNotificationEntity {
  const PaymentNotificationEntity({
    required this.id,
    required this.status,
    required this.statusLabel,
    required this.productLabel,
    required this.amount,
    this.paymentMethodLabel,
    this.requestedSummary,
    this.loadedSummary,
    this.adminMessage,
    this.createdAt,
    this.canDispute = false,
    this.disputeTicketId,
    this.disputeStatus,
  });

  final String id;
  final String status;
  final String statusLabel;
  final String productLabel;
  final double amount;
  final String? paymentMethodLabel;
  final String? requestedSummary;
  final String? loadedSummary;
  final String? adminMessage;
  final DateTime? createdAt;
  final bool canDispute;
  final String? disputeTicketId;
  final String? disputeStatus;

  bool get hasDispute => (disputeTicketId ?? '').isNotEmpty;

  static List<PaymentNotificationEntity> listFromResponse(dynamic body) {
    final raw = body is List
        ? body
        : asJsonList(asJsonMap(body)['notifications'] ?? asJsonMap(body)['data']);
    return raw
        .map((e) => PaymentNotificationEntity.fromJson(asJsonMap(e)))
        .where((e) => e.id.isNotEmpty)
        .toList(growable: false);
  }

  factory PaymentNotificationEntity.fromJson(Map<String, dynamic> json) {
    String? str(String k) {
      final v = json[k]?.toString().trim();
      return (v == null || v.isEmpty) ? null : v;
    }

    final status = str('status') ?? 'pending';
    return PaymentNotificationEntity(
      id: str('id') ?? '',
      status: status,
      statusLabel: str('statusLabel') ?? status,
      productLabel: str('productLabel') ?? str('productType') ?? 'Jeton',
      amount: double.tryParse('${json['amount'] ?? 0}') ?? 0,
      paymentMethodLabel: str('paymentMethodLabel') ?? str('paymentMethod'),
      requestedSummary: str('requestedSummary'),
      loadedSummary: str('loadedSummary'),
      adminMessage: str('adminMessage') ?? str('adminNote'),
      createdAt: DateTime.tryParse(str('createdAt') ?? ''),
      canDispute: json['canDispute'] == true,
      disputeTicketId: str('disputeTicketId'),
      disputeStatus: str('disputeStatus'),
    );
  }
}
