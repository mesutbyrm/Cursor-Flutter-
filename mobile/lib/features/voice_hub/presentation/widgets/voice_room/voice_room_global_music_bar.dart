import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/chat_room_providers.dart';
import '../../providers/voice_room_ui_provider.dart';
import '../../../video/presentation/room_video_controller.dart';

/// Eski global müzik şeridi — Video Müzik Modu ile devre dışı.
class VoiceRoomGlobalMusicBar extends ConsumerWidget {
  const VoiceRoomGlobalMusicBar({super.key, required this.routePath});

  final String routePath;

  static bool shouldShowForRoute(String location) {
    var path = Uri.tryParse(location)?.path ?? location;
    if (!path.startsWith('/')) path = '/$path';
    if (path == '/voice-room' || path.startsWith('/voice-room/')) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(voiceRoomRtcForegroundProvider)) {
      return const SizedBox.shrink();
    }
    if (!shouldShowForRoute(routePath)) {
      return const SizedBox.shrink();
    }
    final session = ref.watch(voiceRoomMusicSessionProvider);
    if (session.room == null || !session.hasActiveMusic) {
      return const SizedBox.shrink();
    }
    final room = session.room!;
    final videoActive =
        ref.watch(roomVideoControllerProvider(room.liveKey)).hasActiveVideo;
    if (videoActive) {
      return const SizedBox.shrink();
    }
    return const SizedBox.shrink();
  }
}
