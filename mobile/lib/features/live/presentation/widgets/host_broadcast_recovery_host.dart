import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/host_live_stream_recovery.dart';
import '../providers/live_providers.dart';
import '../utils/open_host_broadcast_room.dart';

/// Yayıncı uygulamada başka sekmede gezinirken açık kalan yayın için uyarı.
class HostBroadcastRecoveryHost extends ConsumerStatefulWidget {
  const HostBroadcastRecoveryHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<HostBroadcastRecoveryHost> createState() =>
      _HostBroadcastRecoveryHostState();
}

class _HostBroadcastRecoveryHostState
    extends ConsumerState<HostBroadcastRecoveryHost> {
  String? _lastPath;
  var _prompting = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final path =
        router.routerDelegate.currentConfiguration.uri.path;
    if (_lastPath != path) {
      _lastPath = path;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_maybePromptHostRecovery(path));
      });
    }
    return widget.child;
  }

  bool _onLiveRoomRoute(String path) =>
      path.startsWith('/live/room') || path.startsWith('/live/prep');

  Future<void> _maybePromptHostRecovery(String path) async {
    if (!mounted || _prompting || _onLiveRoomRoute(path)) return;
    final me = ref.read(authControllerProvider).valueOrNull;
    if (me == null) return;
    final saved = await HostLiveStreamRecovery.loadIfValid();
    if (saved == null || !mounted) return;
    final streamId = saved.streamId?.trim();
    if (streamId == null || streamId.isEmpty) return;
    if (saved.hostUserId != null &&
        saved.hostUserId!.isNotEmpty &&
        saved.hostUserId != me.id) {
      return;
    }
    final meta = await ref.read(liveRemoteProvider).fetchStream(streamId);
    if (meta == null || !meta.isLive) {
      await HostLiveStreamRecovery.clear();
      return;
    }
    if (!mounted || _prompting) return;
    _prompting = true;
    try {
      final choice = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Canlı yayın açık'),
          content: Text(
            'Yayınınız hâlâ devam ediyor (${saved.title}). '
            'Devam etmek mi, sonlandırmak mı istiyorsunuz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Sonlandır'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Devam et'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (choice == true) {
        await openHostBroadcastRoomIfNeeded(
          ref: ref,
          context: context,
          streamId: streamId,
        );
      } else {
        try {
          await ref.read(liveRepositoryProvider).endVideoStream(streamId);
        } catch (_) {}
        await HostLiveStreamRecovery.clear();
      }
    } finally {
      _prompting = false;
    }
  }
}
