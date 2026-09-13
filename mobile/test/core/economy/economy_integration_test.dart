import 'package:canlifal_social/core/economy/data/economy_wallet_remote_datasource.dart';
import 'package:canlifal_social/core/economy/domain/currency_branding_snapshot.dart';
import 'package:canlifal_social/core/economy/domain/economy_payment_models.dart';
import 'package:canlifal_social/core/economy/domain/economy_wallet_snapshot.dart';
import 'package:canlifal_social/core/economy/services/economy_wallet_adapter.dart';
import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:canlifal_social/features/wallet/domain/wallet_balances.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyBrandingSnapshot', () {
    test('parses jeton/cfc branding and rules', () {
      final snapshot = CurrencyBrandingSnapshot.fromJson({
        'jeton': {
          'key': 'jeton',
          'name': 'Altın',
          'nameEn': 'Gold',
          'icon': '/currency/jeton.svg',
          'color': '#F5C542',
          'convertible': true,
        },
        'cfc': {
          'key': 'cfc',
          'name': 'Coin',
          'nameEn': 'Coin',
          'icon': '/currency/cfc.svg',
          'color': '#A78BFA',
          'convertible': false,
        },
        'rules': {
          'convertible': ['jeton'],
          'rewardCurrency': 'cfc',
        },
      });

      expect(snapshot.jeton.name, 'Altın');
      expect(snapshot.cfc.convertible, isFalse);
      expect(snapshot.rewardCurrency, 'cfc');
    });

    test('defaults remain stable when remote fails', () {
      expect(CurrencyBrandingSnapshot.defaults.jeton.name, 'Jeton');
      expect(CurrencyBrandingSnapshot.defaults.cfc.name, 'CFC');
    });
  });

  group('EconomyWalletSnapshot', () {
    test('parses Abacus GET /api/wallet flat payload', () {
      final snapshot = EconomyWalletSnapshot.fromJson({
        'coins': 0,
        'jetonBalance': 12,
        'cfcBalance': 55,
        'credits': 55,
      });
      expect(snapshot.jeton, 12);
      expect(snapshot.cfc, 55);
    });

    test('parses unified wallet payload', () {
      final snapshot = EconomyWalletSnapshot.fromJson({
        'balances': {'cfc': 55, 'jeton': 10, 'legacyCfc': 0},
        'branding': CurrencyBrandingSnapshot.defaults.toJsonLike(),
        'earnings': {'referralCreditsEarned': 3, 'tellerEarnings': 0},
        'referralCode': 'ABC',
        'withdrawal': {
          'canWithdraw': false,
          'minWithdrawal': 3000,
          'jetonTlRate': 0.5,
          'estimatedTl': 5,
        },
        'transactions': [
          {
            'id': 'c_1',
            'currency': 'cfc',
            'amount': -2,
            'type': 'bana_ozel',
            'balanceAfter': 53,
          },
        ],
        'total': 1,
      });

      expect(snapshot.cfc, 55);
      expect(snapshot.jeton, 10);
      expect(snapshot.transactions, hasLength(1));
    });
  });

  group('EconomyWalletAdapter', () {
    test('maps legacy WalletBalances when unified endpoint unavailable', () {
      const legacy = WalletBalances(jeton: 12, cfc: 34, withdrawalLimit: 1000);
      final mapped = EconomyWalletAdapter(
        EconomyWalletRemoteDataSource(Dio()),
      ).fromLegacyBalances(legacy);

      expect(mapped.jeton, 12);
      expect(mapped.cfc, 34);
      expect(mapped.minWithdrawal, 1000);
    });
  });

  group('BanaOzelInsufficientPayment', () {
    test('parses 402 payload', () {
      final gate = BanaOzelInsufficientPayment.fromJson({
        'error': 'Yetersiz bakiye',
        'required': 2,
        'cfcBalance': 0,
        'jetonBalance': 1,
        'canWatchAd': true,
        'adRemaining': -1,
        'adUnlimited': true,
      });

      expect(gate.canWatchAd, isTrue);
      expect(gate.adUnlimited, isTrue);
    });
  });

  group('economy API endpoints', () {
    test('new endpoints are additive', () {
      expect(ApiEndpoints.currencyBranding, '/api/currency-branding');
      expect(ApiEndpoints.userWallet, '/api/user/wallet');
      expect(ApiEndpoints.userReferralEarnings, '/api/user/referral-earnings');
      expect(ApiEndpoints.agencyInviteEarnings, '/api/agency/invite-earnings');
      expect(ApiEndpoints.wallet, '/api/wallet');
      expect(ApiEndpoints.referralEarnings, '/api/referral/earnings');
      expect(ApiEndpoints.gameSosCreate, '/api/games/sos/create');
      expect(ApiEndpoints.banaOzelOpen, '/api/bana-ozel/open');
      expect(ApiEndpoints.gameSosEconomy, '/api/games/sos');
    });
  });
}

extension on CurrencyBrandingSnapshot {
  Map<String, dynamic> toJsonLike() => {
        'jeton': {
          'key': jeton.key,
          'name': jeton.name,
          'nameEn': jeton.nameEn,
          'icon': jeton.icon,
          'color': jeton.color,
          'convertible': jeton.convertible,
        },
        'cfc': {
          'key': cfc.key,
          'name': cfc.name,
          'nameEn': cfc.nameEn,
          'icon': cfc.icon,
          'color': cfc.color,
          'convertible': cfc.convertible,
        },
      };
}
