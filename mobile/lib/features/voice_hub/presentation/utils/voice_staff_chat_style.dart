import 'package:flutter/material.dart';

import '../../../../core/auth/voice_staff_rank.dart';
import '../../domain/entities/chat_room_message.dart';
import '../theme/voice_room_tokens.dart';

/// Faz 8 — yetkili sohbet renkleri ve neon metin.
abstract final class VoiceStaffChatStyle {
  static bool isStaffUser(ChatRoomUserRef? user) {
    if (user == null) return false;
    final symbol = user.roleSymbol?.trim();
    if (symbol == '%' ||
        symbol == '~' ||
        symbol == '&' ||
        symbol == '@' ||
        symbol == '+') {
      return true;
    }
    final role = user.chatRole?.toLowerCase() ?? '';
    if (role == 'admin' ||
        role == 'superadmin' ||
        role == 'founder' ||
        role == 'owner' ||
        role == 'sop' ||
        role == 'moderator' ||
        role == 'mod' ||
        role == 'op' ||
        role == 'dj') {
      return true;
    }
    final rank = rankOf(user);
    return VoiceStaffRankParser.powerLevel(rank) >=
        VoiceStaffRankParser.powerLevel(VoiceStaffRank.voice);
  }

  static VoiceStaffRank rankOf(ChatRoomUserRef? user) {
    if (user == null) return VoiceStaffRank.none;
    if (user.chatRole == 'dj') return VoiceStaffRank.op;
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

  static Color accentForUser(ChatRoomUserRef? user) {
    if (user == null) return VoiceRoomTokens.neonPurple;
    if (user.chatRole == 'dj') return VoiceRoomTokens.neonPink;
    return accentFor(rankOf(user));
  }

  static List<Color> ringGradient(VoiceStaffRank rank) {
    final c = accentFor(rank);
    return [
      c,
      Color.lerp(c, VoiceRoomTokens.neonPurple, 0.45)!,
      Color.lerp(c, VoiceRoomTokens.neonPink, 0.35)!,
      Colors.white.withValues(alpha: 0.85),
    ];
  }

  /// Hafif ışık — okunaklı kalsın diye siyah halo ile.
  static List<Shadow> nameGlow(Color color) => [
        const Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1)),
        Shadow(color: color.withValues(alpha: 0.9), blurRadius: 12),
        Shadow(color: color.withValues(alpha: 0.5), blurRadius: 20),
      ];

  static List<Shadow> bodyGlow(Color color) => [
        const Shadow(color: Colors.black87, blurRadius: 5, offset: Offset(0, 1)),
        Shadow(color: color.withValues(alpha: 0.4), blurRadius: 8),
      ];

  /// Faz 9 — koltuk altı giriş animasyonu metni: «👑 Admin Mesut odaya giriş yaptı».
  static String entryRoleLabel(ChatRoomUserRef? user) {
    if (user?.chatRole == 'dj') return 'DJ';
    return switch (rankOf(user)) {
      VoiceStaffRank.admin => 'Admin',
      VoiceStaffRank.founder => 'Kurucu',
      VoiceStaffRank.sop => 'SOP',
      VoiceStaffRank.op => 'Mod',
      VoiceStaffRank.voice => 'Voice',
      VoiceStaffRank.none => 'Yetkili',
    };
  }

  static String entryEmoji(ChatRoomUserRef? user) {
    if (user?.chatRole == 'dj') return '🎧';
    return switch (rankOf(user)) {
      VoiceStaffRank.admin => '👑',
      VoiceStaffRank.founder => '🏛️',
      VoiceStaffRank.sop => '⭐',
      VoiceStaffRank.op => '🛡️',
      VoiceStaffRank.voice => '🎤',
      VoiceStaffRank.none => '✨',
    };
  }

  static String formatStaffEntryLine(String name, {ChatRoomUserRef? user}) {
    final clean = name.trim();
    final displayName =
        clean.isEmpty ? 'Kullanıcı' : (clean.length > 28 ? '${clean.substring(0, 26)}…' : clean);
    return '${entryEmoji(user)} ${entryRoleLabel(user)} $displayName odaya giriş yaptı';
  }

  /// Yetkili giriş animasyonu — VIP/Gold hariç.
  static bool isStaffEntry({
    required String content,
    ChatRoomUserRef? user,
  }) {
    if (user != null && isStaffUser(user)) return true;
    final raw = content.trim();
    if (raw.isEmpty) return false;
    if (raw.startsWith('[SYSTEM_VIP_JOIN:')) return false;
    final upper = raw.toUpperCase();
    if (upper.contains(' VIP ') || upper.startsWith('VIP ')) return false;
    if (upper.contains(' GOLD ') || upper.startsWith('GOLD ')) return false;
    if (raw.startsWith('%') ||
        raw.startsWith('~') ||
        raw.startsWith('&') ||
        raw.startsWith('@') ||
        raw.startsWith('+')) {
      return true;
    }
    final role = user?.chatRole?.toLowerCase() ?? '';
    if (role == 'admin' ||
        role == 'superadmin' ||
        role == 'founder' ||
        role == 'owner' ||
        role == 'sop' ||
        role == 'moderator' ||
        role == 'mod' ||
        role == 'op' ||
        role == 'dj') {
      return true;
    }
    return upper.contains('ADMIN') ||
        upper.contains('MODERATOR') ||
        upper.contains('MODERAT') ||
        upper.contains('KURUCU') ||
        upper.contains('FOUNDER') ||
        upper.contains('STAFF') ||
        upper.contains('YETKİLİ') ||
        upper.contains('YETKILI');
  }
}
