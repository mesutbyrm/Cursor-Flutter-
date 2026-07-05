import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../video_call/presentation/video_call_provider.dart';
import '../services/dm_voice_call_service.dart';

/// Giden DM araması kabul edildiğinde sesli görüşme ekranını açar.
class DmVoiceCallHost extends ConsumerWidget {
  const DmVoiceCallHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<DmOutgoingCallState?>(dmOutgoingCallAcceptedProvider, (_, next) {
      if (next == null || !context.mounted) return;
      ref.read(videoCallProvider.notifier).setPresenting(true);
      context.push(
        '/dm-voice-call',
        extra: {
          'peerName': next.peerName,
          'channelId': next.channelId,
        },
      );
      ref.read(dmOutgoingCallAcceptedProvider.notifier).state = null;
    });
    return child;
  }
}
