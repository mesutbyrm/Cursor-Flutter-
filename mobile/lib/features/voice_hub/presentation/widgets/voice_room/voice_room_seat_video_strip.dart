import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../video/presentation/widgets/youtube_video_background.dart';
import '../../../video/presentation/room_video_controller.dart';

/// Koltuk altı video şeridi — videolu isteklerde YouTube arka plan.
class VoiceRoomSeatVideoStrip extends ConsumerWidget {
  const VoiceRoomSeatVideoStrip({
    super.key,
    required this.roomKey,
  });

  final String roomKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final video = ref.watch(roomVideoControllerProvider(roomKey));
    if (!video.hasActiveVideo) {
      return const SizedBox.shrink();
    }

    final width = MediaQuery.sizeOf(context).width;
    final height = (width * 9 / 16).clamp(52.0, 96.0);
    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: YoutubeVideoBackground(
          roomKey: roomKey,
          compact: true,
        ),
      ),
    );
  }
}
