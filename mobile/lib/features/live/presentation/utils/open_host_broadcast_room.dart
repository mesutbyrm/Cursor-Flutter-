import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/host_live_stream_recovery.dart';
import '../../domain/entities/live_broadcast_session.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../providers/live_providers.dart';

/// PK kabul sonrası yayıncıyı aktif yayın odasına yönlendirir.
Future<bool> openHostBroadcastRoomIfNeeded({
  required WidgetRef ref,
  required BuildContext context,
  required String streamId,
}) async {
  final id = streamId.trim();
  if (id.isEmpty || !context.mounted) return false;

  final recovered = await HostLiveStreamRecovery.loadIfValid();
  if (recovered != null && recovered.streamId?.trim() == id) {
    if (!context.mounted) return false;
    await context.push('/live/room', extra: recovered);
    return true;
  }

  final user = ref.read(authControllerProvider).valueOrNull;
  if (user == null) return false;

  LiveStreamEntity? stream;
  final streams = ref.read(liveStreamsProvider).valueOrNull ?? const [];
  for (final s in streams) {
    if (s.id == id) {
      stream = s;
      break;
    }
  }

  final title = stream?.title.trim().isNotEmpty == true
      ? stream!.title.trim()
      : 'Canlı yayın';
  final category = stream?.category?.trim().isNotEmpty == true
      ? stream!.category!.trim()
      : 'Sohbet';

  final session = LiveBroadcastSession.demoHost(
    title: title,
    category: category,
    tags: stream?.tags ?? const [],
    streamerName: user.display,
    streamerHandle: user.username,
    avatarUrl: user.avatarUrl,
    coverImageUrl: stream?.thumbnailUrl,
  ).copyWith(
    streamId: id,
    hostUserId: user.id,
  );

  if (!context.mounted) return false;
  await context.push('/live/room', extra: session);
  return true;
}
