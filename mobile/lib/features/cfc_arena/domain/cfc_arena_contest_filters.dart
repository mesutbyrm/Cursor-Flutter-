import '../../../../core/util/json_util.dart';

import 'cfc_arena_context.dart';

/// Üretim `/api/cfc-arena` yanıtından yarışma listesi.
List<Map<String, dynamic>> parseCfcContestList(dynamic body) {
  if (body is List) {
    return body.whereType<Map>().map(asJsonMap).toList();
  }
  if (body is! Map) return const [];

  final root = asJsonMap(body);
  final direct = root['contests'] ?? root['items'];
  if (direct is List) {
    return direct.whereType<Map>().map(asJsonMap).toList();
  }

  final data = root['data'];
  if (data is List) {
    return data.whereType<Map>().map(asJsonMap).toList();
  }
  if (data is Map) {
    final nested = asJsonMap(data);
    final list = nested['contests'] ?? nested['items'] ?? nested['data'];
    if (list is List) {
      return list.whereType<Map>().map(asJsonMap).toList();
    }
  }
  return const [];
}

bool cfcContestIsActive(Map<String, dynamic> c) {
  final status = (c['status'] ?? '').toString().toLowerCase();
  if (status == 'active') return true;
  if (status.isEmpty) return true;
  return false;
}

bool cfcContestIsPublic(Map<String, dynamic> c) {
  final v = c['isPublic'];
  if (v is bool) return v;
  return true;
}

bool cfcContestIsSeasonOrFeatured(Map<String, dynamic> c) {
  if (c['isFeatured'] == true) return true;
  final scope = (c['scope'] ?? '').toString().toLowerCase();
  if (scope == 'seasonal' || scope == 'season') return true;
  final seasonId = c['seasonId'];
  if (seasonId != null && seasonId.toString().trim().isNotEmpty) return true;
  if (c['season'] is Map) return true;
  return false;
}

List<String> _metricKeys(Map<String, dynamic> c) {
  final raw = c['scoringMetrics'];
  if (raw is! String || raw.trim().isEmpty) return const [];
  final re = RegExp(r'"metric"\s*:\s*"([^"]+)"');
  return re.allMatches(raw).map((m) => m.group(1)!).toList();
}

bool _metricsContainAny(Map<String, dynamic> c, List<String> needles) {
  final keys = _metricKeys(c);
  for (final n in needles) {
    if (keys.any((k) => k.toLowerCase().contains(n.toLowerCase()))) {
      return true;
    }
  }
  return false;
}

/// Canlı yayın / sesli odada gösterilecek aktif sezon/öne çıkan yarışmalar.
List<Map<String, dynamic>> filterContestsForSurface(
  List<Map<String, dynamic>> all,
  CfcArenaSurface surface,
) {
  return all.where((c) {
    if (!cfcContestIsActive(c) || !cfcContestIsPublic(c)) return false;
    if (!cfcContestIsSeasonOrFeatured(c)) return false;

    final type = (c['type'] ?? '').toString().toLowerCase();
    return switch (surface) {
      CfcArenaSurface.liveBroadcast =>
        type == 'broadcaster' ||
            type == 'individual' ||
            type == 'team' ||
            type == 'league' ||
            _metricsContainAny(c, [
              'viewer_count',
              'gifts_received',
              'stream_minutes',
              'followers_gained',
            ]),
      CfcArenaSurface.voiceRoom =>
        type == 'room' ||
            type == 'team' ||
            type == 'duel' ||
            _metricsContainAny(c, [
              'room_engagement',
              'chat_messages',
              'gift_sent',
              'activity_points',
            ]),
    };
  }).toList();
}

String cfcContestId(Map<String, dynamic> c) {
  return pick(c, ['id', 'contestId', '_id'])?.toString() ?? '';
}

int cfcContestParticipantCount(Map<String, dynamic> c) {
  final count = c['_count'];
  if (count is Map) {
    final p = count['participants'];
    if (p is num) return p.toInt();
  }
  final participants = c['participants'];
  if (participants is List) return participants.length;
  return 0;
}
