import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/live_gift_event.dart';
import '../../../notifications/domain/entities/app_notification_entity.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/gift_insights_remote_datasource.dart';
import '../../data/gift_repository.dart';
import '../../../voice_hub/domain/voice_official_join.dart';
import '../../../voice_hub/presentation/providers/voice_room_session_registry.dart';
import '../../../../core/room/room_event_scope.dart';
import '../../domain/homepage_gift_ticker.dart';
import '../providers/gift_display_settings_provider.dart';
import 'global_gift_notification.dart';
import 'global_gift_overlay_notifier.dart';

/// Insights feed kapısı — ilk poll geçmişi overlay'e basmaz.
final globalGiftFeedGateProvider = Provider<GlobalGiftFeedGate>((ref) {
  return GlobalGiftFeedGate();
});

final globalGiftRecentBigGateProvider = Provider<GlobalGiftIdGate>((ref) {
  return GlobalGiftIdGate();
});

/// Merkezi hediye olayı — SSE bildirim + recent-big + insights feed.
class GlobalGiftEventBridge extends ConsumerStatefulWidget {
  const GlobalGiftEventBridge({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<GlobalGiftEventBridge> createState() =>
      _GlobalGiftEventBridgeState();
}

class _GlobalGiftEventBridgeState extends ConsumerState<GlobalGiftEventBridge> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) {
      unawaited(_pollGifts());
    });
    Future.microtask(_pollGifts);
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _pollGifts() async {
    await Future.wait([
      _pollRecentBig(),
      _pollInsightsFeed(),
    ]);
  }

  Future<void> _pollRecentBig() async {
    if (!mounted) return;
    try {
      final items =
          await GiftRepository(ref.read(dioProvider)).fetchRecentBigGifts();
      final notifs = items
          .map(GlobalGiftNotification.fromMap)
          .where((n) => n.eventId.trim().isNotEmpty);
      final fresh = ref.read(globalGiftRecentBigGateProvider).takeNew(
            notifs,
            (n) => n.eventId,
          );
      if (!mounted) return;
      for (final item in fresh.reversed) {
        ref.read(globalGiftOverlayProvider.notifier).enqueue(item);
      }
    } catch (_) {}
  }

  Future<void> _pollInsightsFeed() async {
    if (!mounted) return;
    try {
      final ds = GiftInsightsRemoteDataSource(ref.read(dioProvider));
      final items = await ds.fetchFeed(limit: 8);
      final fresh = ref.read(globalGiftFeedGateProvider).takeNew(items);
      if (!mounted) return;
      for (final item in fresh.reversed) {
        ref
            .read(globalGiftOverlayProvider.notifier)
            .enqueue(GlobalGiftNotification.fromFeedItem(item));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(giftDisplaySettingsProvider);
    return widget.child;
  }
}

/// Bildirim SSE'den gelen hediye olaylarını global overlay'e yönlendirir.
void handleNotificationGiftForGlobalOverlay(
  WidgetRef ref,
  AppNotificationEntity notification,
) {
  final type = notification.type?.toLowerCase() ?? '';
  final blob = '${notification.title} ${notification.body ?? ''}';
  final isGift = type.contains('gift') ||
      type.contains('hediye') ||
      VoiceOfficialJoin.isHomeBannerGiftAnnouncement(blob);
  if (!isGift) return;
  final parsed = HomepageGiftTicker.tryParse(blob.trim());
  if (parsed != null && parsed.senderName != 'Biri') {
    ref
        .read(globalGiftOverlayProvider.notifier)
        .enqueue(GlobalGiftNotification.fromTicker(parsed));
    return;
  }
  ref.read(globalGiftOverlayProvider.notifier).enqueue(
        GlobalGiftNotification(
          eventId: notification.id,
          senderName: notification.title,
          giftName: notification.body ?? 'Hediye',
          displayLabel: HomepageGiftTicker.composeAnnouncement(
            senderName: notification.title,
            giftName: notification.body ?? 'Hediye',
          ),
        ),
      );
}

/// Oda/yayın hediye SSE'sinden global overlay'e — yalnızca 1000+ jeton.
void enqueueGlobalGiftFromLiveEvent(
  WidgetRef ref,
  LiveGiftEvent event, {
  String? sessionKey,
}) {
  if (event.jetonAmount < 1000) return;
  if (sessionKey != null && sessionKey.isNotEmpty) {
    final active = ref.read(voiceRoomActiveLiveKeyProvider)?.trim() ?? '';
    final aliases = ref.read(voiceRoomActiveKeyAliasesProvider);
    if (active.isNotEmpty &&
        !sessionKeyMatchesActiveRoom(
          sessionKey: sessionKey,
          activeRoomKey: active,
          roomAliases: aliases,
        )) {
      return;
    }
    // Sesli odada büyük hediye FxBigGiftBanner ile gösterilir.
    return;
  }
  ref
      .read(globalGiftOverlayProvider.notifier)
      .enqueue(GlobalGiftNotification.fromLiveGift(event));
}
