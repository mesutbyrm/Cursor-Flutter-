import 'pk_status_helper.dart';

/// PK sonucu — önce backend (`winnerId`, `isDraw`), yoksa skor.
class LivePkResolvedOutcome {
  const LivePkResolvedOutcome({
    required this.isDraw,
    required this.localWon,
    required this.usedBackendWinner,
  });

  final bool isDraw;
  final bool localWon;
  final bool usedBackendWinner;
}

LivePkResolvedOutcome resolveLivePkAuthoritativeOutcome({
  required Map<String, dynamic> battle,
  required bool ended,
  required String? myUserId,
  required bool localOnLeft,
  required int leftScore,
  required int rightScore,
}) {
  if (!ended) {
    return const LivePkResolvedOutcome(
      isDraw: false,
      localWon: false,
      usedBackendWinner: false,
    );
  }

  final status = normalizePkStatus(battle['status']?.toString());
  if (battle['isDraw'] == true ||
      status == 'draw' ||
      status == 'tie') {
    return const LivePkResolvedOutcome(
      isDraw: true,
      localWon: false,
      usedBackendWinner: true,
    );
  }

  final winnerId = (battle['winnerId'] ?? battle['winnerUserId'] ?? '')
      .toString()
      .trim();
  if (winnerId.isNotEmpty) {
    final me = myUserId?.trim() ?? '';
    final leftUid = ((battle['user1Id'] ??
                battle['challengerId'] ??
                (battle['user1'] is Map
                    ? (battle['user1'] as Map)['id']
                    : null))
            ?.toString() ??
        '')
        .trim();
    final rightUid = ((battle['user2Id'] ??
                battle['opponentId'] ??
                (battle['user2'] is Map
                    ? (battle['user2'] as Map)['id']
                    : null))
            ?.toString() ??
        '')
        .trim();
    if (me.isNotEmpty) {
      final iWon = winnerId == me;
      return LivePkResolvedOutcome(
        isDraw: false,
        localWon: iWon,
        usedBackendWinner: true,
      );
    }
    if (leftUid.isNotEmpty && rightUid.isNotEmpty) {
      final leftWon = winnerId == leftUid;
      return LivePkResolvedOutcome(
        isDraw: false,
        localWon: localOnLeft ? leftWon : !leftWon,
        usedBackendWinner: true,
      );
    }
  }

  if (leftScore == rightScore) {
    return const LivePkResolvedOutcome(
      isDraw: true,
      localWon: false,
      usedBackendWinner: false,
    );
  }
  final leftWins = leftScore > rightScore;
  return LivePkResolvedOutcome(
    isDraw: false,
    localWon: localOnLeft ? leftWins : !leftWins,
    usedBackendWinner: false,
  );
}
