import 'package:flutter/material.dart';

import '../../theme/voice_room_tokens.dart';

/// Sohbet yukarı kaydırıldığında — «Yeni mesaj» atlama chip'i.
class VoiceRoomChatNewMessageChip extends StatelessWidget {
  const VoiceRoomChatNewMessageChip({
    super.key,
    required this.onTap,
    this.pendingCount = 0,
  });

  final VoidCallback onTap;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final label = pendingCount > 1 ? 'Yeni mesaj ($pendingCount)' : 'Yeni mesaj';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1035).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.65),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: VoiceRoomTokens.gold,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
