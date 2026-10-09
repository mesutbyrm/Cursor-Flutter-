import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';
import 'package:canlifal_social/features/search/domain/entities/search_user_entity.dart';
import 'package:canlifal_social/features/search/data/datasources/search_remote_datasource.dart';
import 'package:canlifal_social/features/search/presentation/providers/search_providers.dart';
import 'package:canlifal_social/features/wallet/domain/wallet_balances.dart';
import 'package:canlifal_social/features/wallet_transfer/data/wallet_transfer_remote.dart';
import 'package:canlifal_social/features/wallet_transfer/presentation/wallet_transfer_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Wallet extends WalletBalancesNotifier {
  @override
  Future<WalletBalances> build() async =>
      const WalletBalances(jeton: 1000, cfc: 50);
  @override
  Future<WalletBalances> refresh({bool force = false}) async =>
      const WalletBalances(jeton: 1000, cfc: 50);
}

class _Search extends SearchRemoteDataSource {
  _Search() : super(Dio());
  @override
  Future<List<SearchUserEntity>> searchUsers(String query) async => const [
        SearchUserEntity(id: 'u2', name: 'Ayşe', username: 'ayse'),
      ];
}

class _Remote extends WalletTransferRemote {
  _Remote() : super(Dio());
  final sent = <Map<String, Object>>[];
  @override
  Future<TransferRules> fetchRules() async => const TransferRules(
        jeton: TransferRule(min: 100, commissionPercent: 10),
        cfc: TransferRule(min: 100, commissionPercent: 5),
      );
  @override
  Future<TransferResult> send({
    required String recipient,
    required TransferCurrency currency,
    required int amount,
    String? idempotencyKey,
  }) async {
    sent.add({'to': recipient, 'cur': currency.wire, 'amount': amount});
    return TransferResult(received: amount - amount ~/ 10, commission: amount ~/ 10);
  }
}

Future<_Remote> _pump(WidgetTester t) async {
  final remote = _Remote();
  await t.pumpWidget(ProviderScope(
    overrides: [
      walletBalancesProvider.overrideWith(_Wallet.new),
      searchRemoteProvider.overrideWithValue(_Search()),
      walletTransferRemoteProvider.overrideWithValue(remote),
    ],
    child: MaterialApp(theme: AppTheme.dark(), home: const WalletTransferPage()),
  ));
  await t.pumpAndSettle();
  await t.enterText(find.byKey(const Key('transfer-search')), 'ay');
  await t.pump(const Duration(milliseconds: 400));
  await t.pumpAndSettle();
  await t.tap(find.byKey(const Key('transfer-user-u2')));
  await t.pumpAndSettle();
  return remote;
}

void main() {
  test('komisyon ve net hesabı', () {
    const r = TransferRule(min: 100, commissionPercent: 10);
    expect(r.commissionFor(250), 25);
    expect(r.netFor(250), 225);
  });

  testWidgets('100 altı gönderilemez', (t) async {
    final remote = await _pump(t);
    await t.enterText(find.byKey(const Key('transfer-amount')), '99');
    await t.pump();
    await t.tap(find.byKey(const Key('transfer-send')));
    await t.pumpAndSettle();
    expect(find.text('En az 100 Jeton gönderebilirsiniz'), findsOneWidget);
    expect(remote.sent, isEmpty);
  });

  testWidgets('bakiyeden fazlası gönderilemez (CFC)', (t) async {
    final remote = await _pump(t);
    await t.tap(find.text('CFC (50)'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('transfer-amount')), '100');
    await t.pump();
    await t.tap(find.byKey(const Key('transfer-send')));
    await t.pumpAndSettle();
    expect(find.text('Yetersiz CFC bakiyesi'), findsOneWidget);
    expect(remote.sent, isEmpty);
  });

  testWidgets('onaylanınca gönderir; özet komisyonu gösterir', (t) async {
    final remote = await _pump(t);
    await t.enterText(find.byKey(const Key('transfer-amount')), '200');
    await t.pump();
    expect(find.textContaining('Alıcıya geçecek: 180 Jeton'), findsOneWidget);
    await t.tap(find.byKey(const Key('transfer-send')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('transfer-confirm')));
    await t.pumpAndSettle();
    expect(remote.sent.single, {'to': 'u2', 'cur': 'jeton', 'amount': 200});
    expect(find.textContaining('180 Jeton gönderildi'), findsOneWidget);
    // Snackbar ve cüzdan yenileme zamanlayıcıları bitsin.
    await t.pump(const Duration(seconds: 15));
  });
}
