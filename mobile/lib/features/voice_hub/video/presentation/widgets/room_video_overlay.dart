import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../presentation/providers/chat_room_providers.dart';
import '../../../presentation/utils/voice_room_permissions.dart';
import '../../../data/services/voice_room_debug_log.dart';
import '../room_video_controller.dart';

/// Oda sahibi / admin / DJ için video kontrolleri (oynat, duraklat, kapat).
class RoomVideoOverlay extends ConsumerWidget {
  const RoomVideoOverlay({
    super.key,
    required this.roomKey,
    required this.perms,
    required this.isDj,
  });

  final String roomKey;
  final VoiceRoomPermissions perms;
  final bool isDj;

  bool get _canControl =>
      perms.isRoomOwner || perms.isSiteAdmin || perms.canManageDj || isDj;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final video = ref.watch(roomVideoControllerProvider(roomKey));
    if (!video.hasActiveVideo || !_canControl) {
      return const SizedBox.shrink();
    }

    final liveCtrl = ref.read(voiceRoomLiveProvider(roomKey).notifier);
    final videoCtrl = ref.read(roomVideoControllerProvider(roomKey).notifier);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final title = video.title?.trim();
    final label = title != null && title.isNotEmpty ? title : 'Video Müzik';

    return Positioned(
      left: 12,
      right: 12,
      top: MediaQuery.paddingOf(context).top + 56,
      child: IgnorePointer(
        ignoring: false,
        child: Material(
          color: Colors.black.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(
                  video.isPlaying ? Icons.music_video_rounded : Icons.pause_circle_outline,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _ControlIcon(
                  tooltip: video.isPlaying ? 'Duraklat' : 'Oynat',
                  icon: video.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  onTap: () {
                    VoiceRoomDebugLog.log('roomVideo.control', {
                      'room': roomKey,
                      'action': video.isPlaying ? 'pause' : 'play',
                    });
                    unawaited(
                      video.isPlaying
                          ? liveCtrl.pauseMusic()
                          : liveCtrl.resumeMusic(),
                    );
                  },
                ),
                _ControlIcon(
                  tooltip: 'Kapat',
                  icon: Icons.close_rounded,
                  color: const Color(0xFFFF6B6B),
                  onTap: () {
                    VoiceRoomDebugLog.log('roomVideo.control', {
                      'room': roomKey,
                      'action': 'close',
                    });
                    unawaited(() async {
                      final err = await liveCtrl.stopMusic();
                      if (err == null) videoCtrl.clear();
                    }());
                  },
                ),
                if (user != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      _roleLabel(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _roleLabel() {
    if (perms.isRoomOwner) return 'Sahip';
    if (perms.isSiteAdmin) return 'Admin';
    if (isDj || perms.canManageDj) return 'DJ';
    return '';
  }
}

class _ControlIcon extends StatelessWidget {
  const _ControlIcon({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      onPressed: onTap,
      icon: Icon(icon, color: color ?? Colors.white, size: 22),
    );
  }
}
