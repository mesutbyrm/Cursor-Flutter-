import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../live/presentation/providers/live_providers.dart';
import 'voice_rooms_body.dart';

class VoiceRoomsHubPage extends ConsumerWidget {
  const VoiceRoomsHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sohbet odaları'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: () => ref.invalidate(voiceRoomsProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: const VoiceRoomsBody(),
    );
  }
}
