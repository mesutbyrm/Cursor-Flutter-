/// canlifal.com sesli oda yetki hiyerarşisi (nick öneki).
///
/// Güç sırası: founder (~) > sop (&) > op (@) > admin (%) > oda sahibi > dj.
enum VoiceStaffRank {
  founder,
  sop,
  op,
  admin,
  none,
}

abstract final class VoiceStaffRankParser {
  static VoiceStaffRank fromUsername(String? username) {
    final n = (username ?? '').trim();
    if (n.isEmpty) return VoiceStaffRank.none;
    if (n.startsWith('~')) return VoiceStaffRank.founder;
    if (n.startsWith('&')) return VoiceStaffRank.sop;
    if (n.startsWith('@')) return VoiceStaffRank.op;
    if (n.startsWith('%')) return VoiceStaffRank.admin;
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
    if (r == 'founder' || r == 'superadmin') return VoiceStaffRank.founder;
    if (r == 'sop') return VoiceStaffRank.sop;
    if (r == 'op' || r == 'moderator') return VoiceStaffRank.op;
    if (r == 'admin') return VoiceStaffRank.admin;
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
        VoiceStaffRank.founder => 100,
        VoiceStaffRank.sop => 80,
        VoiceStaffRank.op => 60,
        VoiceStaffRank.admin => 50,
        VoiceStaffRank.none => 0,
      };

  static String? prefixSymbol(VoiceStaffRank rank) => switch (rank) {
        VoiceStaffRank.founder => '~',
        VoiceStaffRank.sop => '&',
        VoiceStaffRank.op => '@',
        VoiceStaffRank.admin => '%',
        VoiceStaffRank.none => null,
      };

  static String displayPrefix(VoiceStaffRank rank) => switch (rank) {
        VoiceStaffRank.founder => 'Kurucu',
        VoiceStaffRank.sop => 'SOP',
        VoiceStaffRank.op => 'OP',
        VoiceStaffRank.admin => 'Admin',
        VoiceStaffRank.none => '',
      };

  static bool canModerate(VoiceStaffRank rank) =>
      powerLevel(rank) >= powerLevel(VoiceStaffRank.op);

  static bool hasFullRoomControl(VoiceStaffRank rank) =>
      powerLevel(rank) >= powerLevel(VoiceStaffRank.admin);

  static bool isStaffEntrance(VoiceStaffRank rank) =>
      powerLevel(rank) >= powerLevel(VoiceStaffRank.admin);
}
