import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/discover_tab_layout.dart';
import '../../live/presentation/providers/live_providers.dart';
import 'theme/voice_room_tokens.dart';
import 'voice_room_rtc_page.dart';

/// `/voice-room/:id` — oda `extra` yoksa canlifal.com listesinden yükler.
class VoiceRoomRoutePage extends ConsumerWidget {
  const VoiceRoomRoutePage({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(voiceRoomByIdProvider(roomId));

    return async.when(
      loading: () => const Scaffold(
        backgroundColor: VoiceRoomTokens.bgDeep,
        body: Center(child: DiscoverAccentLoader()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: VoiceRoomTokens.bgDeep,
        body: Center(
          child: DiscoverEmptyState(
            icon: Icons.headset_off_rounded,
            message: 'Oda yüklenemedi',
            actionLabel: 'Geri',
            action: () => context.go('/voice-rooms'),
          ),
        ),
      ),
      data: (room) {
        if (room == null) {
          return Scaffold(
            backgroundColor: VoiceRoomTokens.bgDeep,
            body: Center(
              child: DiscoverEmptyState(
                icon: Icons.meeting_room_outlined,
                message: 'Oda bulunamadı',
                actionLabel: 'Odalar',
                action: () => context.go('/voice-rooms'),
              ),
            ),
          );
        }
        return VoiceRoomRtcPage(room: room);
      },
    );
  }
}
