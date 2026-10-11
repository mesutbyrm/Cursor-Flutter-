import 'package:canlifal_social/features/admin/domain/admin_complaint.dart';
import 'package:canlifal_social/features/admin/domain/admin_finance_summary.dart';
import 'package:canlifal_social/features/admin/domain/admin_pending_counts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AdminPendingCounts parses data envelope', () {
    final c = AdminPendingCounts.fromJson({
      'success': true,
      'data': {'pendingReports': 7, 'pendingPayments': 2},
    });
    expect(c.pendingReports, 7);
    expect(c.pendingPayments, 2);
  });

  test('AdminFinanceSummary parses revenue and net', () {
    final s = AdminFinanceSummary.fromJson({
      'data': {
        'period': 'monthly',
        'revenue': {'totalTL': 1000, 'transactionCount': 5},
        'spending': {'gifts': {'total': 200}},
        'withdrawals': {'totalTL': 100},
        'net': {'revenueTL': 900},
      },
    });
    expect(s.revenueTotalTl, 1000);
    expect(s.netRevenueTl, 900);
    expect(s.giftsTotal, 200);
  });

  test('AdminComplaint parses reporter block', () {
    final r = AdminComplaint.fromJson({
      'id': 'r1',
      'reason': 'Spam',
      'status': 'pending',
      'reporter': {'id': 'u1', 'username': 'ali'},
    });
    expect(r.id, 'r1');
    expect(r.reporter?.username, 'ali');
  });
}
