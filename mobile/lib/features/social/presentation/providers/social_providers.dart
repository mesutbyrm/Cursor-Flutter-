import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/providers/auth_selectors.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../../data/datasources/social_remote_datasource.dart';
import '../../data/repositories/social_repository_impl.dart';
import '../../domain/entities/social_story_ring_entity.dart';
import '../../domain/repositories/social_repository.dart';

final socialRemoteProvider = Provider<SocialRemoteDataSource>((ref) {
  return SocialRemoteDataSource(ref.watch(dioProvider));
});

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepositoryImpl(
    ref.watch(socialRemoteProvider),
    currentUserId: ref.watch(currentUserIdProvider),
  );
});

class SocialNotifier extends AsyncNotifier<List<PostEntity>> {
  int _page = 1;
  bool _end = false;
  bool _loadingMore = false;

  @override
  Future<List<PostEntity>> build() async {
    _page = 1;
    _end = false;
    final bundle = await ref.read(socialRepositoryProvider).fetchPage(page: 1);
    _end = !bundle.hasMore;
    return bundle.posts;
  }

  Future<void> refresh() async {
    final previous = state;
    state = const AsyncValue<List<PostEntity>>.loading().copyWithPrevious(previous);
    state = await AsyncValue.guard(() async {
      _page = 1;
      _end = false;
      final bundle = await ref
          .read(socialRepositoryProvider)
          .fetchPage(page: 1, forceRefresh: true);
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
      final bundle =
          await ref.read(socialRepositoryProvider).fetchPage(page: nextPage);
      if (bundle.posts.isEmpty) {
        _end = true;
        return;
      }
      _page = nextPage;
      _end = !bundle.hasMore;
      state = AsyncValue.data([...cur, ...bundle.posts]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _loadingMore = false;
    }
  }

  void bumpCommentCount(String postId, {int delta = 1}) {
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncValue.data(cur.map((p) {
      if (p.id != postId) return p;
      return p.copyWith(commentsCount: p.commentsCount + delta);
    }).toList());
  }

  /// Backend fal paylaşımını akışın başına ekle (dedupe).
  void prependPost(PostEntity post) {
    if (post.id.isEmpty) return;
    final cur = state.valueOrNull;
    if (cur == null) {
      state = AsyncValue.data([post]);
      return;
    }
    if (cur.any((p) => p.id == post.id)) return;
    state = AsyncValue.data([post, ...cur]);
  }
}

final socialNotifierProvider =
    AsyncNotifierProvider<SocialNotifier, List<PostEntity>>(SocialNotifier.new);

/// Üst hikâye şeridi — canlifal.com `/api/stories`.
final socialStoryRingsProvider =
    FutureProvider<List<SocialStoryRingEntity>>((ref) async {
  return ref.read(socialRemoteProvider).fetchStoryRings();
});

/// Profil sayfası — kullanıcının paylaşımları (TikTok ızgara).
final userSocialPostsProvider =
    FutureProvider.family<List<PostEntity>, String>((ref, userId) async {
  return ref.read(socialRepositoryProvider).fetchPostsByUser(userId);
});
