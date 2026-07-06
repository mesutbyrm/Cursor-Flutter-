import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sesli odada video şeridi kapalı — yalnızca ses çalar.
class VoiceRoomSeatVideoStrip extends ConsumerWidget {
  const VoiceRoomSeatVideoStrip({
    super.key,
    required this.roomKey,
  });

  final String roomKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox.shrink();
  }
}
