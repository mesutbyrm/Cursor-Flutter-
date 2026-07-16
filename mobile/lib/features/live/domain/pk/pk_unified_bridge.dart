import '../../../../core/util/json_util.dart';
import '../../../voice_hub/domain/pk/pk_battle_remote_models.dart';
import 'pk_room_models.dart';
import 'live_pk_invite_helper.dart';

/// `PkRoomMatch` → `PkBattleRemote` (sesli/canlı PK ekranları için).
PkBattleRemote pkRoomMatchToBattleRemote(
  PkRoomMatch match, {
  String? myStreamId,
}) {
  final leftSeats = match.seats.where((s) => s.isLeft && s.isOccupied);
  final rightSeats = match.seats.where((s) => s.isRight && s.isOccupied);
  final leftSeat = leftSeats.isNotEmpty ? leftSeats.first : null;
  final rightSeat = rightSeats.isNotEmpty ? rightSeats.first : null;

  return PkBattleRemote(
    id: match.id,
    battleType: 'live_stream',
    status: match.status,
    challengerScore: match.leftScore,
    opponentScore: match.rightScore,
    secondsLeft: match.remainingSec,
    durationSeconds: match.durationSec,
    targetScore: 150000,
    liveStreamId: match.hostStreamId ?? leftSeat?.streamId,
    opponentLiveStreamId: rightSeat?.streamId,
    challengerId: leftSeat?.userId ?? match.hostUserId,
    opponentId: rightSeat?.userId,
    challenger: leftSeat != null
        ? PkParticipantRemote(
            userId: leftSeat.userId ?? '',
            displayName: leftSeat.displayName ?? match.leftName,
            score: leftSeat.score,
          )
        : PkParticipantRemote(
            userId: match.hostUserId ?? '',
            displayName: match.leftName,
            score: match.leftScore,
          ),
    opponent: rightSeat != null
        ? PkParticipantRemote(
            userId: rightSeat.userId ?? '',
            displayName: rightSeat.displayName ?? match.rightName,
            score: rightSeat.score,
          )
        : PkParticipantRemote(
            userId: '',
            displayName: match.rightName,
            score: match.rightScore,
          ),
    result: match.isCompleted
        ? PkResultRemote(
            winnerSide: match.winnerSide,
            challengerFinalScore: match.leftScore,
            opponentFinalScore: match.rightScore,
          )
        : null,
  );
}

/// Birleşik `PkRoomMatch` → eski canlı yayın PK haritası (`liveVideoPkProvider`).
Map<String, dynamic> pkRoomMatchToBattleMap(
  PkRoomMatch match, {
  String? myStreamId,
  String? myUserId,
}) {
  final leftSeat = match.seats.where((s) => s.isLeft && s.isOccupied).toList();
  final hostOnLeft = match.hostStreamId == null ||
      match.hostStreamId == myStreamId ||
      leftSeat.any((s) => s.streamId == myStreamId);

  final isOpponent = match.isPending &&
      isLivePkInviteRecipient(
        match,
        myStreamId: myStreamId?.trim() ?? '',
        myUserId: myUserId,
      );

  return {
    'id': match.id,
    'status': match.status,
    'mode': match.mode.wire,
    'score1': match.leftScore,
    'score2': match.rightScore,
    'leftScore': match.leftScore,
    'rightScore': match.rightScore,
    'challengerScore': match.leftScore,
    'opponentScore': match.rightScore,
    'secondsLeft': match.remainingSec,
    'durationSeconds': match.durationSec,
    'durationSec': match.durationSec,
    'winnerSide': match.winnerSide,
    'leftName': match.leftName,
    'rightName': match.rightName,
    'hostStreamId': match.hostStreamId,
    'opponentStreamId': match.opponentStreamId,
    'opponentUserId': match.opponentUserId,
    'opponentId': match.opponentUserId,
    'isOpponent': isOpponent,
    'hostOnLeft': hostOnLeft,
    'seats': [for (final s in match.seats) _seatToJson(s)],
    'unifiedPk': true,
  };
}

Map<String, dynamic> _seatToJson(PkSeat s) => {
      'seatIndex': s.seatIndex,
      'userId': s.userId,
      'team': s.team,
      'score': s.score,
      'status': s.status,
      'displayName': s.displayName,
      'avatarUrl': s.avatarUrl,
      'streamId': s.streamId,
      'isHost': s.isHost,
    };

/// Aktif maç listesinden bir yayına ait 1v1 PK'yı bul.
PkRoomMatch? findStreamPkMatch(
  List<PkRoomMatch> matches,
  String streamId, {
  PkRoomMode? mode,
}) {
  final sid = streamId.trim();
  if (sid.isEmpty) return null;
  for (final m in matches) {
    if (mode != null && m.mode != mode) continue;
    if (m.hostStreamId == sid) return m;
    if (m.opponentStreamId == sid) return m;
    if (m.seats.any((s) => s.streamId == sid)) return m;
  }
  return null;
}

/// API yanıtından maç listesi çıkar.
List<PkRoomMatch> parsePkMatchList(dynamic raw) {
  if (raw is Map) {
    raw = asJsonMap(raw)['matches'] ??
        asJsonMap(raw)['invites'] ??
        asJsonMap(raw)['data'] ??
        asJsonMap(raw)['items'];
  }
  if (raw is! List) return const [];
  final out = <PkRoomMatch>[];
  for (final e in raw) {
    if (e is Map) out.add(PkRoomMatch.fromJson(asJsonMap(e)));
  }
  return out;
}
