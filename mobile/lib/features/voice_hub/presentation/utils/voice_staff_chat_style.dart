import 'package:flutter/material.dart';

import '../../../../core/auth/voice_staff_rank.dart';
import '../../domain/entities/chat_room_message.dart';
import '../theme/voice_room_tokens.dart';

/// Faz 8 — yetkili sohbet renkleri ve neon metin.
abstract final class VoiceStaffChatStyle {
  static bool isStaffUser(ChatRoomUserRef? user) {
    if (user == null) return false;
    final role = user.chatRole?.toLowerCase() ?? '';
    if (role == 'admin' ||
        role == 'superadmin' ||
        role == 'founder' ||
        role == 'owner' ||
        role == 'sop' ||
        role == 'moderator' ||
        role == 'op' ||
        role == 'dj') {
      return true;
    }
    final rank = VoiceStaffRankParser.resolve(
      username: user.nickname ?? user.name,
      chatRole: user.chatRole,
    );
    return VoiceStaffRankParser.powerLevel(rank) >=
        VoiceStaffRankParser.powerLevel(VoiceStaffRank.op);
  }

  static VoiceStaffRank rankOf(ChatRoomUserRef? user) {
    if (user == null) return VoiceStaffRank.none;
    final symbol = user.roleSymbol?.trim();
    if (symbol == '%') return VoiceStaffRank.admin;
    if (symbol == '~') return VoiceStaffRank.founder;
    if (symbol == '&') return VoiceStaffRank.sop;
    if (symbol == '@') return VoiceStaffRank.op;
    if (symbol == '+') return VoiceStaffRank.voice;
    return user.staffRank;
  }

  static Color accentFor(VoiceStaffRank rank) => switch (rank) {
        VoiceStaffRank.admin => VoiceRoomTokens.gold,
        VoiceStaffRank.founder => const Color(0xFFFF6B35),
        VoiceStaffRank.sop => const Color(0xFFFF6B35),
        VoiceStaffRank.op => VoiceRoomTokens.neonBlue,
        VoiceStaffRank.voice => const Color(0xFF22C55E),
        VoiceStaffRank.none => VoiceRoomTokens.neonPurple,
      };

  static List<Color> ringGradient(VoiceStaffRank rank) {
    final c = accentFor(rank);
    return [
      c,
      Color.lerp(c, VoiceRoomTokens.neonPurple, 0.45)!,
      Color.lerp(c, VoiceRoomTokens.neonPink, 0.35)!,
    ];
  }

  static List<Shadow> nameGlow(Color color) => [
        Shadow(color: color.withValues(alpha: 0.85), blurRadius: 10),
        Shadow(color: color.withValues(alpha: 0.45), blurRadius: 18),
        const Shadow(color: Colors.black87, blurRadius: 4),
      ];

  static List<Shadow> bodyGlow(Color color) => [
        Shadow(color: color.withValues(alpha: 0.35), blurRadius: 6),
        const Shadow(color: Colors.black87, blurRadius: 5),
      ];
}
