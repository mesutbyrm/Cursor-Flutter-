import '../../../../core/util/json_util.dart';

/// Haftalık yayıncı yarışması katılımcısı.
class WeeklyBroadcasterCompetitionParticipant {
  const WeeklyBroadcasterCompetitionParticipant({
    required this.rank,
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.score = 0,
    this.isWinner = false,
  });

  factory WeeklyBroadcasterCompetitionParticipant.fromJson(
    Map<String, dynamic> json,
    int fallbackRank,
  ) {
    return WeeklyBroadcasterCompetitionParticipant(
      rank: json.containsKey('rank') ? asInt(pick(json, ['rank'])) : fallbackRank,
      userId: (pick(json, ['userId', 'id', 'broadcasterId']) ?? '').toString(),
      displayName:
          pick(json, ['displayName', 'name', 'username'])?.toString(),
      avatarUrl: pick(json, ['avatarUrl', 'avatar', 'image'])?.toString(),
      score: asInt(pick(json, ['score', 'totalScore', 'points'])),
      isWinner: pick(json, ['isWinner', 'winner']) == true,
    );
  }

  final int rank;
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final int score;
  final bool isWinner;
}

/// Haftalık yayıncı yarışması — tüm katılımcılar ve derece yapanlar.
class WeeklyBroadcasterCompetition {
  const WeeklyBroadcasterCompetition({
    required this.week,
    required this.participants,
    required this.winners,
    this.title,
    this.startsAt,
    this.endsAt,
  });

  factory WeeklyBroadcasterCompetition.fromJson(Map<String, dynamic> json) {
    // Sunucu katılımcı listesini farklı adlarla dönebiliyor; yalnızca
    // `participants` aranırsa liste boş kalıp tablo hiç dolmuyordu.
    final participantsJson = asJsonList(
      pick(json, [
        'participants',
        'entries',
        'leaderboard',
        'rankings',
        'standings',
        'items',
      ]),
    );

    final winnersJson = asJsonList(
      pick(json, ['winners', 'topWinners', 'awarded']),
    );

    return WeeklyBroadcasterCompetition(
      week: asInt(pick(json, ['week', 'weekNumber'])),
      participants: List.generate(
        participantsJson.length,
        (i) => WeeklyBroadcasterCompetitionParticipant.fromJson(
          participantsJson[i],
          i + 1,
        ),
      ),
      winners: List.generate(
        winnersJson.length,
        (i) => WeeklyBroadcasterCompetitionParticipant.fromJson(
          winnersJson[i],
          i + 1,
        ),
      ),
      title: pick(json, ['title', 'name', 'competitionName'])?.toString(),
      startsAt: _parseDate(pick(json, ['startsAt', 'startAt', 'startDate'])),
      endsAt: _parseDate(
        pick(json, ['endsAt', 'endAt', 'endDate', 'finishesAt']),
      ),
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  final int week;
  final List<WeeklyBroadcasterCompetitionParticipant> participants;
  final List<WeeklyBroadcasterCompetitionParticipant> winners;
  final String? title;
  final DateTime? startsAt;
  final DateTime? endsAt;

  String get displayTitle {
    final t = title?.trim() ?? '';
    if (t.isNotEmpty) return t;
    return week > 0 ? '$week. Hafta Yarışması' : 'Haftalık Yarışma';
  }

  /// Yarışma durumu — sunucu tarih vermediyse `running` varsayılır.
  WeeklyCompetitionPhase phaseAt(DateTime now) {
    final start = startsAt;
    if (start != null && now.isBefore(start)) {
      return WeeklyCompetitionPhase.upcoming;
    }
    final end = endsAt;
    if (end != null && !now.isBefore(end)) {
      return WeeklyCompetitionPhase.finished;
    }
    return WeeklyCompetitionPhase.running;
  }

  /// Kalan süre — bitiş yoksa veya geçtiyse null.
  Duration? remainingAt(DateTime now) {
    final end = endsAt;
    if (end == null) return null;
    final left = end.difference(now);
    return left.isNegative ? null : left;
  }

  /// Kullanıcının kendi satırı — sıralama ve puanı göstermek için.
  WeeklyBroadcasterCompetitionParticipant? entryFor(String? userId) {
    final id = userId?.trim() ?? '';
    if (id.isEmpty) return null;
    for (final p in participants) {
      if (p.userId == id) return p;
    }
    return null;
  }
}

enum WeeklyCompetitionPhase { upcoming, running, finished }
