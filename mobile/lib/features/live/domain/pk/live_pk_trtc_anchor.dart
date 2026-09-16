/// PK sırasında hangi TRTC oda kimliğine join olunacağı (çift yayın).
class LivePkTrtcAnchor {
  const LivePkTrtcAnchor({
    required this.trtcRoomId,
    required this.publishAsHost,
    this.expectedRemoteUserId,
  });

  final String trtcRoomId;
  final bool publishAsHost;
  final String? expectedRemoteUserId;
}

LivePkTrtcAnchor resolveLivePkTrtcAnchor({
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

  final anchorStream =
      hostStream.isNotEmpty ? hostStream : (sid.isNotEmpty ? sid : opponentStream);

  if (amChallenger) {
    return LivePkTrtcAnchor(
      trtcRoomId: anchorStream,
      publishAsHost: true,
      expectedRemoteUserId: opponentId,
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
    );
  }

  return LivePkTrtcAnchor(
    trtcRoomId: sid.isNotEmpty ? sid : anchorStream,
    publishAsHost: true,
    expectedRemoteUserId: opponentId,
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
