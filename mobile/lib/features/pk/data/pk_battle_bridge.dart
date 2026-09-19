import '../../live/domain/pk/live_pk_invite_helper.dart';
import '../../live/domain/pk/pk_unified_bridge.dart';
import '../../voice_hub/domain/pk/pk_battle_remote_models.dart';
import 'pk_models.dart';

/// `PkBattle` → mevcut `liveVideoPkProvider` haritası.
Map<String, dynamic> pkBattleToLiveMap(
  PkBattle battle, {
  String? myContextId,
  String? myUserId,
}) {
  final remote = pkBattleToRemote(battle);
  return pkBattleRemoteToBattleMap(
    remote,
    myStreamId: myContextId,
    myUserId: myUserId,
  );
}

/// `PkBattleRemote` (chat-room/voice PK datasource) → sheet'in `PkBattle`'ı.
/// Sesli oda daveti kılavuz §9.3 `POST /api/chat/rooms/{id}/pk` üzerinden gider;
/// dönen model `PkBattleRemote`, sheet ise `PkBattle` beklediği için köprü.
PkBattle pkRemoteToBattle(PkBattleRemote r) {
  final u1 = r.challenger;
  final u2 = r.opponent;
  return PkBattle(
    id: r.effectiveId,
    status: PkStatus.parse(r.status),
    room1Id: r.voiceRoomId ?? r.liveStreamId ?? '',
    room2Id: r.opponentVoiceRoomId ?? r.opponentLiveStreamId ?? '',
    user1Id: r.challengerId ?? u1?.userId ?? '',
    user2Id: r.opponentId ?? r.targetUserId ?? r.guestUserId ?? u2?.userId ?? '',
    score1: r.challengerScore,
    score2: r.opponentScore,
    duration: r.durationSeconds,
    startedAt: r.startedAt?.toIso8601String() ?? '',
    endsAt: r.endsAt?.toIso8601String() ?? '',
    winnerId: r.winnerId ?? '',
    user1: u1 != null
        ? PkParticipant(id: u1.userId, name: u1.displayName ?? '')
        : null,
    user2: u2 != null
        ? PkParticipant(id: u2.userId, name: u2.displayName ?? '')
        : null,
  );
}

PkBattleRemote pkBattleToRemote(PkBattle battle) {
  final endsAt = DateTime.tryParse(battle.endsAt);
  final startedAt = DateTime.tryParse(battle.startedAt);
  final u1 = battle.user1;
  final u2 = battle.user2;
  return PkBattleRemote(
    id: battle.id,
    battleType: 'live_stream',
    status: battle.status == PkStatus.unknown ? 'pending' : battle.status.name,
    challengerScore: battle.score1,
    opponentScore: battle.score2,
    secondsLeft: battle.remainingBattle(Duration.zero)?.inSeconds ?? battle.duration,
    durationSeconds: battle.duration,
    targetScore: 150000,
    liveStreamId: battle.room1Id,
    opponentLiveStreamId: battle.room2Id,
    challengerId: battle.user1Id,
    opponentId: battle.user2Id,
    challenger: u1 != null
        ? PkParticipantRemote(
            userId: u1.id,
            displayName: u1.name,
            score: battle.score1,
          )
        : null,
    opponent: u2 != null
        ? PkParticipantRemote(
            userId: u2.id,
            displayName: u2.name,
            score: battle.score2,
          )
        : null,
    endsAt: endsAt,
    startedAt: startedAt,
    winnerId: battle.winnerId.isEmpty ? null : battle.winnerId,
    result: battle.status == PkStatus.completed
        ? PkResultRemote(
            winnerId: battle.winnerId.isEmpty ? null : battle.winnerId,
            winnerSide: battle.isDraw
                ? null
                : (battle.winnerId == battle.user1Id ? 'left' : 'right'),
            challengerFinalScore: battle.score1,
            opponentFinalScore: battle.score2,
          )
        : null,
  );
}

bool isPkBattleRecipient(
  PkBattle battle, {
  required String? myUserId,
  String? myContextId,
}) {
  return isLivePkInviteRecipientMap(
    pkBattleToLiveMap(battle, myContextId: myContextId, myUserId: myUserId),
    myStreamId: myContextId ?? '',
    myUserId: myUserId,
  );
}
