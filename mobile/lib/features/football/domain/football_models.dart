import '../../../core/util/json_util.dart';

/// Backend `ALL_COMPETITIONS` (app/api/football/route.ts) ile aynı liste.
const footballCompetitions = <(String code, String name, String flag)>[
  ('PL', 'Premier League', '🏴'),
  ('PD', 'La Liga', '🇪🇸'),
  ('SA', 'Serie A', '🇮🇹'),
  ('BL1', 'Bundesliga', '🇩🇪'),
  ('FL1', 'Ligue 1', '🇫🇷'),
  ('CL', 'Şampiyonlar Ligi', '🇪🇺'),
  ('PPL', 'Primeira Liga', '🇵🇹'),
  ('DED', 'Eredivisie', '🇳🇱'),
  ('ELC', 'Championship', '🏴'),
  ('BSA', 'Brasileirão', '🇧🇷'),
  ('EC', 'Avrupa Şampiyonası', '🇪🇺'),
  ('WC', 'Dünya Kupası', '🌍'),
];

class FootballTeam {
  const FootballTeam({required this.name, this.crest});

  final String name;
  final String? crest;

  factory FootballTeam.fromJson(dynamic raw) {
    final m = asJsonMap(raw);
    final short = m['shortName']?.toString().trim();
    return FootballTeam(
      name: (short != null && short.isNotEmpty) ? short : (m['name']?.toString() ?? ''),
      crest: m['crest']?.toString(),
    );
  }
}

/// football-data.org v4 maç satırı (`GET /api/football?action=matches`).
class FootballMatch {
  const FootballMatch({
    required this.id,
    required this.utcDate,
    required this.status,
    required this.home,
    required this.away,
    required this.homeGoals,
    required this.awayGoals,
    required this.competitionName,
    required this.competitionFlag,
  });

  final String id;
  final DateTime? utcDate;
  final String status;
  final FootballTeam home;
  final FootballTeam away;
  final int? homeGoals;
  final int? awayGoals;
  final String competitionName;
  final String competitionFlag;

  bool get isLive => status == 'IN_PLAY' || status == 'PAUSED' || status == 'LIVE';
  bool get isFinished => status == 'FINISHED';
  bool get hasScore => homeGoals != null && awayGoals != null;

  String get statusLabel => switch (status) {
        'IN_PLAY' || 'LIVE' => 'CANLI',
        'PAUSED' => 'Devre arası',
        'FINISHED' => 'Bitti',
        'POSTPONED' => 'Ertelendi',
        'SUSPENDED' => 'Durduruldu',
        'CANCELLED' => 'İptal',
        _ => '',
      };

  factory FootballMatch.fromJson(Map<String, dynamic> json) {
    final full = asJsonMap(asJsonMap(json['score'])['fullTime']);
    final comp = asJsonMap(json['competition']);
    int? goals(dynamic v) => v == null ? null : asInt(v);
    return FootballMatch(
      id: json['id']?.toString() ?? '',
      utcDate: DateTime.tryParse(json['utcDate']?.toString() ?? ''),
      status: json['status']?.toString() ?? '',
      home: FootballTeam.fromJson(json['homeTeam']),
      away: FootballTeam.fromJson(json['awayTeam']),
      homeGoals: goals(full['home']),
      awayGoals: goals(full['away']),
      competitionName:
          (comp['localName'] ?? comp['name'])?.toString() ?? 'Diğer',
      competitionFlag: comp['flag']?.toString() ?? '⚽',
    );
  }
}

class FootballStandingRow {
  const FootballStandingRow({
    required this.position,
    required this.team,
    required this.played,
    required this.won,
    required this.draw,
    required this.lost,
    required this.goalDifference,
    required this.points,
  });

  final int position;
  final FootballTeam team;
  final int played;
  final int won;
  final int draw;
  final int lost;
  final int goalDifference;
  final int points;

  factory FootballStandingRow.fromJson(Map<String, dynamic> json) =>
      FootballStandingRow(
        position: asInt(json['position']),
        team: FootballTeam.fromJson(json['team']),
        played: asInt(json['playedGames']),
        won: asInt(json['won']),
        draw: asInt(json['draw']),
        lost: asInt(json['lost']),
        goalDifference: asInt(json['goalDifference']),
        points: asInt(json['points']),
      );

  /// `standings[]` içinden `TOTAL` tablosu (yoksa ilki).
  static List<FootballStandingRow> fromStandings(dynamic standings) {
    final groups = asJsonList(standings);
    if (groups.isEmpty) return const [];
    final total = groups.firstWhere(
      (g) => g['type']?.toString() == 'TOTAL',
      orElse: () => groups.first,
    );
    return asJsonList(total['table']).map(FootballStandingRow.fromJson).toList();
  }
}

class FootballScorer {
  const FootballScorer({
    required this.player,
    required this.team,
    required this.goals,
  });

  final String player;
  final FootballTeam team;
  final int goals;

  factory FootballScorer.fromJson(Map<String, dynamic> json) => FootballScorer(
        player: asJsonMap(json['player'])['name']?.toString() ?? '',
        team: FootballTeam.fromJson(json['team']),
        goals: asInt(json['goals']),
      );
}
