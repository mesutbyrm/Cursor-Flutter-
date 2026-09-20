import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../notifications/presentation/providers/notifications_list_notifier.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../providers/payment_requests_notifier.dart';

/// Jeton / üyelik mağazası açılışında hayalet bekleyen talepleri temizler.
Future<int> cleanupStalePaymentRequests(WidgetRef ref) async {
  final notifier = ref.read(paymentRequestsNotifierProvider.notifier);
  await notifier.refresh();
  final expired = await notifier.cancelExpiredPending();
  final all = await notifier.cancelAllPending();
  if (expired > 0 || all > 0) {
    ref.invalidate(notificationsListProvider);
    ref.invalidate(notificationsListNotifierProvider);
  }
  return expired + all;
}
