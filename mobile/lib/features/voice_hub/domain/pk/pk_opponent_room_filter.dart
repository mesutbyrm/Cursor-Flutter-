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
  final ownerId = room.ownerId?.trim() ?? '';
  if (ownerId.isEmpty) return false;
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
  final opponentId = battle.opponentId?.trim() ?? '';
  if (ownerId.isNotEmpty && opponentId.isNotEmpty && ownerId == opponentId) {
    return true;
  }
  final uid = userId?.trim() ?? '';
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
