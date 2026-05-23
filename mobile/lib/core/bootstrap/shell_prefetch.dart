import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/messages/presentation/providers/messages_providers.dart';
import '../../../features/notifications/presentation/providers/notifications_providers.dart';
import '../../../features/profile/presentation/providers/profile_providers.dart';

/// Ana kabuk açıldığında sık kullanılan verileri arka planda önceden yükler.
void prefetchShellData(WidgetRef ref) {
  ref.read(notificationsListProvider.future).ignore();
  ref.read(walletBalancesProvider.future).ignore();
  ref.read(jetonPackagesProvider.future).ignore();
  try {
    ref.read(conversationsProvider.future).ignore();
  } catch (_) {}
}
