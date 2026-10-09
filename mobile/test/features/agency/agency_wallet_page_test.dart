import 'package:canlifal_social/features/agency/data/datasources/agency_wallet_datasource.dart';
import 'package:canlifal_social/features/agency/presentation/pages/agency_wallet_page.dart';
import 'package:canlifal_social/features/agency/presentation/providers/agency_providers.dart';
import 'package:canlifal_social/features/search/data/datasources/search_remote_datasource.dart';
import 'package:canlifal_social/features/search/domain/entities/search_user_entity.dart';
import 'package:canlifal_social/features/search/presentation/providers/search_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSearch extends SearchRemoteDataSource {
  _FakeSearch() : super(Dio());

  @override
  Future<List<SearchUserEntity>> searchUsers(String query) async => const [
        SearchUserEntity(id: 'u1', name: 'Ayşe', username: 'ayse'),
      ];
}

class _FakeWalletDs extends AgencyWalletDataSource {
  _FakeWalletDs({this.transferResult}) : super(Dio());

  final AgencyTransferResult? transferResult;
  final transfers = <(String, int, String?)>[];
  final purchases = <(int, String)>[];
  final cancelled = <String>[];

  @override
  Future<AgencyTransferResult> transfer({
    required String targetUserId,
    required int amount,
    String? reason,
    String? idempotencyKey,
  }) async {
    transfers.add((targetUserId, amount, idempotencyKey));
    return transferResult ??
        AgencyTransferResult(ok: true, message: '$amount Jeton yüklendi', walletBalance: 10000.0 - amount);
  }

  @override
  Future<AgencyPurchaseInfo> fetchPurchase({int? jeton}) async {
    final j = jeton ?? 100000;
    return AgencyPurchaseInfo(
      quote: AgencyPurchaseQuote(
        jetonAmount: j,
        normalPriceTl: j * 2.0,
        finalPriceTl: j * 2.0 * 0.9,
        discountPercent: 10,
        savedTl: j * 2.0 * 0.1,
      ),
      minJeton: 1000,
      enabled: true,
      orders: const [
        AgencyPurchaseOrder(id: 'o1', jeton: 50000, amountTl: 90000, status: 'pending'),
        AgencyPurchaseOrder(id: 'o2', jeton: 20000, amountTl: 36000, status: 'approved'),
      ],
    );
  }

  @override
  Future<void> createPurchase({
    required int jeton,
    required String paymentMethod,
    String? transactionId,
    String? senderName,
    String? notes,
  }) async {
    purchases.add((jeton, paymentMethod));
  }

  @override
  Future<void> cancelPaymentNotification(String id, {String? reason}) async {
    cancelled.add(id);
  }
}

Widget _app(_FakeWalletDs ds, {double balance = 10000}) => ProviderScope(
      overrides: [
        agencyWalletDataSourceProvider.overrideWithValue(ds),
        searchRemoteProvider.overrideWithValue(_FakeSearch()),
        agencyWalletProvider.overrideWith((ref) async => AgencyWalletSnapshot(jetonBalance: balance)),
      ],
      child: const MaterialApp(home: AgencyWalletPage()),
    );

Future<void> _pickUser(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('agency-load-search')), 'ay');
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('agency-load-user-u1')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('bakiye üstünde yükleme "1 jeton eksik" der, sunucuya gitmez', (tester) async {
    final ds = _FakeWalletDs();
    await tester.pumpWidget(_app(ds));
    await tester.pumpAndSettle();
    expect(find.text('10.000 Jeton'), findsOneWidget);

    await _pickUser(tester);
    await tester.enterText(find.byKey(const Key('agency-load-amount')), '10001');
    await tester.tap(find.byKey(const Key('agency-load-send')));
    await tester.pumpAndSettle();

    expect(find.text('Ajans bakiyesi yetersiz: 1 jeton eksik'), findsOneWidget);
    expect(find.byKey(const Key('agency-load-confirm')), findsNothing);
    expect(ds.transfers, isEmpty);
  });

  testWidgets('onaydan sonra tam miktar seçilen kullanıcıya yüklenir', (tester) async {
    final ds = _FakeWalletDs();
    await tester.pumpWidget(_app(ds));
    await tester.pumpAndSettle();

    await _pickUser(tester);
    await tester.enterText(find.byKey(const Key('agency-load-amount')), '10000');
    await tester.tap(find.byKey(const Key('agency-load-send')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('agency-load-confirm')));
    await tester.pumpAndSettle();

    expect(ds.transfers, hasLength(1));
    expect(ds.transfers.single.$1, 'u1');
    expect(ds.transfers.single.$2, 10000);
    expect(ds.transfers.single.$3, isNotEmpty);
    expect(find.text('@ayse hesabına 10.000 Jeton yüklendi'), findsOneWidget);
  });

  testWidgets('sunucu hatası (ör. eksik jeton) aynen gösterilir', (tester) async {
    final ds = _FakeWalletDs(
      transferResult: const AgencyTransferResult(ok: false, message: 'Ajans bakiyesi yetersiz: 5 jeton eksik'),
    );
    await tester.pumpWidget(_app(ds));
    await tester.pumpAndSettle();

    await _pickUser(tester);
    await tester.enterText(find.byKey(const Key('agency-load-amount')), '500');
    await tester.tap(find.byKey(const Key('agency-load-send')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('agency-load-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('agency-load-error')), findsOneWidget);
    expect(find.text('Ajans bakiyesi yetersiz: 5 jeton eksik'), findsOneWidget);
  });

  testWidgets('toplu alım: sunucu teklifi gösterilir, sipariş ve iptal gönderilir', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final ds = _FakeWalletDs();
    await tester.pumpWidget(_app(ds));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('agency-tab-buy')));
    await tester.pumpAndSettle();

    final quote = find.byKey(const Key('agency-buy-quote'));
    expect(find.descendant(of: quote, matching: find.text('100.000 Jeton')), findsOneWidget);
    expect(find.descendant(of: quote, matching: find.text('%10')), findsOneWidget);
    expect(find.descendant(of: quote, matching: find.textContaining('180.000')), findsOneWidget);

    await tester.tap(find.byKey(const Key('agency-buy-send')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('agency-buy-confirm')));
    await tester.pumpAndSettle();
    expect(ds.purchases, [(100000, 'bank_transfer')]);

    // Yalnız bekleyen sipariş iptal edilebilir.
    expect(
      find.descendant(of: find.byKey(const Key('agency-order-o2')), matching: find.text('İptal')),
      findsNothing,
    );
    await tester.tap(find.descendant(of: find.byKey(const Key('agency-order-o1')), matching: find.text('İptal')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'İptal et'));
    await tester.pumpAndSettle();
    expect(ds.cancelled, ['o1']);
  });

  test('sipariş durumu: bekleyen ve düzeltilen iptal edilebilir', () {
    expect(const AgencyPurchaseOrder(id: 'a', jeton: 1, amountTl: 1, status: 'pending').cancellable, isTrue);
    expect(const AgencyPurchaseOrder(id: 'a', jeton: 1, amountTl: 1, status: 'corrected').cancellable, isTrue);
    expect(const AgencyPurchaseOrder(id: 'a', jeton: 1, amountTl: 1, status: 'approved').cancellable, isFalse);
  });
}
