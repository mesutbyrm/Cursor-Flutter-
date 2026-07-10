import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../wallet/domain/cfc_payment_request_entity.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import 'profile_providers.dart';

class PaymentRequestsNotifier
    extends AsyncNotifier<List<CfcPaymentRequestEntity>> {
  int _page = 1;
  bool _end = false;
  bool _loadingMore = false;

  @override
  Future<List<CfcPaymentRequestEntity>> build() async {
    _page = 1;
    _end = false;
    final bundle =
        await ref.read(walletRepositoryProvider).myPaymentRequestsPage(page: 1);
    _end = !bundle.hasMore;
    return _cancelExpiredAndMaybeReload(bundle.items);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      _page = 1;
      _end = false;
      final bundle =
          await ref.read(walletRepositoryProvider).myPaymentRequestsPage(page: 1);
      _end = !bundle.hasMore;
      return _cancelExpiredAndMaybeReload(bundle.items);
    });
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

  Future<List<CfcPaymentRequestEntity>> _cancelExpiredAndMaybeReload(
    List<CfcPaymentRequestEntity> items,
  ) async {
    final expired = items.where((r) => r.shouldAutoCancel).toList();
    if (expired.isEmpty) return items;
    final repo = ref.read(walletRepositoryProvider);
    for (final r in expired) {
      try {
        await repo.cancelPaymentRequest(r.id);
      } catch (_) {}
    }
    try {
      await ref.read(notificationsRepositoryProvider).clearPaymentNotifications();
    } catch (_) {}
    final bundle = await repo.myPaymentRequestsPage(page: 1);
    _page = 1;
    _end = !bundle.hasMore;
    return bundle.items;
  }

  Future<int> cancelExpiredPending() async {
    final cur = state.valueOrNull ?? const <CfcPaymentRequestEntity>[];
    final expired = cur.where((r) => r.shouldAutoCancel).toList();
    if (expired.isEmpty) return 0;
    final repo = ref.read(walletRepositoryProvider);
    var cancelled = 0;
    for (final r in expired) {
      try {
        await repo.cancelPaymentRequest(r.id);
        cancelled++;
      } catch (_) {}
    }
    if (cancelled > 0) {
      try {
        await ref.read(notificationsRepositoryProvider).clearPaymentNotifications();
      } catch (_) {}
      await refresh();
    }
    return cancelled;
  }

  Future<void> cancelPending(String requestId) async {
    await ref.read(walletRepositoryProvider).cancelPaymentRequest(requestId);
    try {
      await ref.read(notificationsRepositoryProvider).clearPaymentNotifications();
    } catch (_) {}
    await refresh();
  }

  /// Tüm bekleyen talepleri iptal eder — birden fazla talep engeli olduğunda.
  Future<void> cancelAllPending() async {
    final repo = ref.read(walletRepositoryProvider);
    final pending = (state.valueOrNull ?? const [])
        .where((r) => r.status.toLowerCase() == 'pending')
        .toList();
    for (final r in pending) {
      try {
        await repo.cancelPaymentRequest(r.id);
      } catch (_) {}
    }
    try {
      await ref.read(notificationsRepositoryProvider).clearPaymentNotifications();
    } catch (_) {}
    await refresh();
  }
}

final paymentRequestsNotifierProvider =
    AsyncNotifierProvider<PaymentRequestsNotifier, List<CfcPaymentRequestEntity>>(
  PaymentRequestsNotifier.new,
);
