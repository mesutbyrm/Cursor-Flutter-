import 'package:equatable/equatable.dart';

import '../../../../core/util/json_util.dart';

/// `GET /api/agency/leaderboard` satırı.
class AgencyLeaderboardEntry extends Equatable {
  const AgencyLeaderboardEntry({
    required this.rank,
    required this.agencyId,
    required this.name,
    this.logoUrl,
    this.score = 0,
    this.memberCount,
  });

  factory AgencyLeaderboardEntry.fromJson(Map<String, dynamic> json, int fallbackRank) {
    final agency = json['agency'] is Map ? asJsonMap(json['agency']) : json;
    return AgencyLeaderboardEntry(
      rank: json.containsKey('rank') ? asInt(pick(json, ['rank'])) : fallbackRank,
      agencyId: pick(agency, ['id', 'agencyId', '_id'])?.toString() ?? '',
      name: pick(agency, ['name', 'title', 'displayName'])?.toString() ?? 'Ajans',
      logoUrl: pick(agency, ['logoUrl', 'logo', 'image', 'avatarUrl'])?.toString(),
      score: asInt(pick(json, ['score', 'points', 'totalEarnings', 'earnings'])),
      memberCount: () {
        final v = pick(json, ['memberCount', 'members']);
        return v == null ? null : asInt(v);
      }(),
    );
  }

  final int rank;
  final String agencyId;
  final String name;
  final String? logoUrl;
  final int score;
  final int? memberCount;

  @override
  List<Object?> get props => [rank, agencyId, name, logoUrl, score, memberCount];
}
