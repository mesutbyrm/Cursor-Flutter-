import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cosmic_background.dart';
import '../../live/presentation/providers/live_providers.dart';
import 'voice_rooms_body.dart';

class VoiceRoomsHubPage extends ConsumerWidget {
  const VoiceRoomsHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => LinearGradient(
            colors: [
              AppTheme.accentGold,
              AppTheme.accent,
            ],
          ).createShader(b),
          child: const Text(
            'Sohbet odaları',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
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
          CosmicBackground(),
          VoiceRoomsBody(),
        ],
      ),
    );
  }
}
