/// PK skorunu ekranda ANINDA artırmak için saf yardımcılar (iyimser güncelleme).
/// Sunucu mutlak skor getirince bu değerlerin yerini alır.
library;

int _score(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

/// [battle] kopyasında `left` (challenger / score1) veya `right` (rakip / score2)
/// tarafına [amount] puan ekler; tüm skor takma adlarını tutarlı yazar.
Map<String, dynamic> battleWithLocalScore(
  Map<String, dynamic> battle, {
  required String side,
  required int amount,
}) {
  final cur1 = _score(battle['score1'] ?? battle['leftScore']);
  final cur2 = _score(battle['score2'] ?? battle['rightScore']);
  final left = side == 'left';
  final n1 = left ? cur1 + amount : cur1;
  final n2 = left ? cur2 : cur2 + amount;
  return Map<String, dynamic>.from(battle)
    ..['score1'] = n1
    ..['score2'] = n2
    ..['leftScore'] = n1
    ..['rightScore'] = n2
    ..['challengerScore'] = n1
    ..['opponentScore'] = n2;
}

/// [streamId] bu savaşta hangi tarafta? Challenger (host) yayını `left`.
String pkSideForStream(Map<String, dynamic> battle, String streamId) {
  final hostSid =
      (battle['liveStreamId'] ?? battle['hostStreamId'])?.toString().trim() ??
          '';
  if (hostSid.isNotEmpty) return hostSid == streamId ? 'left' : 'right';
  final oppSid =
      (battle['opponentLiveStreamId'] ?? battle['opponentStreamId'])
              ?.toString()
              .trim() ??
          '';
  if (oppSid.isNotEmpty && oppSid == streamId) return 'right';
  return 'left';
}
