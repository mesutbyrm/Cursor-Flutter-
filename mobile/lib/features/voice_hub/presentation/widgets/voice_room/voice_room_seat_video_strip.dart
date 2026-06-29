import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../video/presentation/room_video_controller.dart';
import '../../../video/presentation/widgets/youtube_video_background.dart';

/// Koltukların hemen altında tam genişlik, kenarsız YouTube oynatıcı.
class VoiceRoomSeatVideoStrip extends ConsumerWidget {
  const VoiceRoomSeatVideoStrip({
    super.key,
    required this.roomKey,
  });

  final String roomKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final video = ref.watch(roomVideoControllerProvider(roomKey));
    if (!video.hasActiveVideo) return const SizedBox.shrink();

    final width = MediaQuery.sizeOf(context).width;
    final height = (width * 9 / 16).clamp(52.0, 96.0);

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.center,
          minWidth: width,
          maxWidth: width,
          minHeight: height,
          maxHeight: height,
          child: SizedBox(
            width: width,
            height: height,
            child: _SeatVideoPlayer(roomKey: roomKey),
          ),
        ),
      ),
    );
  }
}

class _SeatVideoPlayer extends ConsumerWidget {
  const _SeatVideoPlayer({required this.roomKey});

  final String roomKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return YoutubeVideoBackground(
      roomKey: roomKey,
      compact: true,
    );
  }
}
