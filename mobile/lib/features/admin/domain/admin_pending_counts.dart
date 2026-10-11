import '../../../core/util/json_util.dart';

/// `GET /api/admin/pending-counts`
class AdminPendingCounts {
  const AdminPendingCounts({
    this.pendingPayments = 0,
    this.cfcPaymentRequests = 0,
    this.pendingWithdrawals = 0,
    this.pendingTellerApplications = 0,
    this.pendingAgencyApplications = 0,
    this.pendingVerifications = 0,
    this.pendingReports = 0,
  });

  final int pendingPayments;
  final int cfcPaymentRequests;
  final int pendingWithdrawals;
  final int pendingTellerApplications;
  final int pendingAgencyApplications;
  final int pendingVerifications;
  final int pendingReports;

  int get totalActionable =>
      pendingPayments +
      cfcPaymentRequests +
      pendingWithdrawals +
      pendingReports;

  factory AdminPendingCounts.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? asJsonMap(json['data'])
        : asJsonMap(json);
    int i(String key) => (data[key] as num?)?.toInt() ?? 0;
    return AdminPendingCounts(
      pendingPayments: i('pendingPayments'),
      cfcPaymentRequests: i('cfcPaymentRequests'),
      pendingWithdrawals: i('pendingWithdrawals'),
      pendingTellerApplications: i('pendingTellerApplications'),
      pendingAgencyApplications: i('pendingAgencyApplications'),
      pendingVerifications: i('pendingVerifications'),
      pendingReports: i('pendingReports'),
    );
  }
}
