import 'pk_status_helper.dart';

bool livePkHasDualStreams(Map<String, dynamic>? battle) {
  if (battle == null) return false;
  final host = (battle['liveStreamId'] ??
          battle['hostStreamId'] ??
          battle['streamId'])
      ?.toString()
      .trim();
  final opponent = (battle['opponentLiveStreamId'] ??
          battle['opponentStreamId'] ??
          battle['targetStreamId'])
      ?.toString()
      .trim();
  return host != null &&
      host.isNotEmpty &&
      opponent != null &&
      opponent.isNotEmpty;
}

bool isLivePkEndedStatus(String? status) {
  final s = normalizePkStatus(status);
  return s == 'ended' ||
      s == 'completed' ||
      s == 'finished' ||
      s == 'tie' ||
      s == 'draw' ||
      s == 'cancelled' ||
      s == 'canceled';
}

/// Aktif veya bitti — split video + skor çubuğu (tam ekran sonuç overlay yok).
bool isLivePkBroadcastStage(Map<String, dynamic>? battle, String? status) {
  if (!livePkHasDualStreams(battle)) return false;
  if (isLivePkActiveStatus(status)) return true;
  return isLivePkEndedStatus(status);
}

String livePkOutcomeStatusLabel({
  required bool ended,
  required bool localOnLeft,
  required int leftScore,
  required int rightScore,
  String? leftLabel,
  String? rightLabel,
}) {
  if (!ended) return 'PK devam ediyor!';
  if (leftScore == rightScore) return 'BERABERE!';
  final leftWins = leftScore > rightScore;
  final iWon = localOnLeft ? leftWins : !leftWins;
  if (iWon) return 'KAZANDIN!';
  final winner = leftWins ? (leftLabel ?? 'Sol') : (rightLabel ?? 'Sağ');
  return '$winner kazandı!';
}
