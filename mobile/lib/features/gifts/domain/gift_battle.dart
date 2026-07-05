import '../../../core/util/json_util.dart';

/// Hediye savaşı katılımcısı — puan (gelen hediye jetonu) ile sıralanır.
class GiftBattleParticipant {
  const GiftBattleParticipant({
    required this.participantId,
    required this.displayName,
    this.avatarUrl,
    this.score = 0,
  });

  factory GiftBattleParticipant.fromJson(Map<String, dynamic> json) {
    return GiftBattleParticipant(
      participantId:
          (pick(json, ['participantId', 'userId', 'id']) ?? '').toString(),
      displayName:
          (pick(json, ['displayName', 'name', 'username']) ?? 'Yarışmacı')
              .toString(),
      avatarUrl: pick(json, ['avatarUrl', 'avatar', 'image'])?.toString(),
      score: asInt(pick(json, ['score', 'coins', 'totalCoins', 'points'])),
    );
  }

  final String participantId;
  final String displayName;
  final String? avatarUrl;
  final int score;
}

/// Hediye savaşı durumu — poll ile güncellenir.
class GiftBattle {
  const GiftBattle({
    required this.id,
    required this.status,
    this.context,
    this.contextId,
    this.durationSec = 180,
    this.remainingSec = 0,
    this.participants = const [],
    this.winnerId,
  });

  factory GiftBattle.fromJson(Map<String, dynamic> json) {
    final partsRaw = pick(json, ['participants', 'competitors', 'entries']);
    final parts = <GiftBattleParticipant>[];
    if (partsRaw is List) {
      for (final e in partsRaw) {
        if (e is Map) parts.add(GiftBattleParticipant.fromJson(asJsonMap(e)));
      }
    }
    parts.sort((a, b) => b.score.compareTo(a.score));

    // Kalan süre: doğrudan remainingSec, yoksa endsAt'tan hesapla.
    var remaining = asInt(pick(json, ['remainingSec', 'remaining', 'secondsLeft']));
    final endsAtRaw = pick(json, ['endsAt', 'endAt', 'finishAt']);
    if (remaining <= 0 && endsAtRaw != null) {
      final endsAt = DateTime.tryParse(endsAtRaw.toString());
      if (endsAt != null) {
        remaining = endsAt.difference(DateTime.now()).inSeconds;
        if (remaining < 0) remaining = 0;
      }
    }

    return GiftBattle(
      id: (pick(json, ['id', 'battleId']) ?? '').toString(),
      status: (pick(json, ['status']) ?? 'active').toString(),
      context: pick(json, ['context'])?.toString(),
      contextId: pick(json, ['contextId'])?.toString(),
      durationSec: asInt(pick(json, ['durationSec', 'duration'])),
      remainingSec: remaining,
      participants: parts,
      winnerId: pick(json, ['winnerId', 'winner'])?.toString(),
    );
  }

  final String id;
  final String status; // active | ended
  final String? context;
  final String? contextId;
  final int durationSec;
  final int remainingSec;
  final List<GiftBattleParticipant> participants;
  final String? winnerId;

  bool get isActive => status.toLowerCase() == 'active' && remainingSec > 0;
  bool get isEnded => status.toLowerCase() == 'ended' || remainingSec <= 0;
  bool get isLastCall => isActive && remainingSec <= 10;

  int get totalScore =>
      participants.fold(0, (sum, p) => sum + (p.score < 0 ? 0 : p.score));

  GiftBattleParticipant? get leader =>
      participants.isEmpty ? null : participants.first;
}
