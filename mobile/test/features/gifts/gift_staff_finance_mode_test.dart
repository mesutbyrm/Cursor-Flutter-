import 'package:canlifal_social/features/gifts/domain/gift_staff_finance_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('financeMode request fields', () {
    expect(
      GiftStaffFinanceMode.staff.toRequestFields(),
      {'financeMode': 'staff'},
    );
    expect(
      GiftStaffFinanceMode.real.toRequestFields(),
      {'financeMode': 'real'},
    );
  });
}
