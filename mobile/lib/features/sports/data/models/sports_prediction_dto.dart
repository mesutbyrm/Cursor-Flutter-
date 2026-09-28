import '../../domain/entities/sports_prediction_entity.dart';

class FootballMatchDTO {
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

  FootballMatchDTO({
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

  factory FootballMatchDTO.fromJson(Map<String, dynamic> json) {
    return FootballMatchDTO(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      homeTeam: json['homeTeam']?.toString() ?? '',
      awayTeam: json['awayTeam']?.toString() ?? '',
      homeTeamLogo: json['homeTeamLogo']?.toString(),
      awayTeamLogo: json['awayTeamLogo']?.toString(),
      matchDate: json['matchDate'] != null
          ? DateTime.parse(json['matchDate'].toString())
          : DateTime.now(),
      league: json['league']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      homeScore: (json['homeScore'] as num?)?.toInt(),
      awayScore: (json['awayScore'] as num?)?.toInt(),
      homeOdds: (json['homeOdds'] as num?)?.toDouble() ?? 1.5,
      drawOdds: (json['drawOdds'] as num?)?.toDouble() ?? 3.0,
      awayOdds: (json['awayOdds'] as num?)?.toDouble() ?? 2.5,
      prediction: json['prediction']?.toString() ?? '',
      confidence: (json['confidence'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'homeTeam': homeTeam,
        'awayTeam': awayTeam,
        'homeTeamLogo': homeTeamLogo,
        'awayTeamLogo': awayTeamLogo,
        'matchDate': matchDate.toIso8601String(),
        'league': league,
        'status': status,
        'homeScore': homeScore,
        'awayScore': awayScore,
        'homeOdds': homeOdds,
        'drawOdds': drawOdds,
        'awayOdds': awayOdds,
        'prediction': prediction,
        'confidence': confidence,
      };

  FootballMatch toDomain() => FootballMatch(
        id: id,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        homeTeamLogo: homeTeamLogo,
        awayTeamLogo: awayTeamLogo,
        matchDate: matchDate,
        league: league,
        status: status,
        homeScore: homeScore,
        awayScore: awayScore,
        homeOdds: homeOdds,
        drawOdds: drawOdds,
        awayOdds: awayOdds,
        prediction: prediction,
        confidence: confidence,
      );
}

class BetDTO {
  final String id;
  final String userId;
  final String matchId;
  final String prediction;
  final double amount;
  final double odds;
  final double potentialWin;
  final String status;
  final DateTime createdAt;

  BetDTO({
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

  factory BetDTO.fromJson(Map<String, dynamic> json) {
    return BetDTO(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      matchId: json['matchId']?.toString() ?? '',
      prediction: json['prediction']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      odds: (json['odds'] as num?)?.toDouble() ?? 1.0,
      potentialWin: (json['potentialWin'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'userId': userId,
        'matchId': matchId,
        'prediction': prediction,
        'amount': amount,
        'odds': odds,
        'potentialWin': potentialWin,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  Bet toDomain() => Bet(
        id: id,
        userId: userId,
        matchId: matchId,
        prediction: prediction,
        amount: amount,
        odds: odds,
        potentialWin: potentialWin,
        status: status,
        createdAt: createdAt,
      );
}

class LeaderboardEntryDTO {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int totalBets;
  final int winCount;
  final double winRate;
  final double totalEarnings;
  final int rank;

  LeaderboardEntryDTO({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.totalBets,
    required this.winCount,
    required this.winRate,
    required this.totalEarnings,
    required this.rank,
  });

  factory LeaderboardEntryDTO.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryDTO(
      userId: json['userId']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      totalBets: (json['totalBets'] as num?)?.toInt() ?? 0,
      winCount: (json['winCount'] as num?)?.toInt() ?? 0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0.0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'avatarUrl': avatarUrl,
        'totalBets': totalBets,
        'winCount': winCount,
        'winRate': winRate,
        'totalEarnings': totalEarnings,
        'rank': rank,
      };

  LeaderboardEntry toDomain() => LeaderboardEntry(
        userId: userId,
        username: username,
        avatarUrl: avatarUrl,
        totalBets: totalBets,
        winCount: winCount,
        winRate: winRate,
        totalEarnings: totalEarnings,
        rank: rank,
      );
}
