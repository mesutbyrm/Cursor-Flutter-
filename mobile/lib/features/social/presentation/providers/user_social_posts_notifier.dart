import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../feed/domain/entities/post_entity.dart';
import '../../domain/repositories/social_repository.dart';
import 'social_providers.dart';

class UserSocialPostsNotifier
    extends FamilyAsyncNotifier<List<PostEntity>, String> {
  int _page = 1;
  bool _end = false;
  bool _loadingMore = false;

  @override
  Future<List<PostEntity>> build(String userId) async {
    _page = 1;
    _end = false;
    final bundle = await ref
        .read(socialRepositoryProvider)
        .fetchPostsByUserPage(userId, page: 1);
    _end = !bundle.hasMore;
    return bundle.posts;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      _page = 1;
      _end = false;
      final bundle = await ref
          .read(socialRepositoryProvider)
          .fetchPostsByUserPage(arg, page: 1);
      _end = !bundle.hasMore;
      return bundle.posts;
    });
  }

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || _end || _loadingMore) return;
    _loadingMore = true;
    final nextPage = _page + 1;
    try {
      final bundle = await ref
          .read(socialRepositoryProvider)
          .fetchPostsByUserPage(arg, page: nextPage);
      if (bundle.posts.isEmpty) {
        _end = true;
        return;
      }
      _page = nextPage;
      _end = !bundle.hasMore;
      state = AsyncValue.data([...cur, ...bundle.posts]);
    } finally {
      _loadingMore = false;
    }
  }

  bool get hasMore => !_end;
}

final userSocialPostsNotifierProvider = AsyncNotifierProvider.family<
    UserSocialPostsNotifier, List<PostEntity>, String>(
  UserSocialPostsNotifier.new,
);
