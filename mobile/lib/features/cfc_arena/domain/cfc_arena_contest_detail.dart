import '../../../core/util/json_util.dart';

/// Yarışma sıralamasındaki tek katılımcı — `GET /api/cfc-arena/{id}`
/// yanıtının `data.leaderboard` girdisi.
class CfcArenaEntry {
  const CfcArenaEntry({
    required this.userId,
    required this.name,
    this.image,
    this.score = 0,
    this.rank,
  });

  final String userId;
  final String name;
  final String? image;
  final int score;
  final int? rank;

  static CfcArenaEntry? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final map = asJsonMap(raw);
    final user = map['user'] is Map ? asJsonMap(map['user']) : null;
    final id = pick(map, ['userId', 'user_id'])?.toString().trim() ??
        user?['id']?.toString().trim() ??
        '';
    if (id.isEmpty) return null;
    final name = pick(map, ['displayName', 'name'])?.toString().trim();
    final userName = user == null
        ? null
        : pick(user, ['name', 'username'])?.toString().trim();
    return CfcArenaEntry(
      userId: id,
      name: (name != null && name.isNotEmpty)
          ? name
          : (userName != null && userName.isNotEmpty ? userName : 'Katılımcı'),
      image: user?['image']?.toString(),
      score: asInt(map['score']),
      rank: map['rank'] is num ? (map['rank'] as num).toInt() : null,
    );
  }
}

/// `GET /api/cfc-arena/{id}` — yarışma + sıralama.
///
/// Üretim yanıtı `{success, data: {contest, leaderboard, teams, page, limit}}`
/// biçiminde. Eski ayrıştırıcı yalnızca `contest` alıyordu; katılımcı listesi
/// `contest.participants` içinde aranıyor ve hiç bulunamıyordu.
class CfcArenaContestDetail {
  const CfcArenaContestDetail({
    this.contest = const {},
    this.entries = const [],
  });

  final Map<String, dynamic> contest;
  final List<CfcArenaEntry> entries;

  bool get isEmpty => contest.isEmpty && entries.isEmpty;

  /// Sıralama — sunucu `rank` verdiyse ona, yoksa skora göre.
  List<CfcArenaEntry> get ranked {
    final sorted = [...entries];
    sorted.sort((a, b) {
      final ra = a.rank;
      final rb = b.rank;
      if (ra != null && rb != null && ra != rb) return ra.compareTo(rb);
      if (a.score != b.score) return b.score.compareTo(a.score);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sorted;
  }

  CfcArenaEntry? entryFor(String? userId) {
    final id = userId?.trim();
    if (id == null || id.isEmpty) return null;
    for (final e in entries) {
      if (e.userId == id) return e;
    }
    return null;
  }

  /// Kullanıcı yarışmaya katıldı mı.
  bool hasJoined(String? userId) => entryFor(userId) != null;

  /// 1 tabanlı sıra — sunucu `rank` vermediyse listeden türetilir.
  int? rankFor(String? userId) {
    final entry = entryFor(userId);
    if (entry == null) return null;
    if (entry.rank != null) return entry.rank;
    final list = ranked;
    for (var i = 0; i < list.length; i++) {
      if (list[i].userId == entry.userId) return i + 1;
    }
    return null;
  }

  static CfcArenaContestDetail parse(Object? body) {
    if (body is! Map) return const CfcArenaContestDetail();
    var root = asJsonMap(body);
    if (root['data'] is Map) root = asJsonMap(root['data']);

    final contestRaw = root['contest'];
    final contest = contestRaw is Map ? asJsonMap(contestRaw) : root;

    final rawList = root['leaderboard'] ??
        root['entries'] ??
        root['participants'] ??
        contest['participants'];
    final entries = <CfcArenaEntry>[];
    if (rawList is List) {
      for (final item in rawList) {
        final entry = CfcArenaEntry.fromJson(item);
        if (entry != null) entries.add(entry);
      }
    }
    return CfcArenaContestDetail(contest: contest, entries: entries);
  }
}

/// Yarışmanın bitişine kalan süre; bilinmiyorsa `null`.
Duration? cfcContestRemaining(Map<String, dynamic> contest, DateTime now) {
  final raw = pick(contest, ['endsAt', 'endDate', 'finishesAt'])?.toString();
  if (raw == null || raw.trim().isEmpty) return null;
  final end = DateTime.tryParse(raw);
  if (end == null) return null;
  final diff = end.toUtc().difference(now.toUtc());
  return diff.isNegative ? Duration.zero : diff;
}

String formatCfcRemaining(Duration d) {
  if (d.inDays >= 1) return '${d.inDays} gün';
  if (d.inHours >= 1) return '${d.inHours} sa';
  if (d.inMinutes >= 1) return '${d.inMinutes} dk';
  return 'bitiyor';
}
