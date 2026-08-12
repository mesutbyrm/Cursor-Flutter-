import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/providers/auth_selectors.dart';
import '../../../profile/presentation/providers/profile_hub_providers.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
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
  final Set<String> _viewedPostIds = {};

  bool get hasMore => !_end;
  bool get isLoadingMore => _loadingMore;

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
      // Sayfalama hatası mevcut feed'i silmesin.
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
    bumpCommentCount(postId);
  }

  void addLocalPost(String caption) {
    final user = ref.read(authControllerProvider).valueOrNull;
    final author = user ??
        const UserEntity(
          id: 'local_user',
          username: 'kullanici',
          displayName: 'Sen',
        );
    final post = PostEntity(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      author: author,
      caption: caption.trim().isEmpty ? null : caption.trim(),
      mediaUrl: null,
      likesCount: 0,
      commentsCount: 0,
      viewsCount: 0,
      isLiked: false,
      createdAt: DateTime.now(),
    );
    state.whenData((list) {
      state = AsyncValue.data([post, ...list]);
    });
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
