import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../video/presentation/room_video_controller.dart';
import '../../../video/presentation/widgets/youtube_video_background.dart';

/// Videolu müzik isteği — koltuk alanı altında 1×1 gerçek YouTube oynatıcı.
class VoiceRoomSeatVideoStrip extends ConsumerWidget {
  const VoiceRoomSeatVideoStrip({
    super.key,
    required this.roomKey,
    this.size = 56,
  });

  final String roomKey;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final video = ref.watch(roomVideoControllerProvider(roomKey));
    if (!video.hasActiveVideo || video.videoId == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: size,
              height: size,
              child: YoutubeVideoBackground(
                roomKey: roomKey,
                compact: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
