import '../../../../core/util/json_util.dart';

/// PK liderlik satırı — `/api/pk/leaderboard`.
class PkLeaderboardEntry {
  const PkLeaderboardEntry({
    required this.rank,
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.score = 0,
    this.wins = 0,
    this.winRate = 0,
  });

  factory PkLeaderboardEntry.fromJson(Map<String, dynamic> json, int fallbackRank) {
    return PkLeaderboardEntry(
      rank: json.containsKey('rank') ? asInt(pick(json, ['rank'])) : fallbackRank,
      userId: (pick(json, ['userId', 'id']) ?? '').toString(),
      displayName:
          pick(json, ['displayName', 'name', 'username'])?.toString(),
      avatarUrl: pick(json, ['avatarUrl', 'avatar', 'image'])?.toString(),
      score: asInt(pick(json, ['score', 'totalScore', 'points'])),
      wins: asInt(pick(json, ['wins', 'winCount', 'totalWins'])),
      winRate: asInt(pick(json, ['winRate', 'winrate'])),
    );
  }

  final int rank;
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final int score;
  final int wins;
  final int winRate;
}

/// PK istatistiklerim — `/api/pk/me/stats` veya `/api/pk/stats/:userId`.
class PkStats {
  const PkStats({
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.totalScore = 0,
    this.bestScore = 0,
    this.streak = 0,
    this.winRate = 0,
  });

  factory PkStats.fromJson(Map<String, dynamic> json) {
    final m = json['stats'] is Map ? asJsonMap(json['stats']) : json;
    return PkStats(
      wins: asInt(pick(m, ['wins', 'winCount'])),
      losses: asInt(pick(m, ['losses', 'lossCount', 'lose'])),
      draws: asInt(pick(m, ['draws', 'drawCount', 'draw'])),
      totalScore: asInt(pick(m, ['totalScore', 'total', 'score'])),
      bestScore: asInt(pick(m, ['bestScore', 'best', 'highScore'])),
      streak: asInt(pick(m, ['streak', 'winStreak', 'currentStreak'])),
      winRate: asInt(pick(m, ['winRate', 'winrate'])),
    );
  }

  final int wins;
  final int losses;
  final int draws;
  final int totalScore;
  final int bestScore;
  final int streak;
  final int winRate;

  int get total => wins + losses + draws;
  int get computedWinRate =>
      winRate > 0 ? winRate : (total == 0 ? 0 : ((wins / total) * 100).round());
}
