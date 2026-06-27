/// canlifal.com sesli oda yetki hiyerarşisi (nick öneki).
///
/// Güç: % superadmin (5) > ~ founder (4) > & sop (3) > @ op (2) > + voice (1) > none (0).
enum VoiceStaffRank {
  admin,
  founder,
  sop,
  op,
  voice,
  none,
}

abstract final class VoiceStaffRankParser {
  static VoiceStaffRank fromUsername(String? username) {
    final n = (username ?? '').trim();
    if (n.isEmpty) return VoiceStaffRank.none;
    if (n.startsWith('%')) return VoiceStaffRank.admin;
    if (n.startsWith('~')) return VoiceStaffRank.founder;
    if (n.startsWith('&')) return VoiceStaffRank.sop;
    if (n.startsWith('@')) return VoiceStaffRank.op;
    if (n.startsWith('+')) return VoiceStaffRank.voice;
    final lower = n.toLowerCase();
    if (lower == 'admin' ||
        lower == 'destek' ||
        lower == 'moderator' ||
        lower == 'yonetici') {
      return VoiceStaffRank.admin;
    }
    return VoiceStaffRank.none;
  }

  static VoiceStaffRank fromRole(String? role) {
    final r = (role ?? '').toLowerCase();
    if (r == 'superadmin' || r == 'site_manager') return VoiceStaffRank.admin;
    if (r == 'founder' || r == 'owner') return VoiceStaffRank.founder;
    if (r == 'sop') return VoiceStaffRank.sop;
    if (r == 'op' || r == 'moderator') return VoiceStaffRank.op;
    if (r == 'admin') return VoiceStaffRank.admin;
    if (r == 'voice') return VoiceStaffRank.voice;
    return VoiceStaffRank.none;
  }

  static VoiceStaffRank resolve({
    String? username,
    String? role,
    String? chatRole,
  }) {
    final nick = fromUsername(username);
    if (nick != VoiceStaffRank.none) return nick;
    final cr = fromRole(chatRole);
    if (cr != VoiceStaffRank.none) return cr;
    return fromRole(role);
  }

  static int powerLevel(VoiceStaffRank rank) => switch (rank) {
        VoiceStaffRank.admin => 5,
        VoiceStaffRank.founder => 4,
        VoiceStaffRank.sop => 3,
        VoiceStaffRank.op => 2,
        VoiceStaffRank.voice => 1,
        VoiceStaffRank.none => 0,
      };

  static String? prefixSymbol(VoiceStaffRank rank) => switch (rank) {
        VoiceStaffRank.admin => '%',
        VoiceStaffRank.founder => '~',
        VoiceStaffRank.sop => '&',
        VoiceStaffRank.op => '@',
        VoiceStaffRank.voice => '+',
        VoiceStaffRank.none => null,
      };

  static String displayPrefix(VoiceStaffRank rank) => switch (rank) {
        VoiceStaffRank.admin => 'Süper Admin',
        VoiceStaffRank.founder => 'Kurucu',
        VoiceStaffRank.sop => 'SOP',
        VoiceStaffRank.op => 'OP',
        VoiceStaffRank.voice => 'Ses',
        VoiceStaffRank.none => '',
      };

  static bool canModerate(VoiceStaffRank rank) =>
      powerLevel(rank) >= powerLevel(VoiceStaffRank.op);

  static bool hasFullRoomControl(VoiceStaffRank rank) =>
      powerLevel(rank) >= powerLevel(VoiceStaffRank.admin);

  static bool isStaffEntrance(VoiceStaffRank rank) =>
      powerLevel(rank) >= powerLevel(VoiceStaffRank.admin);
}
