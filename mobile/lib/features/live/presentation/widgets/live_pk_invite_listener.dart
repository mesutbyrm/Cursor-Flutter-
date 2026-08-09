import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/pk_event_log.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/pk/live_pk_invite_helper.dart';
import '../../domain/pk/pk_room_models.dart';
import '../../domain/pk/pk_unified_bridge.dart';
import '../providers/live_pk_invite_signal_provider.dart';
import '../providers/live_pk_owned_streams_socket_provider.dart';
import '../providers/pk_room_providers.dart';

/// Uygulama genelinde bekleyen PK davetleri — Socket.IO + SSE; HTTP polling yok.
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

  static const _dialogTimeout = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    Future.microtask(_processPendingInvites);
  }

  bool _isRecipient(PkRoomMatch inv, String userId) {
    if (userId.isEmpty) return false;
    return isLivePkInviteRecipient(
      inv,
      myStreamId: '',
      myUserId: userId,
    );
  }

  Future<void> _processPendingInvites() async {
    if (_showing || !mounted) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    try {
      ref.invalidate(pkPendingInvitesProvider);
      final invites = await ref.read(pkRoomRemoteProvider).myInvites();
      final pendingIds =
          invites.where((i) => i.isPending).map((i) => i.id).toSet();
      _seen.removeWhere((id) => !pendingIds.contains(id));

      for (final inv in invites) {
        if (!inv.isPending) continue;
        final uid = user.id.trim();
        if (uid.isNotEmpty && inv.hostUserId == uid) continue;
        if (!_isRecipient(inv, uid)) continue;
        if (!_seen.add(inv.id)) continue;
        PkEventLog.incomingRequest(matchId: inv.id);
        await _showDialog(inv);
        break;
      }
    } catch (_) {}
  }

  Future<void> _showDialog(PkRoomMatch inv) async {
    if (!mounted || _showing) return;
    _showing = true;
    final battle = pkRoomMatchToBattleMap(
      inv,
      myUserId: ref.read(authControllerProvider).valueOrNull?.id,
    );
    final challenger = battle['leftName']?.toString() ?? 'Yayıncı';

    bool? accept;
    try {
      accept = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A0F2E),
          title: const Text('PK Daveti', style: TextStyle(color: Colors.white)),
          content: Text(
            '$challenger size PK daveti gönderdi.\nKabul ediyor musunuz?',
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
          await ref.read(pkUnifiedInviteProvider).respond(
                matchId: inv.id,
                accept: false,
              );
        } catch (_) {}
      }
      return;
    }
    try {
      if (accept) {
        PkEventLog.acceptStart(matchId: inv.id);
      } else {
        PkEventLog.reject(matchId: inv.id);
      }
      await ref.read(pkUnifiedInviteProvider).respond(
            matchId: inv.id,
            accept: accept,
          );
      if (accept) {
        PkEventLog.acceptSuccess(matchId: inv.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept ? 'PK kabul edildi — yayın odanıza dönün' : 'PK reddedildi',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
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
    ref.listen(pkPendingInvitesProvider, (_, __) {
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
