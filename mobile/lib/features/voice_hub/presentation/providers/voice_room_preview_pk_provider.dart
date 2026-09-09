import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/pk/pk_battle_remote_models.dart';
import 'pk_battle_remote_provider.dart';

/// Oda önizleme — aktif veya bekleyen PK (GET `/api/chat/rooms/{id}/pk`).
final voiceRoomPreviewPkProvider =
    FutureProvider.autoDispose.family<PkBattleRemote?, String>(
  (ref, roomId) async {
    final id = roomId.trim();
    if (id.isEmpty) return null;
    try {
      final battle = await ref
          .read(pkBattleRemoteDataSourceProvider)
          .fetchRoomBattle(id);
      if (battle == null || battle.isEnded) return null;
      return battle;
    } catch (_) {
      return null;
    }
  },
);
