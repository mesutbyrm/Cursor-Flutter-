import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../gifts/data/gift_goal_remote_datasource.dart';
import '../../../gifts/domain/gift_goal.dart';
import '../../../gifts/presentation/providers/gift_goal_providers.dart';

/// Oda önizleme — aktif hediye hedefi (varsa).
final voiceRoomPreviewGoalProvider =
    FutureProvider.autoDispose.family<GiftGoal?, String>((ref, roomId) async {
  final id = roomId.trim();
  if (id.isEmpty) return null;
  try {
    final goals = await ref.read(giftGoalRemoteProvider).fetchGoals(
          context: 'voice_room',
          contextId: id,
        );
    for (final g in goals) {
      if (g.isActive) return g.withResolvedDeadline();
    }
    return null;
  } catch (_) {
    return null;
  }
});
