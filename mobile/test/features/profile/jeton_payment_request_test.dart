import 'package:flutter_test/flutter_test.dart';
import 'package:canlifal_social/features/profile/data/jeton_payment_request.dart';
import 'package:canlifal_social/features/profile/data/jeton_packages_catalog.dart';
import 'package:canlifal_social/features/profile/domain/entities/jeton_package_entity.dart';

void main() {
  test('buildCustomJetonPaymentRequest sends jeton amount matching coins', () {
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

  test('resolveJetonPackageForPurchase maps remote catalog id', () {
    const remote = [
      JetonPackageEntity(
        id: 'api-p500',
        title: '500 Jeton',
        coins: 500,
        priceTry: 250,
      ),
    ];
    final pkg = resolveJetonPackageForPurchase(
      coins: 500,
      priceTry: 250,
      remote: remote,
    );
    expect(pkg.id, 'api-p500');
    expect(pkg.coins, 500);
  });

  test('normalizePaymentRequestBody keeps jeton coins and packageId', () {
    final body = normalizePaymentRequestBody({
      'requestType': 'jeton',
      'type': 'jeton',
      'method': 'papara',
      'packageId': 'p100',
      'coins': 100,
      'amount': 100,
    });
    expect(body['requestType'], 'jeton');
    expect(body['coins'], 100);
    expect(body['amount'], 100);
    expect(body['packageId'], 'p100');
    expect(body.containsKey('priceTry'), isFalse);
  });

  test('normalizePaymentRequestBody CFC strips coins', () {
    final body = normalizePaymentRequestBody({
      'requestType': 'cfc',
      'type': 'cfc',
      'method': 'bank',
      'amount': 200,
      'coins': 999,
    });
    expect(body['requestType'], 'cfc');
    expect(body['amount'], 200);
    expect(body.containsKey('coins'), isFalse);
    expect(body['method'], 'bank_transfer');
  });

  test('buildCfcPaymentRequest is CFC-only body', () {
    final body = buildCfcPaymentRequest(
      cfcAmount: 150,
      method: 'papara',
    );
    expect(body['requestType'], 'cfc');
    expect(body['amount'], 150);
    expect(body.containsKey('coins'), isFalse);
    expect(body.containsKey('packageId'), isFalse);
  });

  test('buildJetonPaymentRequest sends amount for API validation', () {
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
