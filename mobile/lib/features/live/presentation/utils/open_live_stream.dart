import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/live_entry_perf.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/live_broadcast_session.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../../domain/entities/live_swipe_feed_args.dart';
import '../providers/live_providers.dart';

/// TRTC oturumu hazırla — swipe ve tek yayın için ortak.
Future<LiveBroadcastSession> buildLiveSessionForStream(
  WidgetRef ref,
  LiveStreamEntity stream,
) async {
  final user = ref.read(authControllerProvider).valueOrNull;
  if (user == null) {
    throw StateError('İzlemek için giriş yapın');
  }

  final trtc = await LiveEntryPerf.fetchTrtcParallel(
    ref: ref,
    streamId: stream.id,
    role: 'audience',
    userId: user.id,
  );

  return LiveBroadcastSession.fromStream(stream).copyWith(
    streamId: stream.id,
    trtc: trtc,
    hostUserId: stream.hostUserId,
  );
}

Future<void> _validateStreamStillLive(
  WidgetRef ref,
  BuildContext context,
  LiveStreamEntity stream,
) async {
  if (!Env.useMobileAuth) return;
  try {
    final meta = await ref.read(liveRemoteProvider).fetchStream(stream.id);
    if (meta != null && !meta.isLive && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yayın sona erdi')),
      );
      ref.invalidate(liveStreamsProvider);
      if (context.canPop()) context.pop();
    }
  } catch (_) {}
}

/// Tek yayın — premium tam ekran oda.
Future<void> openLiveStreamNative(
  BuildContext context,
  WidgetRef ref,
  LiveStreamEntity stream, {
  bool swipeMode = true,
}) async {
  if (!stream.isLive) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bu yayın artık aktif değil')),
    );
    return;
  }

  final user = ref.read(authControllerProvider).valueOrNull;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('İzlemek için giriş yapın')),
    );
    return;
  }

  LiveEntryPerf.prewarmOnStreamTap(ref, stream);

  try {
    if (swipeMode) {
      unawaited(_validateStreamStillLive(ref, context, stream));
      await openLiveStreamSwipe(context, ref, stream);
      return;
    }

    if (!context.mounted) return;
    final session = LiveBroadcastSession.fromStream(stream);
    unawaited(_validateStreamStillLive(ref, context, stream));
    context.push('/live/room', extra: session);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }
}

/// Dikey swipe — tüm canlı yayınlar arasında geçiş.
Future<void> openLiveStreamSwipe(
  BuildContext context,
  WidgetRef ref,
  LiveStreamEntity stream,
) async {
  final all = ref.read(liveStreamsProvider).valueOrNull ?? [stream];
  var live = all.where((s) => s.isLive).toList();
  if (live.isEmpty) live.add(stream);

  var index = live.indexWhere((s) => s.id == stream.id);
  if (index < 0) {
    live = [stream, ...live];
    index = 0;
  }

  if (!context.mounted) return;
  context.push(
    '/live/swipe',
    extra: LiveSwipeFeedArgs(streams: live, initialIndex: index),
  );
}
