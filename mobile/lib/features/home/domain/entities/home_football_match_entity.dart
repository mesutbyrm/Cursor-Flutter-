import '../../../../core/util/json_util.dart';

/// `GET /api/football` maç satırı — esnek JSON şeması.
class HomeFootballMatchEntity {
  const HomeFootballMatchEntity({
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore,
    this.awayScore,
    this.status,
    this.league,
  });

  factory HomeFootballMatchEntity.fromJson(Map<String, dynamic> json) {
    return HomeFootballMatchEntity(
      homeTeam: _teamName(json, const [
        'homeTeam',
        'home',
        'teamHome',
        'localTeam',
        'homeName',
      ]),
      awayTeam: _teamName(json, const [
        'awayTeam',
        'away',
        'teamAway',
        'visitorTeam',
        'awayName',
      ]),
      homeScore: _score(json, const ['homeScore', 'scoreHome', 'homeGoals']),
      awayScore: _score(json, const ['awayScore', 'scoreAway', 'awayGoals']),
      status: pick(json, ['status', 'state', 'minute', 'matchStatus'])?.toString(),
      league: pick(json, ['league', 'competition', 'tournament', 'leagueName'])
          ?.toString(),
    );
  }

  final String homeTeam;
  final String awayTeam;
  final int? homeScore;
  final int? awayScore;
  final String? status;
  final String? league;

  bool get hasTeams => homeTeam.isNotEmpty && awayTeam.isNotEmpty;

  String get scoreLabel {
    if (homeScore != null && awayScore != null) {
      return '$homeScore - $awayScore';
    }
    return status?.trim().isNotEmpty == true ? status!.trim() : '—';
  }

  static String _teamName(Map<String, dynamic> json, List<String> keys) {
    final raw = pick(json, keys);
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return pick(map, ['name', 'shortName', 'title', 'team'])?.toString() ?? '';
    }
    return raw?.toString() ?? '';
  }

  static int? _score(Map<String, dynamic> json, List<String> keys) {
    final raw = pick(json, keys);
    if (raw == null) return null;
    return asInt(raw);
  }
}
