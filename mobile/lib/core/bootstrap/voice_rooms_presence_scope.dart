import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/voice_hub/presentation/providers/voice_rooms_presence_provider.dart';

/// SSE presence — kabuk rebuild'lerinden izole; yalnızca bu alt ağaç yenilenir.
class VoiceRoomsPresenceScope extends ConsumerWidget {
  const VoiceRoomsPresenceScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(voiceRoomsPresenceProvider);
    return child;
  }
}
