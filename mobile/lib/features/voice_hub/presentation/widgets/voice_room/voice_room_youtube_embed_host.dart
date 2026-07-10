import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// DJ müziği artık just_audio stream ile çalıyor — YouTube IFrame kullanılmıyor.
class VoiceRoomYoutubeEmbedHost extends ConsumerWidget {
  const VoiceRoomYoutubeEmbedHost({
    super.key,
    required this.roomKey,
    this.compact = false,
  });

  final String roomKey;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox.shrink();
  }
}
