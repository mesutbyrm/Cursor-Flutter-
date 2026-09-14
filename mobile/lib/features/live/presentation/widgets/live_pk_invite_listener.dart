import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/pk_event_log.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../voice_hub/domain/pk/pk_battle_remote_models.dart';
import '../../../voice_hub/presentation/providers/pk_battle_remote_provider.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../../domain/pk/live_pk_invite_helper.dart';
import '../providers/live_active_broadcast_provider.dart';
import '../providers/live_invite_dedup_provider.dart';
import '../providers/live_pk_invite_signal_provider.dart';
import '../providers/live_providers.dart';
import '../providers/live_video_pk_provider.dart';
import '../../../pk/presentation/providers/pk_session_notifier.dart';
import '../providers/pk_session_phase_provider.dart';
import '../utils/live_pk_invite_flow.dart';
import '../../domain/pk/pk_unified_bridge.dart';

/// Canlı yayın PK davetleri — stream SSE + poll + `GET /api/pk/me/invites`.
class LivePkInviteListener extends ConsumerStatefulWidget {
  const LivePkInviteListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LivePkInviteListener> createState() =>
      _LivePkInviteListenerState();
}

class _LivePkInviteListenerState extends ConsumerState<LivePkInviteListener> {
  var _showing = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _showing) return;
      unawaited(_processPendingInvites());
    });
    Future.microtask(_processPendingInvites);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  List<LiveStreamEntity> _ownedLiveStreams(String userId) {
    final streams = ref.read(liveStreamsProvider).valueOrNull ?? const [];
    return streams
        .where((s) {
          if (!s.isLive) return false;
          final host = s.hostUserId?.trim() ?? '';
          return host.isNotEmpty && host == userId;
        })
        .toList(growable: false);
  }

  String? _recipientStreamId(
    PkBattleRemote battle,
    String userId,
    List<LiveStreamEntity> owned,
  ) {
    for (final stream in owned) {
      if (isLivePkInviteRecipientBattle(
        battle,
        myUserId: userId,
        myStreamId: stream.id,
      )) {
        return stream.id;
      }
    }
    final host = battle.liveStreamId?.trim() ?? '';
    final opp = battle.opponentLiveStreamId?.trim() ?? '';
    for (final stream in owned) {
      if (stream.id == host || stream.id == opp) return stream.id;
    }
    return null;
  }

  Future<void> _tryShowBattle(
    PkBattleRemote battle,
    String userId,
    List<LiveStreamEntity> owned,
  ) async {
    if (!battle.isPending || battle.isEnded) return;
    if (battle.challengerId == userId) return;
    final streamId = _recipientStreamId(battle, userId, owned);
    if (streamId == null || streamId.isEmpty) return;
    if (!isLivePkInviteRecipientBattle(
      battle,
      myUserId: userId,
      myStreamId: streamId,
    )) {
      return;
    }
    if (isLiveBroadcastRoomActiveForStream(ref, streamId)) {
      return;
    }
    final inviteId = battle.effectiveId;
    if (inviteId.isEmpty ||
        !ref
            .read(liveInviteDedupProvider.notifier)
            .tryMark(livePkInviteDedupKey(inviteId))) {
      return;
    }
    PkEventLog.incomingRequest(inviteId: inviteId);
    await _showDialog(battle, streamId);
  }

  Future<void> _processPendingInvites() async {
    if (_showing || !mounted) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    try {
      final api = ref.read(pkBattleRemoteDataSourceProvider);
      final owned = _ownedLiveStreams(user.id);

      for (final stream in owned) {
        final inRoom = isLiveBroadcastRoomActiveForStream(ref, stream.id);
        final battle = await api.fetchStreamBattle(stream.id);
        if (battle != null) {
          ref.read(liveVideoPkProvider(stream.id).notifier).applyRemoteBattle(
                pkBattleRemoteToBattleMap(battle, myStreamId: stream.id),
              );
          unawaited(ref.read(pkSessionProvider(
            PkSessionArgs(contextId: stream.id, kind: PkContextKind.live),
          ).notifier).loadState());
          if (!inRoom) {
            await _tryShowBattle(battle, user.id, owned);
            if (_showing) return;
          }
        }
      }

      final invites = await api.fetchMyInvites();
      for (final battle in invites) {
        if (!battle.isPending || battle.isEnded) continue;
        if (!isLiveStreamPkBattle(battle)) continue;
        ref.read(pkBattleRemoteProvider.notifier).ingestSseBattle(battle);
        final streamId = _recipientStreamId(battle, user.id, owned);
        if (streamId != null && streamId.isNotEmpty) {
          ref.read(liveVideoPkProvider(streamId).notifier).applyRemoteBattle(
                pkBattleRemoteToBattleMap(battle, myStreamId: streamId),
              );
        }
        await _tryShowBattle(battle, user.id, owned);
        if (_showing) return;
      }
    } catch (e, st) {
      assert(() {
        debugPrint('[LivePK] invite poll error: $e\n$st');
        return true;
      }());
    }
  }

  Future<void> _showDialog(PkBattleRemote battle, String myStreamId) async {
    if (!mounted || _showing) return;
    _showing = true;
    try {
      final map = pkBattleRemoteToBattleMap(battle, myStreamId: myStreamId);
      await showLiveStreamPkInviteDialog(
        context,
        ref,
        streamId: myStreamId,
        battle: map,
      );
    } finally {
      _showing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(livePkInviteSignalProvider, (_, __) {
      unawaited(_processPendingInvites());
    });
    ref.listen(authControllerProvider, (prev, next) {
      if (prev?.valueOrNull == null && next.valueOrNull != null) {
        unawaited(_processPendingInvites());
      }
    });
    return widget.child;
  }
}
