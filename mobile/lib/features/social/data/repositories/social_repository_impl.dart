import '../../../feed/domain/entities/post_entity.dart';
import '../../domain/entities/create_social_post_input.dart';
import '../../domain/entities/share_fortune_input.dart';
import '../../domain/entities/social_comment_entity.dart';
import '../../domain/repositories/social_repository.dart';
import '../datasources/social_remote_datasource.dart';

class SocialRepositoryImpl implements SocialRepository {
  SocialRepositoryImpl(this._remote, {this.currentUserId});

  final SocialRemoteDataSource _remote;
  final String? currentUserId;

  @override
  Future<SocialFeedPage> fetchPage({int page = 1, bool forceRefresh = false}) async {
    final r = await _remote.fetch(
      page: page,
      currentUserId: currentUserId,
      forceRefresh: forceRefresh,
    );
    return SocialFeedPage(
      posts: r.posts,
      hasMore: r.hasMore,
    );
  }

  @override
  Future<List<PostEntity>> fetchPostsByUser(String userId, {int page = 1}) async {
    final pageResult = await fetchPostsByUserPage(userId, page: page);
    return pageResult.posts;
  }

  @override
  Future<SocialFeedPage> fetchPostsByUserPage(
    String userId, {
    int page = 1,
  }) async {
    try {
      final r = await _remote.fetchUserPosts(
        userId: userId,
        page: page,
        currentUserId: currentUserId,
      );
      if (r.posts.isNotEmpty || page > 1) {
        return SocialFeedPage(posts: r.posts, hasMore: r.hasMore);
      }
    } catch (_) {
      // Yedek: authorId query (eski sunucu)
    }
    final r = await _remote.fetch(
      page: page,
      authorId: userId,
      currentUserId: currentUserId,
    );
    var posts = r.posts;
    var hasMore = r.hasMore;
    if (posts.isEmpty && page == 1) {
      final fallback = await _remote.fetch(
        page: page,
        currentUserId: currentUserId,
      );
      posts = fallback.posts
          .where((p) => p.author.id == userId)
          .toList();
      hasMore = fallback.hasMore;
    }
    return SocialFeedPage(posts: posts, hasMore: hasMore);
  }

  @override
  Future<PostEntity?> fetchPost(String postId) =>
      _remote.fetchPost(postId, currentUserId: currentUserId);

  @override
  Future<PostEntity> createPost(CreateSocialPostInput input) async {
    final dto = await _remote.createPost(input);
    return dto.toEntity();
  }

  @override
  @Deprecated('Backend creates fortune posts; use SocialFortuneFeedSync instead')
  Future<PostEntity> shareFortuneAuto(ShareFortuneInput input) async {
    final dto = await _remote.shareFortuneAuto(input);
    return dto.toEntity();
  }

  @override
  Future<void> deletePost(String postId) async {
    await _remote.deletePost(postId);
  }

  @override
  Future<({bool liked, int likesCount})> toggleLike(String postId) =>
      _remote.toggleLike(postId);

  @override
  Future<List<SocialCommentEntity>> fetchComments(String postId) =>
      _remote.fetchComments(postId);

  @override
  Future<SocialCommentEntity> addComment(String postId, String text) =>
      _remote.addComment(postId, text);

  @override
  Future<void> createStoryImage(String imagePath) =>
      _remote.createStoryImage(imagePath);

  @override
  Future<void> createStoryVideo(String videoPath) =>
      _remote.createStoryVideo(videoPath);

  @override
  Future<void> deleteStory(String storyId) => _remote.deleteStory(storyId);
}
