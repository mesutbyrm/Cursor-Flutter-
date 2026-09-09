import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../live/presentation/providers/live_providers.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';
import '../../providers/chat_room_providers.dart';
import '../../providers/room_fragment_providers.dart';
import '../../providers/voice_room_ui_provider.dart';
import '../../providers/voice_room_ranking_provider.dart';
import '../premium_2026/voice_live_header_2026.dart';
import '../premium_2026/voice_online_gift_box.dart';
import '../premium_2026/voice_live_action_bar_2026.dart';
import '../premium_2026/voice_web_room_header.dart';
import 'voice_room_spec_footer.dart';

/// SSE/foreground + müzik slice abonelikleri — yan etki; rebuild üretmez.
class VoiceRoomLifecycleHost extends ConsumerWidget {
  const VoiceRoomLifecycleHost({super.key, required this.roomKey});

  final String roomKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(voiceRoomForegroundLifecycleProvider(roomKey));
    ref.watch(voiceRoomMusicSliceProvider(roomKey));
    return const SizedBox.shrink();
  }
}

@Deprecated('Use VoiceRoomLifecycleHost')
typedef VoiceRoomRtcLifecycleHost = VoiceRoomLifecycleHost;

int? _hourlyRankForRoom(VoiceRoomRankingState state, String roomKey) {
  final id = roomKey.trim();
  if (id.isEmpty) return null;
  for (final e in state.hourly) {
    if (e.room.apiRoomKey == id || e.room.id == id) return e.rank;
  }
  return null;
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

/// Basic mod üst bar + çevrimiçi hediye kutusu — jeton/sıralama güncellemeleri gövdeyi rebuild etmez.
class VoiceRoomBasicHeaderBand extends ConsumerWidget {
  const VoiceRoomBasicHeaderBand({
    super.key,
    required this.liveRoomKey,
    required this.fallbackRoom,
    required this.onBack,
    required this.onExit,
    required this.onAudience,
    required this.onCoinsTap,
    required this.onRankTap,
  });

  final String liveRoomKey;
  final VoiceRoomEntity fallbackRoom;
  final VoidCallback onBack;
  final VoidCallback onExit;
  final VoidCallback onAudience;
  final VoidCallback onCoinsTap;
  final VoidCallback onRankTap;

  VoiceRoomEntity _displayRoom(VoiceRoomEntity? synced) {
    if (synced != null && synced.apiRoomKey.isNotEmpty) return synced;
    if (fallbackRoom.apiRoomKey.isNotEmpty) return fallbackRoom;
    return synced ?? fallbackRoom;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(voiceRoomRankingProvider);
    final room = _displayRoom(
      ref.watch(voiceRoomByIdProvider(
        liveRoomKey.isNotEmpty ? liveRoomKey : fallbackRoom.id,
      )).valueOrNull,
    );
    final roomKey = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    final online = ref.watch(
      voiceRoomLiveProvider(liveRoomKey).select((s) => s.onlineCountFor(room)),
    );
    final jeton = ref.watch(
      walletBalancesProvider.select((a) => a.valueOrNull?.jeton ?? 0),
    );
    final hourlyRank = ref.watch(
      voiceRoomRankingProvider.select((s) => _hourlyRankForRoom(s, roomKey)),
    );
    final ownerId = room.ownerId;
    final hostAvatar = ownerId == null
        ? null
        : ref.watch(
            voiceRoomSeatSliceProvider(liveRoomKey).select((slice) {
              for (final p in slice.presence) {
                if (p.id == ownerId) return p.image;
              }
              return null;
            }),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VoiceLiveHeader2026(
          room: room,
          onlineCount: online,
          coinBalance: jeton,
          hostAvatarUrl: hostAvatar,
          hourlyRank: hourlyRank,
          onRankTap: onRankTap,
          onBack: onBack,
          onExit: onExit,
          onAudience: onAudience,
          onCoinsTap: onCoinsTap,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: Align(
            alignment: Alignment.centerRight,
            child: VoiceOnlineGiftBox(
              onlineCount: online,
              onTap: onAudience,
            ),
          ),
        ),
      ],
    );
  }
}

/// Basic mod alt aksiyon çubuğu — hoparlör / konuşma isteği UI slice izole.
class VoiceRoomBasicFooterBand extends ConsumerWidget {
  const VoiceRoomBasicFooterBand({
    super.key,
    required this.micOn,
    required this.micEnabled,
    required this.showSpeakRequest,
    required this.onMic,
    required this.onGift,
    required this.onSettings,
    required this.onToggleAudioOutput,
    required this.onInvite,
    required this.onSpeakRequest,
    this.showSettings = false,
  });

  final bool micOn;
  final bool micEnabled;
  final bool showSpeakRequest;
  final VoidCallback onMic;
  final VoidCallback onGift;
  final VoidCallback onSettings;
  final VoidCallback onToggleAudioOutput;
  final VoidCallback onInvite;
  final VoidCallback onSpeakRequest;
  final bool showSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(voiceRoomUiProvider.select(voiceRoomUiFooterSlice));

    return VoiceLiveActionBar2026(
      micOn: micOn,
      micEnabled: micEnabled,
      onMic: onMic,
      onGift: onGift,
      onSettings: onSettings,
      showSettings: showSettings,
      headphonesOn: ui.headphonesOn,
      onToggleAudioOutput: onToggleAudioOutput,
      onInvite: onInvite,
      showSpeakRequest: showSpeakRequest,
      speakRequestPending: ui.requestSpeakPending,
      onSpeakRequest: onSpeakRequest,
    );
  }
}

/// RTC alt bar — mesaj girişi + hoparlör / konuşma isteği slice izole.
class VoiceRoomRtcFooterBand extends ConsumerWidget {
  const VoiceRoomRtcFooterBand({
    super.key,
    required this.liveRoomKey,
    required this.room,
    required this.canSpeak,
    required this.userId,
    required this.controller,
    required this.focusNode,
    required this.micOn,
    required this.micEnabled,
    required this.onSend,
    required this.onToggleAudioOutput,
    required this.onMicToggle,
    required this.onGift,
    required this.onInvite,
    required this.onEmojiTap,
    required this.onChanged,
    required this.onSpeakRequest,
  });

  final String liveRoomKey;
  final VoiceRoomEntity room;
  final bool canSpeak;
  final String? userId;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool micOn;
  final bool micEnabled;
  final VoidCallback onSend;
  final VoidCallback onToggleAudioOutput;
  final VoidCallback onMicToggle;
  final VoidCallback onGift;
  final VoidCallback onInvite;
  final VoidCallback onEmojiTap;
  final ValueChanged<String> onChanged;
  final VoidCallback onSpeakRequest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(voiceRoomUiProvider.select(voiceRoomUiFooterSlice));

    return VoiceRoomSpecFooter(
      liveRoomKey: liveRoomKey,
      controller: controller,
      focusNode: focusNode,
      onSend: onSend,
      onToggleAudioOutput: onToggleAudioOutput,
      headphonesOn: ui.headphonesOn,
      onMicToggle: onMicToggle,
      micOn: micOn,
      micEnabled: micEnabled,
      onSettings: () {},
      showSettings: false,
      onGift: onGift,
      onInvite: onInvite,
      selfUserId: userId,
      onEmojiTap: onEmojiTap,
      onChanged: onChanged,
      joinNotificationsEnabled: ui.chatNotificationSoundEnabled,
      showMusicRequest: false,
      showSpeakRequest: userId != null && !canSpeak,
      speakRequestPending: ui.requestSpeakPending,
      onSpeakRequest: onSpeakRequest,
    );
  }
}

