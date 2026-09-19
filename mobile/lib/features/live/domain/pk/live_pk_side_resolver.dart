/// PK split ekranı — sol/sağ yayıncı bilgisi (backend battle map).
class LivePkPaneModel {
  const LivePkPaneModel({
    required this.label,
    this.avatarUrl,
    this.streamId,
    this.userId,
    this.isLocalPane = false,
  });

  final String label;
  final String? avatarUrl;
  final String? streamId;
  final String? userId;
  final bool isLocalPane;
}

class LivePkSplitLayout {
  const LivePkSplitLayout({required this.left, required this.right});

  final LivePkPaneModel left;
  final LivePkPaneModel right;
}

/// `iAmChallenger` yalnızca güvenle belirlenebiliyorsa döner (aksi halde null).
/// Battle verisi (hostStream / challengerId) parça parça geldiği için, bu
/// değer bilinene kadar taraf kararı ertelenmeli; aksi halde ekran titrer.
bool? resolveIAmChallengerConfident({
  required Map<String, dynamic>? battle,
  required String myStreamId,
  String? myUserId,
}) {
  final b = battle ?? const <String, dynamic>{};
  final sid = myStreamId.trim();
  final uid = myUserId?.trim() ?? '';
  final hostStream =
      (b['liveStreamId'] ?? b['hostStreamId'])?.toString().trim() ?? '';
  final challengerId =
      (b['challengerId'] ?? b['hostUserId'])?.toString().trim() ?? '';
  if (sid.isNotEmpty && hostStream.isNotEmpty) {
    return sid == hostStream;
  }
  if (uid.isNotEmpty && challengerId.isNotEmpty) {
    return uid == challengerId;
  }
  return null;
}

LivePkSplitLayout resolveLivePkSplitLayout({
  required Map<String, dynamic>? battle,
  required String myStreamId,
  String? myUserId,
  required bool amBroadcaster,
  bool? iAmChallengerOverride,
}) {
  final b = battle ?? const <String, dynamic>{};
  final sid = myStreamId.trim();
  final uid = myUserId?.trim() ?? '';

  final hostStream =
      (b['liveStreamId'] ?? b['hostStreamId'])?.toString().trim() ?? '';
  final opponentStream = (b['opponentLiveStreamId'] ?? b['opponentStreamId'])
          ?.toString()
          .trim() ??
      '';
  final challengerId = (b['challengerId'] ?? b['hostUserId'])?.toString().trim();
  final opponentId =
      (b['opponentId'] ?? b['opponentUserId'] ?? b['targetUserId'])
          ?.toString()
          .trim();

  final leftName = b['leftName']?.toString().trim() ??
      b['challengerName']?.toString().trim() ??
      'Yayıncı A';
  final rightName = b['rightName']?.toString().trim() ??
      b['opponentName']?.toString().trim() ??
      'Yayıncı B';

  final challengerAvatar = b['challengerAvatar']?.toString();
  final opponentAvatar = b['opponentAvatar']?.toString();

  var iAmChallenger = false;
  if (iAmChallengerOverride != null) {
    // Çağıran taraf kararlı (kilitlenmiş) değeri geçti — titremeyi önler.
    iAmChallenger = iAmChallengerOverride;
  } else if (sid.isNotEmpty && hostStream.isNotEmpty && sid == hostStream) {
    iAmChallenger = true;
  } else if (uid.isNotEmpty && challengerId != null && uid == challengerId) {
    iAmChallenger = true;
  }

  if (amBroadcaster) {
    if (iAmChallenger) {
      return LivePkSplitLayout(
        left: LivePkPaneModel(
          label: leftName,
          avatarUrl: challengerAvatar,
          streamId: hostStream.isNotEmpty ? hostStream : sid,
          userId: challengerId ?? uid,
          isLocalPane: true,
        ),
        right: LivePkPaneModel(
          label: rightName,
          avatarUrl: opponentAvatar,
          streamId: opponentStream,
          userId: opponentId,
        ),
      );
    }
    return LivePkSplitLayout(
      left: LivePkPaneModel(
        label: rightName,
        avatarUrl: opponentAvatar,
        streamId: opponentStream.isNotEmpty ? opponentStream : sid,
        userId: opponentId ?? uid,
        isLocalPane: true,
      ),
      right: LivePkPaneModel(
        label: leftName,
        avatarUrl: challengerAvatar,
        streamId: hostStream,
        userId: challengerId,
      ),
    );
  }

  // İzleyici: sol = bu yayının yayıncısı, sağ = PK rakibi.
  final watchingHost = sid == hostStream || sid.isEmpty;
  if (watchingHost) {
    return LivePkSplitLayout(
      left: LivePkPaneModel(
        label: leftName,
        avatarUrl: challengerAvatar,
        streamId: hostStream.isNotEmpty ? hostStream : sid,
        userId: challengerId,
      ),
      right: LivePkPaneModel(
        label: rightName,
        avatarUrl: opponentAvatar,
        streamId: opponentStream,
        userId: opponentId,
      ),
    );
  }
  return LivePkSplitLayout(
    left: LivePkPaneModel(
      label: rightName,
      avatarUrl: opponentAvatar,
      streamId: opponentStream.isNotEmpty ? opponentStream : sid,
      userId: opponentId,
    ),
    right: LivePkPaneModel(
      label: leftName,
      avatarUrl: challengerAvatar,
      streamId: hostStream,
      userId: challengerId,
    ),
  );
}
