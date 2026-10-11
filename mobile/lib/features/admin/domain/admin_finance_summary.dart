import '../../../core/util/json_util.dart';

class AdminFinanceSummary {
  const AdminFinanceSummary({
    this.period = 'monthly',
    this.revenueTotalTl = 0,
    this.revenueTransactionCount = 0,
    this.giftsTotal = 0,
    this.withdrawalsTotalTl = 0,
    this.netRevenueTl = 0,
  });

  final String period;
  final double revenueTotalTl;
  final int revenueTransactionCount;
  final int giftsTotal;
  final double withdrawalsTotalTl;
  final double netRevenueTl;

  factory AdminFinanceSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? asJsonMap(json['data'])
        : asJsonMap(json);
    final revenue = data['revenue'] is Map ? asJsonMap(data['revenue']) : {};
    final spending = data['spending'] is Map ? asJsonMap(data['spending']) : {};
    final gifts = spending['gifts'] is Map ? asJsonMap(spending['gifts']) : {};
    final withdrawals =
        data['withdrawals'] is Map ? asJsonMap(data['withdrawals']) : {};
    final net = data['net'] is Map ? asJsonMap(data['net']) : {};
    return AdminFinanceSummary(
      period: data['period']?.toString() ?? 'monthly',
      revenueTotalTl: (revenue['totalTL'] as num?)?.toDouble() ?? 0,
      revenueTransactionCount: (revenue['transactionCount'] as num?)?.toInt() ?? 0,
      giftsTotal: (gifts['total'] as num?)?.toInt() ?? 0,
      withdrawalsTotalTl: (withdrawals['totalTL'] as num?)?.toDouble() ?? 0,
      netRevenueTl: (net['revenueTL'] as num?)?.toDouble() ?? 0,
    );
  }
}
