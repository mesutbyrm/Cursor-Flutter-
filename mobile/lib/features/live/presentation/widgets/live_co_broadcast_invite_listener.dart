import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../providers/co_broadcast_provider.dart';
import '../providers/live_co_broadcast_invite_signal_provider.dart';
import '../providers/live_invite_dedup_provider.dart';
import '../providers/pending_co_broadcast_join_provider.dart';
import '../providers/live_providers.dart';
import '../utils/open_live_stream.dart';

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

  bool _isPendingInvite(Map<String, dynamic> invite) {
    final status = (invite['status']?.toString() ?? 'pending').toLowerCase();
    return status == 'pending' || status == 'invited';
  }

  bool _inviteTargetsUser(Map<String, dynamic> invite, String userId) {
    final targets = <String?>{
      invite['inviteeId']?.toString(),
      invite['userId']?.toString(),
      invite['targetUserId']?.toString(),
      invite['guestUserId']?.toString(),
    };
    for (final t in targets) {
      if (t != null && t.trim() == userId) return true;
    }
    return false;
  }

  Future<void> _pollInvites() async {
    if (_showing || !mounted) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    try {
      await ref.read(coBroadcastProvider.notifier).refresh();
      final invites = ref.read(coBroadcastProvider).invites;
      for (final invite in invites) {
        if (!_isPendingInvite(invite)) continue;
        if (!_inviteTargetsUser(invite, user.id)) continue;
        final streamId = (invite['streamId'] ??
                invite['videoStreamId'] ??
                invite['liveStreamId'] ??
                '')
            .toString()
            .trim();
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
    final hostName = (invite['hostName'] ??
            invite['streamerName'] ??
            invite['fromName'] ??
            'Yayıncı')
        .toString();

    bool? accept;
    try {
      accept = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text(
            'Ortak yayın daveti',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '$hostName sizi ortak yayına davet etti.',
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
      );
    } finally {
      _showing = false;
    }

    if (!mounted || accept == null) return;
    try {
      if (accept) {
        await ref.read(coBroadcastProvider.notifier).acceptInvite(streamId);
        await ref.read(coBroadcastProvider.notifier).refreshStream(streamId);
        ref.read(pendingCoBroadcastJoinProvider.notifier).setPending(streamId);
        final nav = rootNavigatorKey.currentContext;
        if (nav != null && nav.mounted) {
          final streams =
              ref.read(liveStreamsProvider).valueOrNull ?? const [];
          LiveStreamEntity? stream;
          for (final s in streams) {
            if (s.id == streamId) {
              stream = s;
              break;
            }
          }
          if (stream != null) {
            await openLiveStreamSwipe(nav, ref, stream);
          }
        }
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
