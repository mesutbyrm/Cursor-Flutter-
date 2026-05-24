import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../live/presentation/providers/live_providers.dart';
import 'theme/voice_room_tokens.dart';
import 'voice_rooms_body.dart';

/// Sesli sohbet odaları — keşfet ekranı.
class VoiceRoomsHubPage extends ConsumerWidget {
  const VoiceRoomsHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: VoiceRoomTokens.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (b) => VoiceRoomTokens.neonRing.createShader(b),
          child: const Text(
            'Sesli Sohbet',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: () => ref.invalidate(voiceRoomsProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: const Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: BoxDecoration(gradient: VoiceRoomTokens.roomGradient)),
          VoiceRoomsBody(),
        ],
      ),
    );
  }
}
