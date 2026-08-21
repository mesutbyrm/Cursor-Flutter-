import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../data/datasources/feed_remote_datasource.dart';
import '../../data/repositories/feed_repository_impl.dart';

final feedRemoteProvider = Provider<FeedRemoteDataSource>((ref) {
  return FeedRemoteDataSource(ref.watch(dioProvider));
});

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepositoryImpl(ref.watch(feedRemoteProvider));
});

@Deprecated('Use socialNotifierProvider — feed and social share one notifier.')
class FeedNotifier extends AsyncNotifier<List<PostEntity>> {
  int _page = 1;
  bool _end = false;
  bool _loadingMore = false;
  final Set<String> _viewedPostIds = {};

  @override
  Future<List<PostEntity>> build() async {
    _page = 1;
    _end = false;
    _viewedPostIds.clear();
    return ref.read(feedRepositoryProvider).fetchFeed(page: _page);
  }

  Future<void> refresh() async {
    final previous = state;
    state = const AsyncLoading<List<PostEntity>>().copyWithPrevious(previous);
    state = await AsyncValue.guard(() async {
      _page = 1;
      _end = false;
      _viewedPostIds.clear();
      return ref.read(feedRepositoryProvider).fetchFeed(page: 1);
    });
  }

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || _end || _loadingMore) return;
    _loadingMore = true;
    final nextPage = _page + 1;
    try {
      final more =
          await ref.read(feedRepositoryProvider).fetchFeed(page: nextPage);
      if (more.isEmpty) {
        _end = true;
        return;
      }
      _page = nextPage;
      state = AsyncValue.data([...cur, ...more]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _loadingMore = false;
    }
  }

  void toggleLike(String postId) {
    state.whenData((list) {
      state = AsyncValue.data(
        list.map((p) {
          if (p.id != postId) return p;
          final liked = !p.isLiked;
          final delta = liked ? 1 : -1;
          final nextLikes = (p.likesCount + delta).clamp(0, 999999999);
          return p.copyWith(
            isLiked: liked,
            likedByMe: liked,
            likesCount: nextLikes,
          );
        }).toList(),
      );
    });
  }

  void registerView(String postId) {
    if (_viewedPostIds.contains(postId)) return;
    _viewedPostIds.add(postId);
    state.whenData((list) {
      state = AsyncValue.data(
        list.map((p) {
          if (p.id != postId) return p;
          return p.copyWith(viewsCount: p.viewsCount + 1);
        }).toList(),
      );
    });
  }

  void addComment(String postId) {
    state.whenData((list) {
      state = AsyncValue.data(
        list.map((p) {
          if (p.id != postId) return p;
          return p.copyWith(commentsCount: p.commentsCount + 1);
        }).toList(),
      );
    });
  }

  /// Backend fal paylaşımını ana akışın başına ekle (dedupe).
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

  @Deprecated('Backend POST /api/social/posts kullanın')
  void addLocalPost(String caption) {}
}

@Deprecated('Use socialNotifierProvider')
final feedNotifierProvider =
    AsyncNotifierProvider<FeedNotifier, List<PostEntity>>(FeedNotifier.new);
