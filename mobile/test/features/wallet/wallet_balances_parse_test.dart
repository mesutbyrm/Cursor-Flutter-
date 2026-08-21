import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/wallet/domain/wallet_balances.dart';

void main() {
  group('WalletBalances parse', () {
    test('parses jeton cfc membership', () {
      final w = WalletBalances.fromJson({
        'jetonBalance': 1200,
        'cfcBalance': 50,
        'membership': 'gold',
        'membershipExpiresAt': '2026-12-31T00:00:00.000Z',
        'favoriteTeam': 'Fenerbahçe',
      });
      expect(w.jeton, 1200);
      expect(w.cfc, 50);
      expect(w.membership, 'gold');
      expect(w.favoriteTeam, 'Fenerbahçe');
      expect(w.membershipDaysRemaining, isNotNull);
    });

    test('zero balance is valid not hidden in model', () {
      final w = WalletBalances.fromJson({'jetonBalance': 0, 'cfcBalance': 0});
      expect(w.jeton, 0);
      expect(w.cfc, 0);
    });

    test('missing price fields default to zero', () {
      final w = WalletBalances.fromJson({});
      expect(w.jeton, 0);
      expect(w.membership, isNull);
    });

    test('alternate jeton keys', () {
      final w = WalletBalances.fromJson({'coins': 42});
      expect(w.jeton, 42);
    });
  });
}
