import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/messages/presentation/providers/conversations_list_notifier.dart';
import '../../../features/messages/presentation/providers/messages_providers.dart';
import '../../../features/notifications/presentation/providers/notifications_providers.dart';
import '../../../features/profile/presentation/providers/profile_providers.dart';
import 'startup_perf.dart';
import '../performance/voice_room_entry_perf.dart';

/// Ana kabuk açıldığında sık kullanılan verileri arka planda önceden yükler.
void prefetchShellData(
  WidgetRef ref, {
  Duration delay = StartupPerf.shellPrefetchDelay,
}) {
  unawaited(
    Future<void>.delayed(delay, () {
      VoiceRoomEntryPerf.prewarmShell();
      ref.read(notificationsListProvider.future).ignore();
      ref.read(walletBalancesProvider.future).ignore();
      ref.read(profileStatsProvider.future).ignore();
      ref.read(jetonPackagesProvider.future).ignore();
      try {
        ref.read(conversationsProvider.future).ignore();
        ref.read(conversationsListNotifierProvider.notifier).refresh(
              silent: true,
              forceRefresh: false,
            );
      } catch (_) {}
    }),
  );
}
