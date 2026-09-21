import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_follow.dart';
import '../models/user_block.dart';

class SocialFeaturesService {
  final _baseUrl = 'https://canlifal.com/api';

  Future<void> follow(String userId, String targetUserId) async {
    final response = await Future.delayed(const Duration(milliseconds: 300));
    return response;
  }

  Future<void> unfollow(String userId, String targetUserId) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<List<UserFollow>> getFollowing(String userId, {int limit = 20, int offset = 0}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  Future<List<UserFollow>> getFollowers(String userId, {int limit = 20, int offset = 0}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  Future<bool> isFollowing(String userId, String targetUserId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return false;
  }

  Future<void> block(String userId, String targetUserId, {String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> unblock(String userId, String targetUserId) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<List<UserBlock>> getBlockedUsers(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  Future<bool> isBlocked(String userId, String targetUserId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return false;
  }
}

final socialFeaturesServiceProvider = Provider((ref) => SocialFeaturesService());

final followingProvider = FutureProvider.family<List<UserFollow>, (int, int)>((ref, params) async {
  final service = ref.watch(socialFeaturesServiceProvider);
  return service.getFollowing('', limit: params.$1, offset: params.$2);
});

final followersProvider = FutureProvider.family<List<UserFollow>, (int, int)>((ref, params) async {
  final service = ref.watch(socialFeaturesServiceProvider);
  return service.getFollowers('', limit: params.$1, offset: params.$2);
});

final blockedUsersProvider = FutureProvider<List<UserBlock>>((ref) async {
  final service = ref.watch(socialFeaturesServiceProvider);
  return service.getBlockedUsers('');
});

class FollowNotifier extends StateNotifier<AsyncValue<void>> {
  FollowNotifier(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  Future<void> follow(String userId, String targetUserId) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(socialFeaturesServiceProvider);
      await service.follow(userId, targetUserId);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final followNotifierProvider = StateNotifierProvider<FollowNotifier, AsyncValue<void>>((ref) {
  return FollowNotifier(ref);
});

class BlockNotifier extends StateNotifier<AsyncValue<void>> {
  BlockNotifier(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  Future<void> block(String userId, String targetUserId, {String? reason}) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(socialFeaturesServiceProvider);
      await service.block(userId, targetUserId, reason: reason);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final blockNotifierProvider = StateNotifierProvider<BlockNotifier, AsyncValue<void>>((ref) {
  return BlockNotifier(ref);
});
