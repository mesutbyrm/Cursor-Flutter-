import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../video/presentation/widgets/youtube_video_background.dart';

/// Video isteği modunda YouTube IFrame; ses modunda gizli kalır.
class VoiceRoomYoutubeEmbedHost extends ConsumerWidget {
  const VoiceRoomYoutubeEmbedHost({
    super.key,
    required this.roomKey,
    this.compact = false,
    this.fillBackground = true,
  });

  final String roomKey;
  final bool compact;
  /// Video isteğinde tam ekran arka plan (koltukların arkasında).
  final bool fillBackground;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = YoutubeVideoBackground(
      roomKey: roomKey,
      compact: compact,
      fillBackground: fillBackground,
    );
    if (fillBackground && !compact) {
      return Positioned.fill(child: child);
    }
    return child;
  }
}
