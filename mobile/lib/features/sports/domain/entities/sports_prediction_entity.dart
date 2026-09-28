class FootballMatch {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final String? homeTeamLogo;
  final String? awayTeamLogo;
  final DateTime matchDate;
  final String league;
  final String status;
  final int? homeScore;
  final int? awayScore;
  final double homeOdds;
  final double drawOdds;
  final double awayOdds;
  final String prediction;
  final int confidence;

  FootballMatch({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    this.homeTeamLogo,
    this.awayTeamLogo,
    required this.matchDate,
    required this.league,
    required this.status,
    this.homeScore,
    this.awayScore,
    required this.homeOdds,
    required this.drawOdds,
    required this.awayOdds,
    required this.prediction,
    required this.confidence,
  });

  bool get isLive => status == 'live';

  bool get isFinished => status == 'finished';

  bool get isPending => status == 'pending';

  String get score =>
      homeScore != null && awayScore != null ? '$homeScore-$awayScore' : 'N/A';
}

class Bet {
  final String id;
  final String userId;
  final String matchId;
  final String prediction;
  final double amount;
  final double odds;
  final double potentialWin;
  final String status;
  final DateTime createdAt;

  Bet({
    required this.id,
    required this.userId,
    required this.matchId,
    required this.prediction,
    required this.amount,
    required this.odds,
    required this.potentialWin,
    required this.status,
    required this.createdAt,
  });

  bool get isWon => status == 'won';

  bool get isLost => status == 'lost';

  bool get isPending => status == 'pending';

  double get profit => potentialWin - amount;
}

class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int totalBets;
  final int winCount;
  final double winRate;
  final double totalEarnings;
  final int rank;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.totalBets,
    required this.winCount,
    required this.winRate,
    required this.totalEarnings,
    required this.rank,
  });

  int get lossCount => totalBets - winCount;
}
