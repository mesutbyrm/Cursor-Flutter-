import '../../../../core/network/pk_event_log.dart';

/// PK sırasında hangi TRTC oda kimliğine join olunacağı (çift yayın).
class LivePkTrtcAnchor {
  const LivePkTrtcAnchor({
    required this.trtcRoomId,
    required this.publishAsHost,
    this.expectedRemoteUserId,
    this.pkSessionId,
  });

  final String trtcRoomId;
  final bool publishAsHost;
  final String? expectedRemoteUserId;
  final String? pkSessionId;
}

String? _firstNonEmpty(Iterable<String?> values) {
  for (final raw in values) {
    final t = raw?.trim() ?? '';
    if (t.isNotEmpty) return t;
  }
  return null;
}

/// İki yayıncının aynı TRTC odasına girmesi için ortak oda kimliği.
///
/// `pkSessionId` / battle `id` oturum kimliğidir; TRTC oda adı değildir (bridge
/// `pkSessionId` = `effectiveId` yazıyor). Önce sunucunun TRTC/stream alanları.
String resolveSharedLivePkTrtcRoomId(Map<String, dynamic> battle) {
  return _firstNonEmpty([
        battle['trtcRoomId'],
        battle['pkRoomId'],
        battle['liveStreamId'],
        battle['hostStreamId'],
        battle['streamId'],
        battle['room1Id'],
        battle['unifiedMatchId'],
      ]) ??
      '';
}

String? _resolveOpponentUserId({
  required Map<String, dynamic> battle,
  required String myStreamId,
  String? myUserId,
}) {
  final sid = myStreamId.trim();
  final uid = myUserId?.trim() ?? '';
  final hostStream = (battle['liveStreamId'] ??
          battle['hostStreamId'] ??
          battle['streamId'])
      ?.toString()
      .trim() ??
      '';
  final opponentStream = (battle['opponentLiveStreamId'] ??
          battle['opponentStreamId'] ??
          battle['targetStreamId'])
      ?.toString()
      .trim() ??
      '';
  final challengerId =
      (battle['challengerId'] ?? battle['hostUserId'])?.toString().trim();
  final opponentId = (battle['opponentId'] ??
          battle['opponentUserId'] ??
          battle['targetUserId'])
      ?.toString()
      .trim();

  var amChallenger = false;
  if (sid.isNotEmpty && hostStream.isNotEmpty && sid == hostStream) {
    amChallenger = true;
  } else if (uid.isNotEmpty && challengerId != null && uid == challengerId) {
    amChallenger = true;
  }

  if (amChallenger) return opponentId;
  if (sid.isNotEmpty &&
      opponentStream.isNotEmpty &&
      sid == opponentStream &&
      challengerId != null &&
      challengerId.isNotEmpty) {
    return challengerId;
  }
  return opponentId ?? challengerId;
}

LivePkTrtcAnchor resolveLivePkTrtcAnchor({
  required Map<String, dynamic> battle,
  required String myStreamId,
  String? myUserId,
}) {
  final sharedRoom = resolveSharedLivePkTrtcRoomId(battle);
  final pkSessionId = _firstNonEmpty([
    battle['pkSessionId'],
    battle['id'],
    battle['battleId'],
    battle['pkBattleId'],
  ]);
  final remoteUserId = _resolveOpponentUserId(
    battle: battle,
    myStreamId: myStreamId,
    myUserId: myUserId,
  );

  if (sharedRoom.isNotEmpty) {
    PkEventLog.log('entering_room', {
      'trtcRoomId': sharedRoom,
      if (pkSessionId != null) 'pkSessionId': pkSessionId,
      if (remoteUserId != null) 'expectedRemoteUserId': remoteUserId,
    });
    return LivePkTrtcAnchor(
      trtcRoomId: sharedRoom,
      publishAsHost: true,
      expectedRemoteUserId: remoteUserId,
      pkSessionId: pkSessionId,
    );
  }

  final sid = myStreamId.trim();
  final hostStream = (battle['liveStreamId'] ??
          battle['hostStreamId'] ??
          battle['streamId'])
      ?.toString()
      .trim() ??
      '';
  final opponentStream = (battle['opponentLiveStreamId'] ??
          battle['opponentStreamId'] ??
          battle['targetStreamId'])
      ?.toString()
      .trim() ??
      '';
  final challengerId =
      (battle['challengerId'] ?? battle['hostUserId'])?.toString().trim();
  final opponentId = (battle['opponentId'] ??
          battle['opponentUserId'] ??
          battle['targetUserId'])
      ?.toString()
      .trim();

  var amChallenger = false;
  if (sid.isNotEmpty && hostStream.isNotEmpty && sid == hostStream) {
    amChallenger = true;
  } else if (myUserId != null &&
      myUserId.trim().isNotEmpty &&
      challengerId != null &&
      myUserId.trim() == challengerId) {
    amChallenger = true;
  }

  final anchorStream =
      hostStream.isNotEmpty ? hostStream : (sid.isNotEmpty ? sid : opponentStream);

  if (amChallenger) {
    return LivePkTrtcAnchor(
      trtcRoomId: anchorStream,
      publishAsHost: true,
      expectedRemoteUserId: opponentId,
      pkSessionId: pkSessionId,
    );
  }

  if (sid.isNotEmpty &&
      opponentStream.isNotEmpty &&
      sid == opponentStream &&
      anchorStream.isNotEmpty) {
    return LivePkTrtcAnchor(
      trtcRoomId: anchorStream,
      publishAsHost: true,
      expectedRemoteUserId: challengerId,
      pkSessionId: pkSessionId,
    );
  }

  return LivePkTrtcAnchor(
    trtcRoomId: anchorStream.isNotEmpty ? anchorStream : sid,
    publishAsHost: true,
    expectedRemoteUserId: opponentId,
    pkSessionId: pkSessionId,
  );
}

/// `POST /api/live/pk/score` — `side`: score1 | score2 | left | right
String livePkScoreSideForStream({
  required Map<String, dynamic> battle,
  required String myStreamId,
}) {
  final sid = myStreamId.trim();
  final hostStream = (battle['liveStreamId'] ?? battle['hostStreamId'])
          ?.toString()
          .trim() ??
      '';
  if (sid.isNotEmpty && hostStream.isNotEmpty && sid == hostStream) {
    return 'score1';
  }
  return 'score2';
}
