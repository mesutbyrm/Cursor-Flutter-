import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/connectivity/connectivity_service.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/shorts_offline_action_queue.dart';
import '../providers/shorts_providers.dart';

/// Uygulama açılışında / feed'de çevrimdışı kuyruğu senkronize eder.
final shortsOfflineSyncProvider = Provider<void>((ref) {
  ref.listen<bool>(isOnlineProvider, (prev, next) {
    if (next == true) {
      unawaited(_flush(ref));
    }
  });
  unawaited(_flush(ref));
});

Future<void> _flush(Ref ref) async {
  await ShortsOfflineActionQueue.instance.flush(
    onAction: (action) async {
      final repo = ref.read(shortsRepositoryProvider);
      switch (action.type) {
        case ShortOfflineActionType.like:
          await repo.toggleLike(action.targetId);
        case ShortOfflineActionType.save:
          await repo.toggleSave(action.targetId);
        case ShortOfflineActionType.follow:
          final profile = ref.read(profileRepositoryProvider);
          if (action.liked) {
            await profile.follow(action.targetId);
          } else {
            await profile.unfollow(action.targetId);
          }
      }
    },
  );
}

Future<void> enqueueShortLike(WidgetRef ref, String videoId, bool liked) async {
  final online = ref.read(isOnlineProvider);
  if (!online) {
    await ShortsOfflineActionQueue.instance.enqueueLike(videoId, liked: liked);
    return;
  }
  await ref.read(shortsRepositoryProvider).toggleLike(videoId);
}

Future<void> enqueueShortSave(WidgetRef ref, String videoId, bool saved) async {
  final online = ref.read(isOnlineProvider);
  if (!online) {
    await ShortsOfflineActionQueue.instance.enqueueSave(videoId, saved: saved);
    return;
  }
  await ref.read(shortsRepositoryProvider).toggleSave(videoId);
}
