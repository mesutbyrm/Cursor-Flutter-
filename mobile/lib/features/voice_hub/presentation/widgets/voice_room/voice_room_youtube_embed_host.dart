import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../services/voice_room_dj_player.dart';
import '../../providers/chat_room_providers.dart';

/// Tek YouTube IFrame oynatıcı — ses modunda görünmez, video modunda şerit.
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
    final player = ref.watch(voiceRoomDjPlayerProvider);

    return ValueListenableBuilder<VoiceRoomEmbedUiState>(
      valueListenable: player.embedUi,
      builder: (context, ui, _) {
        final videoId = ui.videoId?.trim();
        if (videoId == null || videoId.isEmpty) {
          return const SizedBox.shrink();
        }

        if (ui.unplayable) {
          return _UnplayableBanner(compact: compact);
        }

        final showVideo = ui.showVideo;
        final playerWidget = YoutubePlayer(
          controller: player.youtubeController,
          aspectRatio: 16 / 9,
        );

        if (!showVideo) {
          return SizedBox(
            width: 1,
            height: 1,
            child: Opacity(
              opacity: 0,
              child: IgnorePointer(child: playerWidget),
            ),
          );
        }

        if (compact) {
          return ClipRect(child: playerWidget);
        }

        final width = MediaQuery.sizeOf(context).width;
        return Center(
          child: Container(
            width: (width * 0.72).clamp(220.0, 320.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: playerWidget,
          ),
        );
      },
    );
  }
}

class _UnplayableBanner extends StatelessWidget {
  const _UnplayableBanner({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
        : const EdgeInsets.all(16);
    return Padding(
      padding: padding,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(compact ? 8 : 12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            '⚠️ Bu şarkı çalınamıyor, lütfen başka bir şarkı deneyin.',
            style: TextStyle(
              color: Colors.amber.shade100,
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
