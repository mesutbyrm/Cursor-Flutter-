
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/bootstrap/startup_perf.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/ui/premium_2026/premium_immersive_background.dart';
import '../../feed/presentation/widgets/discover_premium_2026/discover_premium_visual.dart';
import '../../../core/widgets/discover_tab_layout.dart';
import '../../live/domain/entities/live_stream_entity.dart';
import '../../live/domain/entities/voice_room_entity.dart';
import '../../live/domain/entities/voice_room_sort.dart';
import '../../live/presentation/providers/live_providers.dart';
import 'providers/voice_rooms_presence_provider.dart';
import 'utils/open_voice_chat_room_flow.dart';
import '../../vip_gold/presentation/utils/open_voice_room_vip.dart';
import 'basic/voice_room_basic_list.dart';
import 'basic/voice_room_basic_mode.dart';
import 'widgets/premium_2026/voice_discover_hub_2026.dart';

/// Sesli sohbet keşfet — Premium 2026 hub (referans görsel).
class VoiceRoomsBody extends ConsumerStatefulWidget {
  const VoiceRoomsBody({
    super.key,
    this.embeddedInLiveShellTab = false,
  });

  final bool embeddedInLiveShellTab;

  @override
  ConsumerState<VoiceRoomsBody> createState() => _VoiceRoomsBodyState();
}

class _VoiceRoomsBodyState extends ConsumerState<VoiceRoomsBody>
    with AutomaticKeepAliveClientMixin {
  Timer? _roomListRefresh;
  Timer? _presenceTimer;
  Timer? _liveStreamsTimer;
  var _presenceReady = false;
  var _liveStreamsReady = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _presenceTimer = Timer(LazyLoadPerf.voiceRoomPresence, () {
      if (mounted) setState(() => _presenceReady = true);
    });
    _liveStreamsTimer = Timer(LazyLoadPerf.voiceRoomLiveStreams, () {
      if (mounted) setState(() => _liveStreamsReady = true);
    });
    _roomListRefresh = Timer.periodic(const Duration(seconds: 25), (_) {
      if (!mounted) return;
      ref.invalidate(voiceRoomsProvider);
    });
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
    _liveStreamsTimer?.cancel();
    _roomListRefresh?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!Env.useNextAuth) {
      return const DiscoverEmptyState(
        icon: Icons.headset_mic_outlined,
        message:
            'Bu özellik canlifal.com oturumu ile kullanılabilir.\nGiriş yaptıktan sonra odalar burada listelenir.',
      );
    }

    final rooms = ref.watch(voiceRoomsProvider);
    final presence = _presenceReady
        ? ref.watch(voiceRoomsPresenceProvider)
        : const VoiceRoomsPresenceState();
    final liveStreams = _liveStreamsReady && !VoiceRoomBasicMode.enabled
        ? ref.watch(liveStreamsProvider)
        : const AsyncValue<List<LiveStreamEntity>>.data([]);
    final mq = MediaQuery.paddingOf(context);
    final topPad = widget.embeddedInLiveShellTab
        ? 8.0
        : mq.top + kToolbarHeight + 4;

    return rooms.when(
      loading: () => const DiscoverAccentLoader(),
      error: (e, _) => DiscoverEmptyState(
        icon: Icons.mic_off_rounded,
        message: ApiException.userMessage(e),
        actionLabel: 'Yenile',
        action: () => ref.invalidate(voiceRoomsProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return DiscoverEmptyState(
            icon: Icons.nights_stay_rounded,
            message: 'Henüz oda yok.\nİlk sesli sohbet odasını sen aç!',
            actionLabel: 'Oda Aç',
            action: () => showOpenVoiceChatRoomFlow(context, ref),
          );
        }

        final ordered = _orderedRooms(list, ref.watch(myVoiceRoomProvider));
        final withPresence = ordered
            .map(
              (r) => r.copyWith(
                onlineCount: presence.countFor(r),
              ),
            )
            .toList();
        final live = liveStreams.valueOrNull ?? const [];

        return PremiumImmersiveBackground(
          child: RefreshIndicator(
            color: DiscoverPremiumVisual.accent,
            backgroundColor: DiscoverPremiumVisual.backgroundMid,
            onRefresh: () async {
              ref.invalidate(voiceRoomsProvider);
              if (!VoiceRoomBasicMode.enabled) {
                ref.invalidate(liveStreamsProvider);
              }
            },
            child: VoiceRoomBasicMode.enabled
                ? VoiceRoomBasicList(rooms: withPresence, ref: ref)
                : VoiceDiscoverHub2026(
                    rooms: withPresence,
                    liveStreams: live,
                    topPadding: topPad,
                    onRoomTap: (r) => openVoiceRoomWithVipGate(context, ref, r),
                    onSearchChanged: (_) {},
                  ),
          ),
        );
      },
    );
  }

  static List<VoiceRoomEntity> _orderedRooms(
    List<VoiceRoomEntity> all,
    VoiceRoomEntity? mine,
  ) {
    final sorted = sortVoiceRoomsByPopularity(all);
    if (mine == null) return sorted;
    final rest = sorted.where((r) => r.id != mine.id).toList();
    return [mine, ...rest];
  }
}
