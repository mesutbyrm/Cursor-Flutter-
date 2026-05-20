import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../trtc/presentation/providers/trtc_providers.dart';
import '../../domain/entities/live_broadcast_session.dart';
import '../../domain/entities/live_stream_entity.dart';

/// Canlı yayını native TRTC ile açar (WebView yok).
Future<void> openLiveStreamNative(
  BuildContext context,
  WidgetRef ref,
  LiveStreamEntity stream,
) async {
  if (!stream.isLive) return;

  final user = ref.read(authControllerProvider).valueOrNull;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('İzlemek için giriş yapın')),
    );
    return;
  }

  try {
    final cred = await ref.read(trtcRemoteProvider).fetchUserSig(
          userId: user.id,
          roomId: stream.id,
        );
    if (!context.mounted) return;
    context.push(
      '/live/room',
      extra: LiveBroadcastSession.fromStream(stream).copyWith(
        streamId: stream.id,
        trtc: cred,
        hostUserId: stream.hostUserId,
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }
}
