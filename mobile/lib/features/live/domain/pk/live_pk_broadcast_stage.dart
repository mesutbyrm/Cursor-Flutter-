import 'live_pk_status_pill_mode.dart';
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

/// Maç sonucu etiketi — aktif maç bitmiş sayılmaz (erken "berabere" önlenir).
bool isLivePkOutcomeOnlyStatus(String? status) {
  final s = normalizePkStatus(status);
  return s == 'tie' || s == 'draw';
}

bool isLivePkEndedStatus(String? status) {
  final s = normalizePkStatus(status);
  return s == 'ended' ||
      s == 'completed' ||
      s == 'finished' ||
      s == 'cancelled' ||
      s == 'canceled';
}

/// Süre / `endsAt` doldu mu — sunucu erken `completed`/`ended` gönderse bile
/// maç devam ediyor sayılır.
bool livePkClockAllowsFinish(Map<String, dynamic>? battle, DateTime clock) {
  if (battle == null || battle.isEmpty) return true;
  final endsRaw = battle['endsAt']?.toString().trim() ?? '';
  final endsAt =
      endsRaw.isNotEmpty ? DateTime.tryParse(endsRaw)?.toUtc() : null;
  if (endsAt != null) {
    return !clock.isBefore(endsAt);
  }
  final startedRaw = battle['startedAt']?.toString().trim() ?? '';
  final started =
      startedRaw.isNotEmpty ? DateTime.tryParse(startedRaw)?.toUtc() : null;
  if (started != null) {
    final dur = int.tryParse(
          '${battle['durationSeconds'] ?? battle['duration'] ?? 180}',
        ) ??
        180;
    return !clock.isBefore(started.add(Duration(seconds: dur)));
  }
  return true;
}

/// PK gerçekten bitti mi — `tie`/`draw` ve `completed` yalnızca süre dolduktan sonra.
bool livePkBattleFinished({
  required String? status,
  Map<String, dynamic>? battle,
  DateTime? now,
}) {
  final clock = (now ?? DateTime.now()).toUtc();
  final s = normalizePkStatus(status);
  if (s == 'rejected' || s == 'cancelled' || s == 'canceled') return true;
  if (isLivePkEndedStatus(status)) {
    return livePkClockAllowsFinish(battle, clock);
  }
  if (!isLivePkOutcomeOnlyStatus(status)) return false;
  return livePkClockAllowsFinish(battle, clock);
}

/// Yalnız başlarken / aktifken split video + skor çubuğu. PK bittiği anda
/// (yayıncı, rakip ve izleyiciler için) doğrudan tekli yayına dönülür;
/// önceden sonuç ekranı için split 7-8 sn açık kalıyor, erken bitişte ise
/// süre dolunca split geri geliyordu.
bool isLivePkBroadcastStage(Map<String, dynamic>? battle, String? status) {
  if (!livePkHasDualStreams(battle)) return false;
  if (isLivePkStartingStatus(status)) return true;
  if (isLivePkActiveStatus(status)) return true;
  return false;
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
  if (leftScore == rightScore) return 'Berabere!';
  final leftWins = leftScore > rightScore;
  final iWon = localOnLeft ? leftWins : !leftWins;
  if (iWon) return 'Kazandın!';
  final winner = leftWins ? (leftLabel ?? 'Sol') : (rightLabel ?? 'Sağ');
  return '$winner kazandı!';
}

PkStatusPillMode livePkStatusPillMode({
  required bool ended,
  required int leftScore,
  required int rightScore,
}) {
  if (!ended) return PkStatusPillMode.active;
  if (leftScore == rightScore) return PkStatusPillMode.endedDraw;
  return PkStatusPillMode.endedWin;
}

String? livePkWinnerName({
  required int leftScore,
  required int rightScore,
  String? leftLabel,
  String? rightLabel,
}) {
  if (leftScore == rightScore) return null;
  final leftWins = leftScore > rightScore;
  return leftWins ? (leftLabel ?? 'Sol') : (rightLabel ?? 'Sağ');
}

bool livePkLeftPaneWins({
  required int leftScore,
  required int rightScore,
}) {
  if (leftScore == rightScore) return false;
  return leftScore > rightScore;
}
