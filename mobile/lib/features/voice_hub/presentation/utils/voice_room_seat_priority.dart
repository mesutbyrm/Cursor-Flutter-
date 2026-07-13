import '../../../../core/auth/voice_staff_rank.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_my_permissions.dart';
import '../../domain/entities/chat_room_presence.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';

import 'voice_room_permissions.dart';

/// Koltuk önceliği: Admin > Kurucu > & > @ > + > V > Normal
abstract final class VoiceRoomSeatPriority {
  static const tierAdmin = 70;
  static const tierFounder = 60;
  static const tierSop = 50;
  static const tierOp = 40;
  static const tierVoice = 30;
  static const tierVip = 20;
  static const tierDj = 15;
  static const tierNormal = 0;

  static VoiceStaffRank _rankFromSymbol(String? symbol) {
    switch (symbol?.trim()) {
      case '%':
        return VoiceStaffRank.admin;
      case '~':
        return VoiceStaffRank.founder;
      case '&':
        return VoiceStaffRank.sop;
      case '@':
        return VoiceStaffRank.op;
      case '+':
        return VoiceStaffRank.voice;
      default:
        return VoiceStaffRank.none;
    }
  }

  static VoiceStaffRank _resolveRank({
    String? username,
    String? role,
    String? chatRole,
    String? roleSymbol,
  }) {
    final fromNick = VoiceStaffRankParser.resolve(
      username: username,
      role: role,
      chatRole: chatRole,
    );
    final fromSym = _rankFromSymbol(roleSymbol);
    if (VoiceStaffRankParser.powerLevel(fromSym) >
        VoiceStaffRankParser.powerLevel(fromNick)) {
      return fromSym;
    }
    return fromNick;
  }

  static int tierForRank(VoiceStaffRank rank) => switch (rank) {
        VoiceStaffRank.admin => tierAdmin,
        VoiceStaffRank.founder => tierFounder,
        VoiceStaffRank.sop => tierSop,
        VoiceStaffRank.op => tierOp,
        VoiceStaffRank.voice => tierVoice,
        VoiceStaffRank.none => tierNormal,
      };

  static int forPresence(ChatRoomPresence p, VoiceRoomEntity room) {
    if (p.chatRole == 'admin' || p.chatRole == 'superadmin') {
      return tierAdmin;
    }
    if (room.ownerId == p.id ||
        p.chatRole == 'owner' ||
        p.chatRole == 'founder') {
      return tierFounder;
    }
    if (room.djUserIds.contains(p.id) || p.chatRole == 'dj') {
      final base = tierForRank(
        _resolveRank(
          username: p.nickname ?? p.name,
          chatRole: p.chatRole,
          roleSymbol: p.roleSymbol,
        ),
      );
      return base > tierDj ? base : tierDj;
    }
    final rank = _resolveRank(
      username: p.nickname ?? p.name,
      chatRole: p.chatRole,
      roleSymbol: p.roleSymbol,
    );
    var tier = tierForRank(rank);
    if (tier <= tierNormal &&
        VipTier.fromMembership(p.membership).isVip) {
      tier = tierVip;
    }
    return tier;
  }

  static int forUser(
    UserEntity user, {
    required VoiceRoomEntity room,
    ChatRoomPresence? self,
    ChatRoomMyPermissions? server,
  }) {
    final perms = VoiceRoomPermissions.forUser(
      user: user,
      room: room,
      selfPresence: self,
      server: server,
    );
    if (server?.isGlobalAdmin == true || perms.isSiteAdmin) {
      return tierAdmin;
    }
    if (server?.isRoomOwner == true || perms.isRoomOwner) {
      return tierFounder;
    }
    final rank = _resolveRank(
      username: user.username,
      role: user.role,
      chatRole: self?.chatRole ?? server?.role,
      roleSymbol: self?.roleSymbol,
    );
    var tier = tierForRank(rank);
    if (room.djUserIds.contains(user.id) ||
        self?.chatRole == 'dj' ||
        perms.canManageDj) {
      tier = tier > tierDj ? tier : tierDj;
    }
    if (tier <= tierNormal &&
        VipTier.fromMembership(self?.membership).isVip) {
      tier = tierVip;
    }
    return tier;
  }

  /// Oda sahibi, site admin, kanal yetkilileri, sesli yetkili ve DJ otomatik koltuk.
  static bool shouldAutoSit(int tier) =>
      tier >= tierVoice || tier == tierDj;

  /// Sağ alt admin koltuğu (11) — admin oturabilsin diye her zaman görünür.
  static bool showAdminSeat(Map<int, ChatRoomPresence> seats) => true;

  static int? pickAutoSeatIndex({
    required int myTier,
    required List<ChatRoomPresence> presence,
    required VoiceRoomEntity room,
  }) {
    if (room.id.trim().isEmpty && room.slug.trim().isEmpty) return null;
    final occupied = <int, ChatRoomPresence>{
      for (final p in presence)
        if (p.seatIndex != null) p.seatIndex!: p,
    };

    // En düşük numaralı boş koltuk — backend transaction/lock ile doğrular.
    for (var seat = 1; seat <= 10; seat++) {
      if (!occupied.containsKey(seat)) return seat;
    }
    // Admin koltuğu görünürse ve boşsa en son seçenek olarak kullanılabilir.
    if (myTier >= tierAdmin && !occupied.containsKey(11)) {
      return 11;
    }
    return null;
  }
}
