/// PK REST/SSE yükü — tekrarlayan olayları atlamak için parmak izi.
String livePkBattleIngestFingerprint(Map<String, dynamic> battle) {
  final eventId = (battle['eventId'] ??
          battle['sseEventId'] ??
          battle['messageId'] ??
          '')
      .toString()
      .trim();
  final id = (battle['id'] ??
          battle['battleId'] ??
          battle['pkBattleId'] ??
          battle['inviteId'] ??
          '')
      .toString()
      .trim();
  final status = (battle['status'] ?? '').toString().toLowerCase().trim();
  final s1 = '${battle['score1'] ?? battle['leftScore'] ?? battle['challengerScore'] ?? ''}';
  final s2 = '${battle['score2'] ?? battle['rightScore'] ?? battle['opponentScore'] ?? ''}';
  final host = (battle['liveStreamId'] ??
          battle['hostStreamId'] ??
          '')
      .toString()
      .trim();
  final opp = (battle['opponentLiveStreamId'] ??
          battle['opponentStreamId'] ??
          '')
      .toString()
      .trim();
  return '$eventId|$id|$status|$s1|$s2|$host|$opp';
}
