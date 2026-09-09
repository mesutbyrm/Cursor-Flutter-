import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/chat_room_providers.dart';
import '../../providers/room_fragment_providers.dart';
import '../../providers/voice_room_mention_notice_provider.dart';
import 'voice_room_mention_notice_banner.dart';
import 'voice_room_reconnect_banner.dart';

/// SSE kopması + mention banner — basic ve RTC sohbet katmanı üstü.
class VoiceRoomConnectionOverlays extends ConsumerWidget {
  const VoiceRoomConnectionOverlays({
    super.key,
    required this.roomKey,
    this.mentionTop = 8,
    this.onMentionTap,
  });

  final String roomKey;
  final double mentionTop;
  /// Mention banner dokunuldu — mesaj kutusuna odaklan + @etiket.
  final void Function(String fromName)? onMentionTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(voiceRoomConnectionSliceProvider(roomKey));
    final mention = ref.watch(voiceRoomMentionNoticeProvider);
    final showReconnect = !conn.sseConnected && conn.selfInRoom;
    if (!showReconnect && mention == null) return const SizedBox.shrink();
    final mentionOffset = showReconnect ? mentionTop + 44 : mentionTop;

    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (showReconnect)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: VoiceRoomReconnectBanner(
                message: 'Ses bağlantısı yeniden kuruluyor…',
                onRetry: () {
                  ref
                      .read(voiceRoomLiveProvider(roomKey).notifier)
                      .resyncAfterSseReconnect();
                },
              ),
            ),
          if (mention != null)
            Positioned(
              top: mentionOffset,
              left: 0,
              right: 0,
              child: VoiceRoomMentionNoticeBanner(
                dismissKey: mention.seq,
                fromName: mention.fromName,
                preview: mention.messagePreview,
                onDismiss: () =>
                    ref.read(voiceRoomMentionNoticeProvider.notifier).clear(),
                onTap: onMentionTap == null
                    ? null
                    : () {
                        onMentionTap!(mention.fromName);
                        ref
                            .read(voiceRoomMentionNoticeProvider.notifier)
                            .clear();
                      },
              ),
            ),
        ],
      ),
    );
  }
}
