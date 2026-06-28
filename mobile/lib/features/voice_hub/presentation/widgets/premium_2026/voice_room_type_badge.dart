import 'package:flutter/material.dart';

import 'package:canlifal_social/features/vip_gold/domain/voice_room_access.dart';
import 'package:canlifal_social/features/vip_gold/presentation/theme/vip_gold_tokens.dart';

import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../theme/voice_room_tokens.dart';

/// Oda tipi rozeti — FREE / NORMAL / VIP (mevcut `roomType` alanından).
class VoiceRoomTypeBadge extends StatelessWidget {
  const VoiceRoomTypeBadge({
    super.key,
    required this.roomType,
    this.compact = false,
  });

  factory VoiceRoomTypeBadge.fromRoom(VoiceRoomEntity room) {
    return VoiceRoomTypeBadge(roomType: room.resolvedRoomType);
  }

  final String roomType;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (roomType.toUpperCase()) {
      'FREE' => ('Ücretsiz', const Color(0xFF22C55E), Icons.mic_rounded),
      'VIP' => ('VIP', VipGoldTokens.goldMid, Icons.workspace_premium_rounded),
      _ => ('Normal', VoiceRoomTokens.neonBlue, Icons.diamond_outlined),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 10 : 12, color: color),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: compact ? 9 : 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
