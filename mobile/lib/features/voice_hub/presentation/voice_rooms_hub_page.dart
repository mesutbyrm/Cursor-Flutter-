import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../live/presentation/providers/live_providers.dart';
import '../../../core/theme/app_theme.dart';
import 'voice_rooms_body.dart';

class VoiceRoomsHubPage extends ConsumerWidget {
  const VoiceRoomsHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [AppTheme.accentSecondary, AppTheme.accent],
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _VoiceHubBackdrop(),
          const VoiceRoomsBody(),
        ],
      ),
    );
  }
}

class _VoiceHubBackdrop extends StatelessWidget {
  const _VoiceHubBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.background,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF181028),
            AppTheme.background,
            const Color(0xFF081820),
          ],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.2, -0.45),
            radius: 0.9,
            colors: [
              AppTheme.accent.withValues(alpha: 0.14),
              Colors.transparent,
            ],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
