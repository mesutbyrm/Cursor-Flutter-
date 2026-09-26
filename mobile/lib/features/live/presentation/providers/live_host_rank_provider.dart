import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/pk/pk_leaderboard_models.dart';
import 'pk_room_providers.dart';

class LiveHostRankInfo {
  const LiveHostRankInfo({
    this.popularRank,
    this.leagueLabel,
  });

  final int? popularRank;
  final String? leagueLabel;
}

String leagueLabelForRank(int rank) {
  if (rank <= 0) return 'Lig 5';
  if (rank <= 10) return 'Lig 1';
  if (rank <= 30) return 'Lig 2';
  if (rank <= 60) return 'Lig 3';
  if (rank <= 100) return 'Lig 4';
  return 'Lig 5';
}

/// PK / hediye skoruna göre lig (canlı üst bar — leaderboard skoru ile birleştirilir).
String leagueLabelForPkScore(int score) {
  if (score >= 50_000) return 'Lig 1';
  if (score >= 20_000) return 'Lig 2';
  if (score >= 8_000) return 'Lig 3';
  if (score >= 2_000) return 'Lig 4';
  return 'Lig 5';
}

int _leagueTier(String label) {
  final m = RegExp(r'Lig\s*(\d+)').firstMatch(label);
  return int.tryParse(m?.group(1) ?? '') ?? 5;
}

String _bestLeagueLabel(String a, String b) {
  return _leagueTier(a) <= _leagueTier(b) ? a : b;
}

final liveHostRankProvider = FutureProvider.autoDispose
    .family<LiveHostRankInfo?, String>((ref, hostUserId) async {
  final id = hostUserId.trim();
  if (id.isEmpty) return null;
  try {
    final api = ref.watch(pkRoomRemoteProvider);
    final board = await api.leaderboard(limit: 100);
    PkLeaderboardEntry? found;
    for (final e in board) {
      if (e.userId == id) {
        found = e;
        break;
      }
    }
    if (found != null) {
      final fromRank = leagueLabelForRank(found.rank);
      final fromScore = leagueLabelForPkScore(found.score);
      return LiveHostRankInfo(
        popularRank: found.rank,
        leagueLabel: _bestLeagueLabel(fromRank, fromScore),
      );
    }
    return const LiveHostRankInfo(leagueLabel: 'Lig 5');
  } catch (_) {
    return null;
  }
});
