import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../live/domain/entities/live_stream_entity.dart';
import '../../../live/presentation/utils/open_live_stream.dart';
import '../../domain/entities/psychic_entity.dart';

/// Falcı kartı tıklama — profil veya (API streamId varsa) canlı yayın.
Future<void> openPsychicCardDestination(
  BuildContext context,
  WidgetRef ref,
  PsychicEntity psychic,
) async {
  final streamId = psychic.liveStreamId?.trim();
  if (streamId != null && streamId.isNotEmpty) {
    final stream = LiveStreamEntity(
      id: streamId,
      title: psychic.name,
      streamerName: psychic.name,
      thumbnailUrl: psychic.avatarUrl,
      category: psychic.displayCategory,
      isLive: true,
      hostUserId: psychic.userId ?? psychic.trtcUserId,
    );
    await openLiveStreamNative(context, ref, stream);
    return;
  }
  if (!context.mounted) return;
  context.push('/canli-falcilar/${psychic.id}');
}
