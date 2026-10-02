import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_selectors.dart';
import '../../../wallet/domain/cfc_payment_request_entity.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import 'profile_providers.dart';

/// Ödeme talepleri — SUNUCU tek doğruluk kaynağıdır (`GET /api/payments/requests`).
///
/// Yerel bayrak/önbellek tutulmaz: sağlayıcı `autoDispose`dur (ekran açıldıkça
/// sunucudan taze çekilir), kullanıcı değişince sıfırlanır ve uygulama öne
/// gelince sessizce yenilenebilir ([refresh] `silent: true`).
class PaymentRequestsNotifier
    extends AutoDisposeAsyncNotifier<List<CfcPaymentRequestEntity>> {
  int _page = 1;
  bool _end = false;
  bool _loadingMore = false;

  @override
  Future<List<CfcPaymentRequestEntity>> build() async {
    _page = 1;
    _end = false;
    // Hesap değişince (çıkış/giriş) önceki kullanıcının talepleri kalmasın.
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null || uid.isEmpty) return const [];
    final bundle = await ref
        .read(walletRepositoryProvider)
        .myPaymentRequestsPage(page: 1);
    _end = !bundle.hasMore;
    return bundle.items;
  }

  /// [silent]: mevcut liste ekranda kalır (banner titremez); hata olursa eski
  /// liste korunur.
  Future<void> refresh({bool silent = false}) async {
    final previous = state;
    if (!silent || !previous.hasValue) {
      state = const AsyncValue.loading();
    }
    final next = await AsyncValue.guard(() async {
      _page = 1;
      _end = false;
      final bundle = await ref
          .read(walletRepositoryProvider)
          .myPaymentRequestsPage(page: 1);
      _end = !bundle.hasMore;
      return bundle.items;
    });
    if (silent && next.hasError && previous.hasValue) return;
    state = next;
  }

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || _end || _loadingMore) return;
    _loadingMore = true;
    final nextPage = _page + 1;
    try {
      final bundle = await ref
          .read(walletRepositoryProvider)
          .myPaymentRequestsPage(page: nextPage);
      if (bundle.items.isEmpty) {
        _end = true;
        return;
      }
      _page = nextPage;
      _end = !bundle.hasMore;
      state = AsyncValue.data([...cur, ...bundle.items]);
    } finally {
      _loadingMore = false;
    }
  }

  bool get hasMore => !_end;

  // Backend'de ödeme talebi iptal ucu yok (`/api/payments/requests` yalnız
  // GET/POST). Toplu/otomatik iptal ağ isteği atmadan 0 döner; talebi
  // yönetici onaylar ya da reddeder.
  Future<int> cancelExpiredPending() async {
    final cur = state.valueOrNull ?? await future;
    final now = DateTime.now();
    var expired = 0;
    for (final r in cur) {
      if (!r.isPending) continue;
      final exp = r.expiresAt;
      if (exp != null && now.isAfter(exp)) expired++;
    }
    return expired;
  }

  CfcPaymentRequestEntity? pendingJetonRequestOlderThanHour() {
    final cur = state.valueOrNull;
    if (cur == null) return null;
    final now = DateTime.now();
    for (final r in cur) {
      if (!r.isPending || r.requestType != 'jeton') continue;
      final exp = r.expiresAt;
      if (exp != null && now.isAfter(exp)) return r;
    }
    return null;
  }

  Future<void> cancelPending(String requestId) async {
    await ref.read(walletRepositoryProvider).cancelPaymentRequest(requestId);
    try {
      await ref
          .read(notificationsRepositoryProvider)
          .clearPaymentNotifications();
    } catch (_) {}
    await refresh();
  }

  Future<int> cancelAllPending() async => 0;
}

final paymentRequestsNotifierProvider =
    AsyncNotifierProvider.autoDispose<
      PaymentRequestsNotifier,
      List<CfcPaymentRequestEntity>
    >(PaymentRequestsNotifier.new);
