import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../live/presentation/providers/live_providers.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';
import '../../providers/chat_room_providers.dart';
import '../../providers/room_fragment_providers.dart';
import '../../providers/voice_room_ui_provider.dart';
import '../premium_2026/voice_web_room_header.dart';

/// SSE/foreground + müzik slice abonelikleri — yan etki; rebuild üretmez.
class VoiceRoomRtcLifecycleHost extends ConsumerWidget {
  const VoiceRoomRtcLifecycleHost({super.key, required this.roomKey});

  final String roomKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(voiceRoomForegroundLifecycleProvider(roomKey));
    ref.watch(voiceRoomMusicSliceProvider(roomKey));
    return const SizedBox.shrink();
  }
}

/// RTC üst bar — jeton / çevrimiçi / oda meta güncellemeleri sayfa gövdesini rebuild etmez.
class VoiceRoomRtcHeaderBand extends ConsumerWidget {
  const VoiceRoomRtcHeaderBand({
    super.key,
    required this.roomLookupKey,
    required this.liveRoomKey,
    required this.fallbackRoom,
    required this.onBack,
    required this.onExit,
    required this.onAudience,
    required this.onGallery,
    required this.onRoomPanel,
    required this.onShare,
    required this.onCoinsTap,
    this.galleryEnabled = false,
  });

  final String roomLookupKey;
  final String liveRoomKey;
  final VoiceRoomEntity fallbackRoom;
  final VoidCallback onBack;
  final VoidCallback onExit;
  final VoidCallback onAudience;
  final VoidCallback? onGallery;
  final VoidCallback onRoomPanel;
  final VoidCallback onShare;
  final VoidCallback onCoinsTap;
  final bool galleryEnabled;

  VoiceRoomEntity _displayRoom(VoiceRoomEntity? synced) {
    if (synced != null && synced.apiRoomKey.isNotEmpty) return synced;
    if (fallbackRoom.apiRoomKey.isNotEmpty) return fallbackRoom;
    return synced ?? fallbackRoom;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = _displayRoom(
      ref.watch(voiceRoomByIdProvider(roomLookupKey)).valueOrNull,
    );
    final online = ref.watch(
      voiceRoomLiveProvider(liveRoomKey).select((s) => s.onlineCountFor(room)),
    );
    final jeton = ref.watch(
      walletBalancesProvider.select((a) => a.valueOrNull?.jeton ?? 0),
    );
    final ownerId = room.ownerId;
    final headerAvatar = ownerId == null
        ? null
        : ref.watch(
            voiceRoomSeatSliceProvider(liveRoomKey).select((slice) {
              for (final p in slice.presence) {
                if (p.id == ownerId) return p.image;
              }
              return null;
            }),
          );

    return VoiceWebRoomHeader(
      room: room,
      onlineCount: online,
      coinBalance: jeton,
      onCoinsTap: onCoinsTap,
      roomAvatarUrl: headerAvatar,
      onBack: onBack,
      onExit: onExit,
      onAudience: onAudience,
      onGallery: galleryEnabled ? onGallery : null,
      onSettings: null,
      onRoomPanel: onRoomPanel,
      onShare: onShare,
    );
  }
}
