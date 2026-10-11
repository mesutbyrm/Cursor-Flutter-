import 'package:canlifal_social/features/agency/domain/entities/agency_management_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AgencyPeriodView.fromJson parses period summary', () {
    final p = AgencyPeriodView.fromJson({
      'period': '2026-09',
      'memberCount': 12,
      'totalJeton': 4500,
      'status': 'closed',
    });
    expect(p.period, '2026-09');
    expect(p.memberCount, 12);
    expect(p.totalJeton, 4500);
    expect(p.status, 'closed');
  });
}
