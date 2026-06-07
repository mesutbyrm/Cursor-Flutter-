import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../live/presentation/providers/live_providers.dart';
import 'theme/voice_room_tokens.dart';
import 'voice_rooms_body.dart';

/// Sesli sohbet odaları — keşfet ekranı.
class VoiceRoomsHubPage extends ConsumerWidget {
  const VoiceRoomsHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleSize = MediaQuery.sizeOf(context).width >= 600 ? 24.0 : 22.0;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/feed');
        }
      },
      child: Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: VoiceRoomTokens.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (b) => VoiceRoomTokens.neonRing.createShader(b),
          child: Text(
            'Sesli Sohbet',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: titleSize,
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
    ),
    );
  }
}
