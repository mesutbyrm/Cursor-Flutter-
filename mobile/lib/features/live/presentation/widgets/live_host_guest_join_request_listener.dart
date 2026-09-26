import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/host_live_stream_recovery.dart';
import '../providers/co_broadcast_provider.dart';
import '../providers/live_active_broadcast_provider.dart';
import '../providers/live_guest_join_signal_provider.dart';
import '../providers/live_guest_request_blocklist_provider.dart';
import '../providers/live_invite_dedup_provider.dart';
import '../providers/live_providers.dart';

/// Yayıncı — misafir katılma isteği (yayın odası dışında da poll + dialog).
class LiveHostGuestJoinRequestListener extends ConsumerStatefulWidget {
  const LiveHostGuestJoinRequestListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LiveHostGuestJoinRequestListener> createState() =>
      _LiveHostGuestJoinRequestListenerState();
}

class _LiveHostGuestJoinRequestListenerState
    extends ConsumerState<LiveHostGuestJoinRequestListener> {
  Timer? _pollTimer;
  var _showing = false;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _showing) return;
      unawaited(_pollHostGuestRequests());
    });
    Future.microtask(_pollHostGuestRequests);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> _pending(
    CoBroadcastState state,
    String streamId,
  ) {
    final blocklist = ref.read(liveGuestRequestBlocklistProvider(streamId));
    return state.joinRequests.where((r) {
      final status = (r['status']?.toString() ?? 'pending').toLowerCase();
      if (status != 'pending') return false;
      final userId = (r['userId'] ?? r['id'] ?? '').toString();
      return userId.isEmpty || !blocklist.contains(userId);
    }).toList();
  }

  Future<void> _pollHostGuestRequests() async {
    if (_showing || !mounted) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    final saved = await HostLiveStreamRecovery.loadIfValid();
    final streamId = saved?.streamId?.trim();
    if (streamId == null || streamId.isEmpty) return;
    if (saved!.hostUserId != null &&
        saved.hostUserId!.isNotEmpty &&
        saved.hostUserId != user.id) {
      return;
    }
    if (isLiveBroadcastRoomActiveForStream(ref, streamId)) return;

    try {
      final meta = await ref.read(liveRemoteProvider).fetchStream(streamId);
      if (meta == null || !meta.isLive) return;

      await ref.read(coBroadcastProvider.notifier).refreshStream(streamId);
      final pending = _pending(ref.read(coBroadcastProvider), streamId);
      if (pending.isEmpty) return;

      final req = pending.first;
      final userId = (req['userId'] ?? req['id'] ?? '').toString();
      final dedupKey = 'guest-join:$streamId:$userId';
      if (userId.isEmpty ||
          !ref.read(liveInviteDedupProvider.notifier).tryMark(dedupKey)) {
        return;
      }

      await _showGuestDialog(streamId, req);
    } catch (_) {}
  }

  Future<void> _showGuestDialog(
    String streamId,
    Map<String, dynamic> request,
  ) async {
    if (!mounted || _showing) return;
    _showing = true;
    try {
      final name = request['userName']?.toString() ??
          request['displayName']?.toString() ??
          'İzleyici';
      final userId = request['userId']?.toString() ?? '';
      if (userId.isEmpty) return;

      HapticFeedback.heavyImpact();
      final action = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Misafir isteği'),
          content: Text(
            '$name canlı yayına misafir olmak istiyor.\n'
            'Yayın odasına dönerek de yanıtlayabilirsiniz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'block'),
              child: const Text('Engelle'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'reject'),
              child: const Text('Reddet'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'approve'),
              child: const Text('Onayla'),
            ),
          ],
        ),
      );
      if (!mounted || action == null) return;

      final notifier = ref.read(coBroadcastProvider.notifier);
      if (action == 'approve') {
        await notifier.approveRequest(streamId: streamId, userId: userId);
        await notifier.refreshStream(streamId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name misafir olarak eklendi')),
          );
        }
      } else if (action == 'reject') {
        await notifier.rejectRequest(streamId: streamId, userId: userId);
      } else if (action == 'block') {
        ref
            .read(liveGuestRequestBlocklistProvider(streamId).notifier)
            .block(userId);
        await notifier.rejectRequest(streamId: streamId, userId: userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu kullanıcıdan misafir isteği alınmayacak'),
            ),
          );
        }
      }
    } finally {
      _showing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(liveGuestJoinSignalProvider, (_, __) {
      unawaited(_pollHostGuestRequests());
    });
    return widget.child;
  }
}
