import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../data/services/voice_room_socket_helper.dart';
import 'pk_battle_remote_provider.dart';

/// Sahip olunan sesli odalar için global PK socket — HTTP polling yok.
final voicePkOwnedRoomsSocketProvider = Provider<void>((ref) {
  void sync() {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      ref.read(pkBattleRemoteProvider.notifier).disconnectOwnedRoomsSocket();
      return;
    }
    final rooms = ref.read(voiceRoomsProvider).valueOrNull ?? const [];
    final keys = _ownedRoomKeys(rooms, user.id);
    if (keys.isEmpty) {
      ref.read(pkBattleRemoteProvider.notifier).disconnectOwnedRoomsSocket();
      return;
    }
    ref.read(pkBattleRemoteProvider.notifier).connectOwnedRooms(keys);
  }

  ref.listen(voiceRoomsProvider, (_, __) => sync());
  ref.listen(authControllerProvider, (_, __) => sync());
  ref.onDispose(() {
    ref.read(pkBattleRemoteProvider.notifier).disconnectOwnedRoomsSocket();
  });
  Future.microtask(sync);
});

List<String> _ownedRoomKeys(List<VoiceRoomEntity> rooms, String userId) {
  if (userId.isEmpty) return const [];
  final out = <String>[];
  for (final room in rooms) {
    if ((room.ownerId?.trim() ?? '') != userId) continue;
    final primary =
        room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id.trim();
    if (primary.isEmpty) continue;
    for (final k in VoiceRoomSocketHelper.joinKeys(
      primary: primary,
      alternate: room.slug,
    )) {
      if (!out.contains(k)) out.add(k);
    }
  }
  return out;
}
