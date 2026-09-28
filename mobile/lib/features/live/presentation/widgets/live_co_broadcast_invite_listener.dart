import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/co_broadcast_provider.dart';
import '../providers/live_co_broadcast_invite_signal_provider.dart';
import '../providers/live_invite_dedup_provider.dart';
import '../widgets/broadcast_room/live_guest_broadcast_modals.dart';
import '../utils/co_broadcast_invite_actions.dart';

/// Ortak yayın (misafir) davetleri — yayın sayfası dışında da kabul ekranı.
class LiveCoBroadcastInviteListener extends ConsumerStatefulWidget {
  const LiveCoBroadcastInviteListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LiveCoBroadcastInviteListener> createState() =>
      _LiveCoBroadcastInviteListenerState();
}

class _LiveCoBroadcastInviteListenerState
    extends ConsumerState<LiveCoBroadcastInviteListener> {
  var _showing = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || _showing) return;
      unawaited(_pollInvites());
    });
    Future.microtask(_pollInvites);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _pollInvites() async {
    if (_showing || !mounted) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    try {
      await ref.read(coBroadcastProvider.notifier).refresh();
      final invites = ref.read(coBroadcastProvider).invites;
      for (final invite in invites) {
        if (!isPendingCoBroadcastInvite(invite, user.id)) continue;
        final streamId = coBroadcastInviteStreamId(invite);
        if (streamId.isEmpty) continue;
        final id = (invite['id'] ??
                invite['inviteId'] ??
                '$streamId:${invite['createdAt']}')
            .toString();
        if (id.isEmpty ||
            !ref
                .read(liveInviteDedupProvider.notifier)
                .tryMark(liveCoBroadcastInviteDedupKey(id))) {
          continue;
        }
        await _showInviteDialog(streamId, invite);
        return;
      }
    } catch (_) {}
  }

  Future<void> _showInviteDialog(
    String streamId,
    Map<String, dynamic> invite,
  ) async {
    if (!mounted || _showing) return;
    _showing = true;
    final hostName = coBroadcastInviteHostName(invite);

    bool? accept;
    try {
      accept = await showViewerGuestInviteModal(
        context: context,
        hostName: hostName,
      );
    } finally {
      _showing = false;
    }

    if (!mounted || accept == null) return;
    try {
      if (accept) {
        await acceptCoBroadcastInviteAndJoin(ref, streamId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ortak yayına katıldınız')),
          );
        }
      } else {
        await ref.read(coBroadcastProvider.notifier).rejectInvite(streamId);
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
    ref.listen(liveCoBroadcastInviteSignalProvider, (_, __) {
      unawaited(_pollInvites());
    });
    ref.listen(authControllerProvider, (prev, next) {
      if (prev?.valueOrNull == null && next.valueOrNull != null) {
        unawaited(_pollInvites());
      }
    });
    return widget.child;
  }
}
