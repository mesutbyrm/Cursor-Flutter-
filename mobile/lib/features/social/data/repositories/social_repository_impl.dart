import '../../../feed/domain/entities/post_entity.dart';
import '../../domain/entities/create_social_post_input.dart';
import '../../domain/entities/share_fortune_input.dart';
import '../../domain/repositories/social_repository.dart';
import '../datasources/social_remote_datasource.dart';

class SocialRepositoryImpl implements SocialRepository {
  SocialRepositoryImpl(this._remote);

  final SocialRemoteDataSource _remote;

  @override
  Future<SocialFeedPage> fetchPage({int page = 1}) async {
    final r = await _remote.fetch(page: page);
    return SocialFeedPage(
      posts: r.posts.map((e) => e.toEntity()).toList(),
      hasMore: r.hasMore,
    );
  }

  @override
  Future<List<PostEntity>> fetchPostsByUser(String userId, {int page = 1}) async {
    final r = await _remote.fetch(page: page, authorId: userId);
    final posts = r.posts.map((e) => e.toEntity()).toList();
    if (posts.isNotEmpty) return posts;
    if (page > 1) return posts;
    final fallback = await _remote.fetch(page: page);
    return fallback.posts
        .map((e) => e.toEntity())
        .where((p) => p.author.id == userId)
        .toList();
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
}
