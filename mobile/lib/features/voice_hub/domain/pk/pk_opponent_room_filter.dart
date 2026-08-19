import '../../../live/domain/entities/voice_room_entity.dart';
import 'pk_battle_remote_models.dart';

/// PK daveti için rakip oda — boş odalar ve sahipsiz odalar hariç.
List<VoiceRoomEntity> filterPkEligibleOpponentRooms(
  List<VoiceRoomEntity> rooms, {
  String? excludeRoomKey,
}) {
  final exclude = excludeRoomKey?.trim() ?? '';
  return rooms.where((r) => isPkEligibleOpponentRoom(r, excludeRoomKey: exclude)).toList()
    ..sort((a, b) => b.displayOnline.compareTo(a.displayOnline));
}

bool isPkEligibleOpponentRoom(
  VoiceRoomEntity room, {
  required String excludeRoomKey,
}) {
  final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
  if (key.isEmpty) return false;
  if (excludeRoomKey.isNotEmpty && key == excludeRoomKey) return false;
  if (room.displayOnline <= 0) return false;
  // ownerId boş olsa bile davet anında presence'tan çözülür.
  return true;
}

bool isPkChallengerRoom(PkBattleRemote battle, VoiceRoomEntity room) {
  final keys = {room.apiRoomKey, room.id, room.slug}
      .where((k) => k.trim().isNotEmpty)
      .map((k) => k.trim().toLowerCase())
      .toSet();
  final challengerRoom = battle.voiceRoomId?.trim().toLowerCase() ?? '';
  return challengerRoom.isNotEmpty && keys.contains(challengerRoom);
}

/// Gelen PK daveti bu oda sahibine mi ait?
bool isPkInviteTarget(
  PkBattleRemote battle,
  VoiceRoomEntity room, {
  String? userId,
}) {
  if (!battle.isPending) return false;

  final keys = {room.apiRoomKey, room.id, room.slug}
      .where((k) => k.trim().isNotEmpty)
      .map((k) => k.trim().toLowerCase())
      .toSet();

  bool roomMatches(String? raw) {
    final v = raw?.trim().toLowerCase() ?? '';
    return v.isNotEmpty && keys.contains(v);
  }

  if (roomMatches(battle.opponentVoiceRoomId)) return true;

  final ownerId = room.ownerId?.trim() ?? '';
  final uid = userId?.trim() ?? '';
  final opponentId = battle.opponentId?.trim() ?? '';
  if (ownerId.isNotEmpty && opponentId.isNotEmpty && ownerId == opponentId) {
    return true;
  }
  final targetUserId = battle.targetUserId?.trim() ?? '';
  if (targetUserId.isNotEmpty) {
    if (uid.isNotEmpty && uid == targetUserId) return true;
    if (ownerId.isNotEmpty && ownerId == targetUserId) return true;
  }
  final guestUserId = battle.guestUserId?.trim() ?? '';
  if (guestUserId.isNotEmpty) {
    if (uid.isNotEmpty && uid == guestUserId) return true;
    if (ownerId.isNotEmpty && ownerId == guestUserId) return true;
  }
  if (uid.isNotEmpty && opponentId.isNotEmpty && uid == opponentId) {
    return true;
  }
  final oppUser = battle.opponent?.userId.trim() ?? '';
  if (uid.isNotEmpty && oppUser.isNotEmpty && uid == oppUser) {
    return true;
  }
  if (ownerId.isNotEmpty && oppUser.isNotEmpty && ownerId == oppUser) {
    return true;
  }
  if (roomMatches(battle.opponent?.roomId)) return true;

  // Challenger odası değilsek ve oda sahibiysek: hedef biziz (alanlar eksik gelse bile).
  if (!isPkChallengerRoom(battle, room) &&
      uid.isNotEmpty &&
      ownerId.isNotEmpty &&
      uid == ownerId) {
    return true;
  }
  return false;
}

/// Menüde PK savaş ekranına gitmek için gerçekten aktif savaş var mı?
bool isPkBattleLive(PkBattleRemote? battle) =>
    battle != null && battle.isActive && !battle.isEnded;

/// PK kaydı bu sesli odaya ait mi (skor şeridi / SSE senkronu için).
/// Gelen PK daveti hangi odaya gösterilecek — aktif oda öncelikli.
VoiceRoomEntity? pickPkInviteTargetRoom({
  required PkBattleRemote battle,
  required String userId,
  required List<VoiceRoomEntity> rooms,
  VoiceRoomEntity? activeRoom,
}) {
  if (userId.isEmpty || !battle.isPending) return null;

  if (activeRoom != null &&
      isPkInviteTarget(battle, activeRoom, userId: userId)) {
    return activeRoom;
  }

  final owned = rooms
      .where((r) => (r.ownerId?.trim() ?? '') == userId)
      .toList(growable: false);

  final candidates = <VoiceRoomEntity>[
    if (activeRoom != null) activeRoom,
    ...owned,
  ];

  final oppRoomId = battle.opponentVoiceRoomId?.trim() ?? '';
  if (oppRoomId.isNotEmpty) {
    for (final r in rooms) {
      if (r.apiRoomKey == oppRoomId ||
          r.id == oppRoomId ||
          r.slug == oppRoomId) {
        candidates.add(r);
      }
    }
  }

  final seen = <String>{};
  for (final room in candidates) {
    final k = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    if (k.isEmpty || !seen.add(k)) continue;
    if (isPkInviteTarget(battle, room, userId: userId)) return room;
  }

  for (final room in rooms) {
    final k = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    if (k.isEmpty || !seen.add(k)) continue;
    if (isPkInviteTarget(battle, room, userId: userId)) return room;
  }
  return null;
}

bool pkBattleBelongsToRoom(PkBattleRemote battle, VoiceRoomEntity room) {
  final keys = {room.apiRoomKey, room.id, room.slug}
      .where((k) => k.trim().isNotEmpty)
      .map((k) => k.trim().toLowerCase())
      .toSet();

  bool matches(String? raw) {
    final v = raw?.trim().toLowerCase() ?? '';
    return v.isNotEmpty && keys.contains(v);
  }

  return matches(battle.voiceRoomId) ||
      matches(battle.opponentVoiceRoomId) ||
      matches(battle.challenger?.roomId) ||
      matches(battle.opponent?.roomId);
}
