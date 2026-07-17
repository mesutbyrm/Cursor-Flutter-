import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../video/presentation/widgets/youtube_video_background.dart';

/// Video isteği modunda YouTube IFrame; ses modunda gizli kalır.
class VoiceRoomYoutubeEmbedHost extends ConsumerWidget {
  const VoiceRoomYoutubeEmbedHost({
    super.key,
    required this.roomKey,
    this.compact = false,
  });

  final String roomKey;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return YoutubeVideoBackground(
      roomKey: roomKey,
      compact: compact,
    );
  }
}
