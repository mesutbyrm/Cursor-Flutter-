import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/live_gift_event.dart';
import '../../../notifications/domain/entities/app_notification_entity.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/gift_insights_remote_datasource.dart';
import '../../domain/gift_feed_item.dart';
import '../../../voice_hub/presentation/providers/voice_room_session_registry.dart';
import '../../../../core/room/room_event_scope.dart';
import '../providers/gift_display_settings_provider.dart';
import 'global_gift_notification.dart';
import 'global_gift_overlay_notifier.dart';

/// Merkezi hediye olayı — SSE bildirim + insights feed poll.
class GlobalGiftEventBridge extends ConsumerStatefulWidget {
  const GlobalGiftEventBridge({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<GlobalGiftEventBridge> createState() =>
      _GlobalGiftEventBridgeState();
}

class _GlobalGiftEventBridgeState extends ConsumerState<GlobalGiftEventBridge> {
  Timer? _poll;
  final _seenFeedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(_pollInsightsFeed());
    });
    Future.microtask(_pollInsightsFeed);
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _pollInsightsFeed() async {
    if (!mounted) return;
    try {
      final ds = GiftInsightsRemoteDataSource(ref.read(dioProvider));
      final items = await ds.fetchFeed(limit: 8);
      for (final item in items.reversed) {
        _enqueueFeedItem(item);
      }
    } catch (_) {}
  }

  void _enqueueFeedItem(GiftFeedItem item) {
    final id = item.id.trim();
    if (id.isNotEmpty && !_seenFeedIds.add(id)) return;
    if (_seenFeedIds.length > 400) {
      _seenFeedIds.remove(_seenFeedIds.first);
    }
    ref
        .read(globalGiftOverlayProvider.notifier)
        .enqueue(GlobalGiftNotification.fromFeedItem(item));
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
  if (!type.contains('gift') && !type.contains('hediye')) return;
  ref.read(globalGiftOverlayProvider.notifier).enqueue(
        GlobalGiftNotification(
          eventId: notification.id,
          senderName: notification.title,
          giftName: notification.body ?? 'Hediye',
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
