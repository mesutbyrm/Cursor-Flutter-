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
    this.endsAt,
  });

  factory WeeklyBroadcasterCompetition.fromJson(Map<String, dynamic> json) {
    final participantsJson = json['participants'] is List
        ? (json['participants'] as List<dynamic>)
            .map((e) => e is Map ? asJsonMap(e) : e as Map)
            .toList()
        : <Map<String, dynamic>>[];

    final winnersJson = json['winners'] is List
        ? (json['winners'] as List<dynamic>)
            .map((e) => e is Map ? asJsonMap(e) : e as Map)
            .toList()
        : <Map<String, dynamic>>[];

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
      endsAt: json['endsAt'] != null
          ? DateTime.tryParse(json['endsAt'].toString())
          : null,
    );
  }

  final int week;
  final List<WeeklyBroadcasterCompetitionParticipant> participants;
  final List<WeeklyBroadcasterCompetitionParticipant> winners;
  final DateTime? endsAt;
}
