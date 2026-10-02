import 'package:canlifal_social/core/pagination/paged_result.dart';
import 'package:canlifal_social/core/providers/auth_selectors.dart';
import 'package:canlifal_social/features/profile/domain/repositories/profile_repository.dart';
import 'package:canlifal_social/features/profile/presentation/providers/payment_requests_notifier.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';
import 'package:canlifal_social/features/wallet/domain/cfc_payment_request_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

CfcPaymentRequestEntity _req(String id, String status) => CfcPaymentRequestEntity(
      id: id,
      amount: 100,
      method: 'papara',
      status: status,
      requestType: 'jeton',
    );

class _FakeWallet implements WalletRepository {
  List<CfcPaymentRequestEntity> server = [];
  int calls = 0;
  bool fail = false;

  @override
  Future<PagedResult<CfcPaymentRequestEntity>> myPaymentRequestsPage({
    int page = 1,
  }) async {
    calls++;
    if (fail) throw Exception('ağ');
    return PagedResult(items: List.of(server), hasMore: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderContainer _container(_FakeWallet w, {String? uid = 'u1'}) {
  final c = ProviderContainer(
    overrides: [
      walletRepositoryProvider.overrideWithValue(w),
      currentUserIdProvider.overrideWithValue(uid),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('durum sunucudan gelir: onaylanan talep artık bekliyor sayılmaz', () async {
    final w = _FakeWallet()..server = [_req('a', 'pending')];
    final c = _container(w);
    final sub = c.listen(paymentRequestsNotifierProvider, (_, __) {});
    addTearDown(sub.close);
    var list = await c.read(paymentRequestsNotifierProvider.future);
    expect(list.where((r) => r.isPending), hasLength(1));

    w.server = [_req('a', 'approved')];
    await c.read(paymentRequestsNotifierProvider.notifier).refresh(silent: true);
    list = c.read(paymentRequestsNotifierProvider).requireValue;
    expect(list.where((r) => r.isPending), isEmpty);
  });

  test('silent refresh: hata olursa eski liste korunur', () async {
    final w = _FakeWallet()..server = [_req('a', 'pending')];
    final c = _container(w);
    final sub = c.listen(paymentRequestsNotifierProvider, (_, __) {});
    addTearDown(sub.close);
    await c.read(paymentRequestsNotifierProvider.future);

    w.fail = true;
    await c.read(paymentRequestsNotifierProvider.notifier).refresh(silent: true);
    final state = c.read(paymentRequestsNotifierProvider);
    expect(state.hasError, isFalse);
    expect(state.requireValue, hasLength(1));
  });

  test('oturum yoksa istek atılmaz, liste boş', () async {
    final w = _FakeWallet()..server = [_req('a', 'pending')];
    final c = _container(w, uid: null);
    final sub = c.listen(paymentRequestsNotifierProvider, (_, __) {});
    addTearDown(sub.close);
    final list = await c.read(paymentRequestsNotifierProvider.future);
    expect(list, isEmpty);
    expect(w.calls, 0);
  });

  test('autoDispose: dinleyici kalmayınca sonraki açılışta sunucudan yeniden çekilir',
      () async {
    final w = _FakeWallet()..server = [_req('a', 'pending')];
    final c = _container(w);
    var sub = c.listen(paymentRequestsNotifierProvider, (_, __) {});
    await c.read(paymentRequestsNotifierProvider.future);
    expect(w.calls, 1);
    sub.close();
    await Future<void>.delayed(Duration.zero);

    w.server = const [];
    sub = c.listen(paymentRequestsNotifierProvider, (_, __) {});
    addTearDown(sub.close);
    final list = await c.read(paymentRequestsNotifierProvider.future);
    expect(w.calls, 2);
    expect(list, isEmpty);
  });
}
