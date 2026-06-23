import 'package:flutter_test/flutter_test.dart';
import 'package:canlifal_social/features/profile/data/jeton_payment_request.dart';

void main() {
  test('buildCustomJetonPaymentRequest includes CANLIFAL ref and amounts', () {
    final body = buildCustomJetonPaymentRequest(
      coins: 500,
      priceTry: 250,
      method: 'papara',
      userId: 'user-abc',
      username: 'ilhamperisi',
      paymentReference: 'CANLIFAL-user-abc',
    );
    expect(body['coins'], 500);
    expect(body['priceTry'], 250);
    expect(body['method'], 'papara');
    expect(body['notes'], contains('CANLIFAL-user-abc'));
    expect(body['notes'], contains('500 jeton'));
  });
}
