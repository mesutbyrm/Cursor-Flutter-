import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/messages/presentation/providers/conversations_list_notifier.dart';
import '../../../features/messages/presentation/providers/messages_providers.dart';
import '../../../features/profile/presentation/providers/profile_providers.dart';
import '../../../features/shorts/domain/repositories/shorts_repository.dart';
import '../../../features/shorts/presentation/providers/shorts_providers.dart';
import 'startup_perf.dart';
import '../../../features/gifts/presentation/providers/gift_providers.dart';
import '../../../features/voice_hub/presentation/providers/voice_gift_providers.dart';
import '../performance/voice_room_entry_perf.dart';

/// Ana kabuk açıldığında sık kullanılan verileri kademeli önceden yükler.
///
/// Kademe 1 (T+200ms): cüzdan + bildirim + profil istatistikleri (paralel).
/// Kademe 2 (T+1100ms): sohbet listesi.
/// Kademe 3 (T+2200ms): shorts For You feed.
/// Kademe 4 (T+3500ms): jeton paketleri.
void prefetchShellData(
  WidgetRef ref, {
  Duration delay = StartupPerf.shellPrefetchDelay,
}) {
  unawaited(
    Future<void>.delayed(delay, () {
      VoiceRoomEntryPerf.prewarmShell();
      // Cüzdan/bildirim HomeHeader rozetleri tarafından zaten yüklenir — yalnızca profil.
      unawaited(ref.read(profileStatsProvider.future));
      try {
        ref.read(chatRoomGiftsRemoteProvider).fetchGiftTypes().ignore();
      } catch (_) {}
    }),
  );

  // Canlı yayın / sesli oda hediye katalogları — ilk açılışta önbelleğe al.
  unawaited(
    Future<void>.delayed(StartupPerf.shellPrefetchTier1bDelay, () {
      try {
        ref.read(liveStreamGiftCatalogProvider.future).ignore();
        ref.read(voiceRoomGiftCatalogProvider.future).ignore();
      } catch (_) {}
      // Rozetler yüklendikten sonra tam liste yenileme (sessiz).
      try {
        ref.read(walletBalancesProvider.notifier).refresh(force: false);
      } catch (_) {}
    }),
  );

  unawaited(
    Future<void>.delayed(StartupPerf.shellPrefetchTier2Delay, () {
      try {
        ref.read(conversationsProvider.future).ignore();
        ref.read(conversationsListNotifierProvider.notifier).refresh(
              silent: true,
              forceRefresh: false,
            );
      } catch (_) {}
    }),
  );

  unawaited(
    Future<void>.delayed(StartupPerf.shellPrefetchTier3Delay, () {
      ref.read(shortsFeedProvider(ShortsFeedTab.forYou).future).ignore();
    }),
  );

  unawaited(
    Future<void>.delayed(StartupPerf.shellPrefetchTier4Delay, () {
      ref.read(jetonPackagesProvider.future).ignore();
    }),
  );
}
