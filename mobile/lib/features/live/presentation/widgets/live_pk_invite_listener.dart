import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/pk_event_log.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../voice_hub/domain/pk/pk_battle_remote_models.dart';
import '../../../voice_hub/presentation/providers/pk_battle_remote_provider.dart';
import '../../domain/pk/live_pk_invite_helper.dart';
import '../providers/live_pk_invite_signal_provider.dart';
import '../providers/live_pk_owned_streams_socket_provider.dart';
import '../providers/live_providers.dart';
import '../providers/live_video_pk_provider.dart';

/// Canlı yayın PK davetleri — ana backend (`/api/video-streams/*/pk-battle`).
class LivePkInviteListener extends ConsumerStatefulWidget {
  const LivePkInviteListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LivePkInviteListener> createState() =>
      _LivePkInviteListenerState();
}

class _LivePkInviteListenerState extends ConsumerState<LivePkInviteListener> {
  final Set<String> _seen = {};
  var _showing = false;
  Timer? _pollTimer;

  static const _dialogTimeout = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
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
      final streams = ref.read(liveStreamsProvider).valueOrNull ?? const [];
      final owned = streams
          .where((s) {
            if (!s.isLive) return false;
            final host = s.hostUserId?.trim() ?? '';
            return host.isNotEmpty && host == user.id;
          })
          .toList(growable: false);

      for (final stream in owned) {
        final battle = await api.fetchStreamBattle(stream.id);
        if (battle == null || battle.isEnded) continue;
        if (!battle.isPending) continue;
        if (!_isRecipient(battle, user.id, stream.id)) continue;
        if (battle.challengerId == user.id) continue;
        final inviteId = battle.effectiveId;
        if (inviteId.isEmpty || !_seen.add(inviteId)) continue;
        PkEventLog.incomingRequest(inviteId: inviteId);
        await _showDialog(battle, stream.id);
        return;
      }
    } catch (_) {}
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

    if (!mounted || accept == null) {
      if (accept == null && mounted) {
        try {
          await ref.read(pkBattleRemoteProvider.notifier).reject(
                battle.effectiveId,
                streamId: myStreamId,
              );
        } catch (_) {}
      }
      return;
    }

    final remote = ref.read(pkBattleRemoteProvider.notifier);
    try {
      if (accept) {
        PkEventLog.acceptStart(inviteId: battle.effectiveId);
        await remote.accept(battle.effectiveId, streamId: myStreamId);
        PkEventLog.acceptSuccess(battleId: battle.effectiveId);
        await ref
            .read(liveVideoPkProvider(myStreamId).notifier)
            .ingestRemoteBattle(battle.effectiveId);
      } else {
        PkEventLog.reject(inviteId: battle.effectiveId);
        await remote.reject(battle.effectiveId, streamId: myStreamId);
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
    ref.watch(livePkOwnedStreamsSocketProvider);
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
