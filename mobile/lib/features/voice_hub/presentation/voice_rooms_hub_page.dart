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
      backgroundColor: VoiceRoomTokens.bgDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(decoration: BoxDecoration(gradient: VoiceRoomTokens.roomGradient)),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Geri',
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/feed');
                          }
                        },
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      Expanded(
                        child: ShaderMask(
                          shaderCallback: (b) =>
                              VoiceRoomTokens.neonRing.createShader(b),
                          child: Text(
                            'Sesli Sohbet',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: titleSize,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Yenile',
                        onPressed: () => ref.invalidate(voiceRoomsProvider),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                ),
                const Expanded(child: VoiceRoomsBody()),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
