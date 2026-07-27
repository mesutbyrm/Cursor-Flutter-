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
  if (rank <= 0) return 'Lig 4';
  if (rank <= 10) return 'Lig 1';
  if (rank <= 30) return 'Lig 2';
  if (rank <= 60) return 'Lig 3';
  return 'Lig 4';
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
      return LiveHostRankInfo(
        popularRank: found.rank,
        leagueLabel: leagueLabelForRank(found.rank),
      );
    }
    return const LiveHostRankInfo(leagueLabel: 'Lig 4');
  } catch (_) {
    return null;
  }
});
