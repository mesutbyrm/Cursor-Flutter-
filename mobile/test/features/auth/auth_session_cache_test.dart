import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/providers/auth_selectors.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';
import 'package:canlifal_social/features/wallet/domain/wallet_balances.dart';

void main() {
  test('currentUserCoinBalanceProvider prefers wallet over auth seed', () async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _StaticAuthController(coinBalance: 100),
        ),
        walletBalancesProvider.overrideWith(
          () => _StaticWalletNotifier(555),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(walletBalancesProvider.future);
    expect(container.read(currentUserCoinBalanceProvider), 555);
  });

  test('wallet empty when auth user logs out', () {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_NullAuthController.new),
        walletBalancesProvider.overrideWith(_StaticWalletNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(authControllerProvider).valueOrNull, isNull);
  });
}

class _StaticAuthController extends AuthController {
  _StaticAuthController({this.coinBalance = 0});

  final int coinBalance;

  @override
  Future<UserEntity?> build() async {
    return UserEntity(
      id: 'u1',
      username: 'test',
      coinBalance: coinBalance,
    );
  }
}

class _NullAuthController extends AuthController {
  @override
  Future<UserEntity?> build() async => null;
}

class _StaticWalletNotifier extends WalletBalancesNotifier {
  _StaticWalletNotifier([this.jeton = 777]);

  final int jeton;

  @override
  Future<WalletBalances> build() async => WalletBalances(jeton: jeton);
}
