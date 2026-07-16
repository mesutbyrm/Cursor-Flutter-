import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/pk/live_pk_invite_helper.dart';
import '../../domain/pk/pk_room_models.dart';
import '../../domain/pk/pk_unified_bridge.dart';
import '../../../voice_hub/domain/pk/pk_invite_expiry.dart';
import '../../../voice_hub/presentation/widgets/pk/pk_invite_response_dialog.dart';
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
  final Set<String> _seenExpired = {};
  var _showing = false;

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
      final pendingIds = invites
          .where((i) => i.isPending && !i.isExpired)
          .map((i) => i.id)
          .toSet();
      _seen.removeWhere((id) => !pendingIds.contains(id));

      for (final inv in invites) {
        if (inv.isExpired) {
          if (_seenExpired.add(inv.id)) {
            showPkInviteExpiredSnackBar(context);
          }
          continue;
        }
        if (!inv.isPending) continue;
        final uid = user.id.trim();
        if (uid.isNotEmpty && inv.hostUserId == uid) continue;
        if (!_isRecipient(inv, uid)) continue;
        if (!_seen.add(inv.id)) continue;
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
      accept = await showPkInviteResponseDialog(
        context: context,
        challengerLabel: challenger,
        expiresAt: inv.expiresAt,
        timeoutSeconds: inv.timeoutSeconds,
      );
    } finally {
      _showing = false;
    }

    if (!mounted || accept == null) {
      if (accept == null && mounted) showPkInviteExpiredSnackBar(context);
      return;
    }
    try {
      await ref.read(pkUnifiedInviteProvider).respond(
            matchId: inv.id,
            accept: accept,
          );
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
      if (!mounted) return;
      if (isPkInviteExpireApiError(e)) {
        showPkInviteExpiredSnackBar(context);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
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
