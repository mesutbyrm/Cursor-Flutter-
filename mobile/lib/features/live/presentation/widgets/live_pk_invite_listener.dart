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
import '../providers/live_invite_dedup_provider.dart';
import '../providers/live_pk_invite_signal_provider.dart';
import '../providers/live_providers.dart';
import '../providers/live_video_pk_provider.dart';
import '../utils/open_host_broadcast_room.dart';

/// Canlı yayın PK davetleri — stream SSE + `GET /api/video-streams/{id}/pk-battle`.
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

  static const _dialogTimeout = Duration(seconds: 30);

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
    return null;
  }

  bool _isRecipient(PkBattleRemote battle, String userId, String myStreamId) {
    if (userId.isEmpty) return false;
    return isLivePkInviteRecipientBattle(
      battle,
      myUserId: userId,
      myStreamId: myStreamId,
    );
  }

  Future<void> _processPendingInvites() async {
    if (_showing || !mounted) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    try {
      final api = ref.read(pkBattleRemoteDataSourceProvider);
      final owned = _ownedLiveStreams(user.id);
      if (owned.isEmpty) return;

      // Canlı 1v1 PK — ana backend `GET /api/video-streams/{id}/pk-battle` (tek kaynak).
      for (final stream in owned) {
        final battle = await api.fetchStreamBattle(stream.id);
        if (battle == null || battle.isEnded) continue;
        if (!battle.isPending) continue;
        if (battle.challengerId == user.id) continue;
        if (!_isRecipient(battle, user.id, stream.id)) continue;
        final inviteId = battle.effectiveId;
        if (inviteId.isEmpty ||
            !ref
                .read(liveInviteDedupProvider.notifier)
                .tryMark(livePkInviteDedupKey(inviteId))) {
          continue;
        }
        PkEventLog.incomingRequest(inviteId: inviteId);
        await _showDialog(battle, stream.id);
        return;
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
    final challenger =
        battle.challenger?.displayName?.trim() ?? 'Yayıncı';

    bool? accept;
    try {
      accept = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A0F2E),
          title: const Row(
            children: [
              Text('🔥 ', style: TextStyle(fontSize: 22)),
              Text('PK Daveti', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(
            '$challenger seninle PK yapmak istiyor.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Reddet'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Kabul Et'),
            ),
          ],
        ),
      ).timeout(
        _dialogTimeout,
        onTimeout: () {
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context, null);
          }
          return null;
        },
      );
    } on TimeoutException {
      accept = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PK daveti süresi doldu')),
        );
      }
    } finally {
      _showing = false;
    }

    // Dialog timeout / dismiss — backend pending state korunur; otomatik reject yok.
    if (!mounted || accept == null) return;

    final remote = ref.read(pkBattleRemoteProvider.notifier);
    final pkNotifier = ref.read(liveVideoPkProvider(myStreamId).notifier);
    try {
      if (accept) {
        PkEventLog.acceptStart(inviteId: battle.effectiveId);
        await remote.accept(battle.effectiveId, streamId: myStreamId);
        await pkNotifier.refresh();
        PkEventLog.acceptSuccess(battleId: battle.effectiveId);
        await openHostBroadcastRoomIfNeeded(
          ref: ref,
          context: context,
          streamId: myStreamId,
        );
      } else {
        PkEventLog.reject(inviteId: battle.effectiveId);
        await remote.reject(battle.effectiveId, streamId: myStreamId);
        await pkNotifier.refresh();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept ? 'PK kabul edildi' : 'PK daveti reddedildi',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
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
