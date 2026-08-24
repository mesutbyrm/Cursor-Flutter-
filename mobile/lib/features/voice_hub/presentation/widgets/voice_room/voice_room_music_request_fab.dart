import 'package:flutter/material.dart';

import '../../theme/voice_room_tokens.dart';

/// Sağ alt «Müzik İste» — yetersiz jetonda pasif görünür.
class VoiceRoomMusicRequestFab extends StatelessWidget {
  const VoiceRoomMusicRequestFab({
    super.key,
    required this.enabled,
    required this.active,
    required this.audioCost,
    this.onPressed,
  });

  /// Müzik sistemi odada açık mı.
  final bool enabled;

  /// Yeterli jeton veya staff bypass.
  final bool active;

  final int audioCost;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();

    return RepaintBoundary(
      child: Material(
        elevation: active ? 6 : 0,
        shadowColor: VoiceRoomTokens.gold.withValues(alpha: 0.4),
        color: active
            ? VoiceRoomTokens.gold.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: active ? onPressed : null,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.music_note_rounded,
                  size: 20,
                  color: active ? Colors.black87 : Colors.white38,
                ),
                const SizedBox(width: 6),
                Text(
                  'Müzik İste',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: active ? Colors.black87 : Colors.white38,
                  ),
                ),
                if (!active) ...[
                  const SizedBox(width: 4),
                  Text(
                    '$audioCost💎',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
