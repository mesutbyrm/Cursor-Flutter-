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

  /// Oda sahibi, site admin, kanal yetkilileri ve DJ odaya girince otomatik koltuk.
  static bool shouldAutoSit(int tier) =>
      tier >= tierOp || tier == tierDj;

  /// Sağ alt admin koltuğu (11) — admin oturabilsin diye her zaman görünür.
  static bool showAdminSeat(Map<int, ChatRoomPresence> seats) => true;

  static int? pickAutoSeatIndex({
    required int myTier,
    required List<ChatRoomPresence> presence,
    required VoiceRoomEntity room,
  }) {
    final occupied = <int, ChatRoomPresence>{
      for (final p in presence)
        if (p.seatIndex != null) p.seatIndex!: p,
    };

    if (myTier >= tierAdmin) {
      return _takeSeat(11, myTier, occupied, room);
    }
    if (myTier >= tierFounder) {
      return _takeSeat(1, myTier, occupied, room);
    }

    for (var seat = 2; seat <= 10; seat++) {
      final picked = _takeSeat(seat, myTier, occupied, room);
      if (picked != null) return picked;
    }
    return null;
  }

  static int? _takeSeat(
    int seat,
    int myTier,
    Map<int, ChatRoomPresence> occupied,
    VoiceRoomEntity room,
  ) {
    if (seat == 11 && myTier < tierAdmin) return null;
    final occupant = occupied[seat];
    if (occupant == null) return seat;
    if (myTier > forPresence(occupant, room)) return seat;
    return null;
  }
}
