import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../live/presentation/providers/live_providers.dart';
import 'theme/voice_room_tokens.dart';
import 'voice_room_rtc_page.dart';
import 'widgets/voice_room_error_boundary.dart';

/// `/voice-room/:id` — oda `extra` yoksa canlifal.com listesinden yükler.
class VoiceRoomRoutePage extends ConsumerWidget {
  const VoiceRoomRoutePage({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(voiceRoomByIdProvider(roomId));

    return async.when(
      loading: () => Scaffold(
        backgroundColor: VoiceRoomTokens.bgDeep,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: VoiceRoomTokens.neonPurple),
              const SizedBox(height: 16),
              Text(
                'Oda yükleniyor…',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
      error: (e, _) => VoiceRoomLoadErrorView(
        title: 'Oda yüklenemedi',
        message: ApiException.userMessage(e),
        onBack: () => context.go('/voice-rooms'),
        onRetry: () => ref.invalidate(voiceRoomByIdProvider(roomId)),
      ),
      data: (room) {
        if (room == null) {
          return VoiceRoomLoadErrorView(
            title: 'Oda bulunamadı',
            message: 'Bu oda kaldırılmış veya ID hatalı olabilir ($roomId).',
            onBack: () => context.go('/voice-rooms'),
          );
        }
        final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
        return VoiceRoomErrorBoundary(
          roomId: key,
          child: VoiceRoomRtcPage(room: room),
        );
      },
    );
  }
}
