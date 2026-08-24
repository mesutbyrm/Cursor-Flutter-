import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../video/presentation/room_video_controller.dart';
import '../../providers/chat_room_providers.dart';

/// Videolu müzik çalarken herkese görünen kapat düğmesi (WebView arka plan üstü).
class VoiceRoomVideoCloseBar extends ConsumerWidget {
  const VoiceRoomVideoCloseBar({
    super.key,
    required this.roomKey,
    this.bottomPadding = 132,
  });

  final String roomKey;
  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final video = ref.watch(roomVideoControllerProvider(roomKey));
    if (!video.showsVideo && !video.hasActiveVideo) {
      return const SizedBox.shrink();
    }

    final title = video.title?.trim();
    final label = title != null && title.isNotEmpty ? title : 'Videolu müzik';

    return Positioned(
      left: 12,
      right: 12,
      bottom: bottomPadding,
      child: Material(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.music_video_rounded, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 36),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  final ctrl = ref.read(voiceRoomLiveProvider(roomKey).notifier);
                  unawaited(ctrl.closeMusicPlayer());
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close_rounded, size: 18),
                    SizedBox(width: 4),
                    Text('Kapat', style: TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
