import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/providers/auth_selectors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_hub_providers.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../../data/datasources/social_remote_datasource.dart';
import '../../data/repositories/social_repository_impl.dart';
import '../../domain/entities/social_comment_entity.dart';
import '../../domain/entities/social_story_ring_entity.dart';
import '../../domain/repositories/social_repository.dart';

final socialRemoteProvider = Provider<SocialRemoteDataSource>((ref) {
  return SocialRemoteDataSource(
    ref.watch(dioProvider),
    upload: ref.watch(cloudMediaUploadProvider),
  );
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
  String? _loadMoreError;
  final Set<String> _viewedPostIds = {};

  bool get hasMore => !_end;
  bool get isLoadingMore => _loadingMore;
  String? get loadMoreError => _loadMoreError;

  @override
  Future<List<PostEntity>> build() async {
    _page = 1;
    _end = false;
    _viewedPostIds.clear();
    final bundle = await ref.read(socialRepositoryProvider).fetchPage(page: 1);
    _end = !bundle.hasMore;
    return bundle.posts;
  }

  Future<void> refresh() async {
    final previous = state;
    _loadMoreError = null;
    state = const AsyncValue<List<PostEntity>>.loading().copyWithPrevious(previous);
    state = await AsyncValue.guard(() async {
      _page = 1;
      _end = false;
      _viewedPostIds.clear();
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
    _loadMoreError = null;
    state = AsyncValue.data(List<PostEntity>.from(cur));
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
    } catch (_) {
      _loadMoreError = 'Daha fazla gönderi yüklenemedi';
      state = AsyncValue.data(List<PostEntity>.from(cur));
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> retryLoadMore() => loadMore();

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

  void bumpShareCount(String postId, {int delta = 1}) {
    state.whenData((list) {
      state = AsyncValue.data(
        list.map((p) {
          if (p.id != postId) return p;
          return p.copyWith(shareCount: p.shareCount + delta);
        }).toList(),
      );
    });
  }

  void addComment(String postId) {
    bumpCommentCount(postId);
  }

  void reconcileLike(
    String postId, {
    required bool liked,
    required int likesCount,
  }) {
    state.whenData((list) {
      state = AsyncValue.data(
        list.map((p) {
          if (p.id != postId) return p;
          return p.copyWith(
            isLiked: liked,
            likedByMe: liked,
            likesCount: likesCount,
          );
        }).toList(),
      );
    });
  }

  @Deprecated('Backend POST /api/social/posts kullanın — local fake post yok')
  void addLocalPost(String caption) {
    // Üretimde fake local post enjekte edilmez.
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

  /// Gönderiyi akıştan kaldır (silme sonrası tam yenileme yerine).
  void removePost(String postId) {
    if (postId.isEmpty) return;
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncValue.data(cur.where((p) => p.id != postId).toList());
  }
}

final socialNotifierProvider =
    AsyncNotifierProvider<SocialNotifier, List<PostEntity>>(SocialNotifier.new);

/// Üst hikâye şeridi — canlifal.com `/api/stories`.
final socialStoryRingsProvider =
    FutureProvider<List<SocialStoryRingEntity>>((ref) async {
  final rings = await ref.read(socialRemoteProvider).fetchStoryRings();
  final me = ref.read(authControllerProvider).valueOrNull;
  if (me == null) return rings;
  return rings
      .map(
        (r) => r.user.id == me.id ? r.copyWith(isOwn: true) : r,
      )
      .toList();
});

/// Profil sayfası — kullanıcının paylaşımları (TikTok ızgara).
final userSocialPostsProvider =
    FutureProvider.family<List<PostEntity>, String>((ref, userId) async {
  return ref.read(socialRepositoryProvider).fetchPostsByUser(userId);
});

/// Tek gönderi detayı — kılavuz §9.10.
final postDetailProvider =
    FutureProvider.family<PostEntity?, String>((ref, postId) async {
  if (postId.trim().isEmpty) return null;
  return ref.read(socialRepositoryProvider).fetchPost(postId);
});

/// Gönderi yorumları — ekranlar arası paylaşımlı cache.
final postCommentsProvider =
    FutureProvider.family<List<SocialCommentEntity>, String>((ref, postId) async {
  if (postId.trim().isEmpty) return const [];
  return ref.read(socialRepositoryProvider).fetchComments(postId);
});
