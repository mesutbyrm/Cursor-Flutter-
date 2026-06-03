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
  Future<SocialFeedPage> fetchPage({int page = 1}) async {
    final r = await _remote.fetch(page: page, currentUserId: currentUserId);
    return SocialFeedPage(
      posts: r.posts.map((e) => e.toEntity()).toList(),
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
    final r = await _remote.fetch(
      page: page,
      authorId: userId,
      currentUserId: currentUserId,
    );
    var posts = r.posts.map((e) => e.toEntity()).toList();
    var hasMore = r.hasMore;
    if (posts.isEmpty && page == 1) {
      final fallback = await _remote.fetch(
        page: page,
        currentUserId: currentUserId,
      );
      posts = fallback.posts
          .map((e) => e.toEntity())
          .where((p) => p.author.id == userId)
          .toList();
      hasMore = fallback.hasMore;
    }
    return SocialFeedPage(posts: posts, hasMore: hasMore);
  }

  @override
  Future<PostEntity> createPost(CreateSocialPostInput input) async {
    final dto = await _remote.createPost(input);
    return dto.toEntity();
  }

  @override
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
}
