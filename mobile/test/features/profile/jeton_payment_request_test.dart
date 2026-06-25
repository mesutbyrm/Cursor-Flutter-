import 'package:flutter_test/flutter_test.dart';
import 'package:canlifal_social/features/profile/data/jeton_payment_request.dart';
import 'package:canlifal_social/features/profile/data/jeton_packages_catalog.dart';
import 'package:canlifal_social/features/profile/domain/entities/jeton_package_entity.dart';

void main() {
  test('buildCustomJetonPaymentRequest sends jeton fields and amount', () {
    final body = buildCustomJetonPaymentRequest(
      coins: 500,
      priceTry: 250,
      method: 'papara',
      userId: 'user-abc',
      username: 'İlham Perisi',
      packageId: 'p500',
    );
    expect(body['coins'], 500);
    expect(body['amount'], 500);
    expect(body['priceTry'], 250);
    expect(body['requestType'], 'jeton');
    expect(body['type'], 'jeton');
    expect(body['packageId'], 'p500');
    expect(body['notes'], contains('İlham Perisi'));
    expect(body['notes'], isNot(contains('CANLIFAL')));
  });

  test('resolveJetonPackageForPurchase maps preset coins to catalog id', () {
    final pkg = resolveJetonPackageForPurchase(coins: 500, priceTry: 250);
    expect(pkg.id, 'p500');
    expect(pkg.coins, 500);
  });

  test('buildJetonPaymentRequest includes amount for API compatibility', () {
    final body = buildJetonPaymentRequest(
      package: const JetonPackageEntity(
        id: 'p100',
        title: '100 Jeton',
        coins: 100,
        priceTry: 50,
      ),
      method: 'bank_transfer',
      senderLabel: 'Admin',
    );
    expect(body['amount'], 100);
    expect(body['coins'], 100);
    expect(body['requestType'], 'jeton');
  });
}
