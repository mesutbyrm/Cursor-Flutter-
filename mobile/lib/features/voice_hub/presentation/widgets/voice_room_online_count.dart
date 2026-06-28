import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/voice_room_entity.dart';
import '../providers/voice_rooms_presence_provider.dart';

/// Oda çevrimiçi sayısı — yalnızca ilgili oda presence değişince rebuild.
class VoiceRoomOnlineCount extends ConsumerWidget {
  const VoiceRoomOnlineCount({
    super.key,
    required this.room,
    required this.builder,
  });

  final VoiceRoomEntity room;
  final Widget Function(BuildContext context, int count) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      voiceRoomsPresenceProvider.select((p) => p.countFor(room)),
    );
    return builder(context, count);
  }
}
