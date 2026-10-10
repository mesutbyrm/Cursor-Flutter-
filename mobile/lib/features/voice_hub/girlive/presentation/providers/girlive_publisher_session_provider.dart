import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../live/domain/pk/live_pk_authoritative_outcome.dart';
import '../../../domain/entities/chat_room_presence.dart';
import '../../../domain/pk/pk_battle_remote_models.dart';
import '../../girlive_publisher_session_metrics.dart';

class GirLivePublisherSessionNotifier
    extends StateNotifier<GirLivePublisherSessionMetrics?> {
  GirLivePublisherSessionNotifier() : super(null);

  final Set<String> _presentNow = {};
  final Set<String> _everSeen = {};
  var _pkActive = false;
  void start(String roomKey) {
    final key = roomKey.trim();
    if (key.isEmpty) return;
    _presentNow.clear();
    _everSeen.clear();
    _pkActive = false;
    state = GirLivePublisherSessionMetrics(roomKey: key, startedAt: DateTime.now());
  }

  void onPresence(String roomKey, List<ChatRoomPresence> presence, {String? myUserId}) {
    final cur = state;
    if (cur == null || cur.roomKey != roomKey.trim()) return;

    final ids = <String>{};
    for (final p in presence) {
      final id = p.id.trim();
      if (id.isEmpty || id == myUserId) continue;
      ids.add(id);
    }

    var visits = cur.totalVisitEvents;
    var unique = Set<String>.from(cur.uniqueVisitorIds);
    var returns = Set<String>.from(cur.returnVisitorIds);
    var buckets = Map<int, int>.from(cur.hourlyJoinBuckets);

    for (final id in ids) {
      if (_presentNow.contains(id)) continue;
      visits++;
      final hour = DateTime.now().hour;
      buckets[hour] = (buckets[hour] ?? 0) + 1;
      if (_everSeen.contains(id)) {
        returns.add(id);
      } else {
        _everSeen.add(id);
        unique.add(id);
      }
    }

    _presentNow
      ..clear()
      ..addAll(ids);

    final active = ids.length;
    final peak = active > cur.peakActiveViewerCount ? active : cur.peakActiveViewerCount;

    state = cur.copyWith(
      totalVisitEvents: visits,
      uniqueVisitorIds: unique,
      returnVisitorIds: returns,
      hourlyJoinBuckets: buckets,
      lastActiveViewerCount: active,
      peakActiveViewerCount: peak,
    );
  }

  void onPkBattle({
    required String roomKey,
    required PkBattleRemote? battle,
    required String? ownerUserId,
    required int giftJetonDelta,
  }) {
    final cur = state;
    if (cur == null || cur.roomKey != roomKey.trim()) return;
    if (battle == null) return;

    final active = battle.isActive && !battle.isEnded;
    var pkGift = cur.pkGiftJetonDuringPk;
    if (_pkActive && giftJetonDelta > 0) {
      pkGift += giftJetonDelta;
    }
    _pkActive = active;

    if (!battle.isEnded) {
      if (pkGift != cur.pkGiftJetonDuringPk) {
        state = cur.copyWith(pkGiftJetonDuringPk: pkGift);
      }
      return;
    }

    final bid = battle.id.trim();
    if (bid.isEmpty || cur.recordedPkBattleIds.contains(bid)) return;

    final endedOk = battle.status == 'ended' ||
        battle.status == 'completed' ||
        (battle.winnerId != null && battle.winnerId!.trim().isNotEmpty) ||
        battle.result != null;
    if (!endedOk) return;
    if (battle.status == 'cancelled' ||
        battle.status == 'canceled' ||
        battle.status == 'rejected') {
      return;
    }

    final owner = ownerUserId?.trim() ?? '';
    final wire = <String, dynamic>{
      'status': battle.status,
      'winnerId': battle.winnerId ?? battle.result?.winnerId,
      'challengerId': battle.challengerId,
      'opponentId': battle.opponentId,
      'user1Id': battle.challengerId,
      'user2Id': battle.opponentId,
    };
    final outcome = resolveLivePkAuthoritativeOutcome(
      battle: wire,
      ended: true,
      myUserId: owner.isNotEmpty ? owner : null,
      localOnLeft: true,
      leftScore: battle.challengerScore,
      rightScore: battle.opponentScore,
    );

    if (!outcome.usedBackendWinner &&
        battle.winnerId == null &&
        battle.result == null) {
      return;
    }

    var won = cur.pkWon;
    var lost = cur.pkLost;
    var draw = cur.pkDraw;
    if (outcome.isDraw) {
      draw++;
    } else if (owner.isNotEmpty) {
      if (outcome.localWon) {
        won++;
      } else {
        lost++;
      }
    }

    final recorded = Set<String>.from(cur.recordedPkBattleIds)..add(bid);
    state = cur.copyWith(
      pkCompleted: cur.pkCompleted + 1,
      pkWon: won,
      pkLost: lost,
      pkDraw: draw,
      pkGiftJetonDuringPk: pkGift,
      recordedPkBattleIds: recorded,
    );
  }

  GirLivePublisherSessionMetrics? take(String roomKey) {
    final cur = state;
    if (cur == null || cur.roomKey != roomKey.trim()) return null;
    state = null;
    _presentNow.clear();
    _everSeen.clear();
    _pkActive = false;
    return cur;
  }
}

final girlivePublisherSessionProvider = StateNotifierProvider<
    GirLivePublisherSessionNotifier, GirLivePublisherSessionMetrics?>(
  (ref) => GirLivePublisherSessionNotifier(),
);

void trackGirLivePublisherSession(
  WidgetRef ref,
  String roomKey, {
  required ProviderListenable<List<ChatRoomPresence>> presence,
  required ProviderListenable<PkBattleRemote?> pkBattle,
  required String? ownerUserId,
  String? myUserId,
}) {
  final key = roomKey.trim();
  if (key.isEmpty) return;
  final session = ref.read(girlivePublisherSessionProvider.notifier)..start(key);

  ref.listenManual<List<ChatRoomPresence>>(
    presence,
    (_, next) => session.onPresence(key, next, myUserId: myUserId),
    fireImmediately: true,
  );

  ref.listenManual<PkBattleRemote?>(
    pkBattle,
    (prev, next) {
      session.onPkBattle(
        roomKey: key,
        battle: next,
        ownerUserId: ownerUserId,
        giftJetonDelta: 0,
      );
    },
  );
}
