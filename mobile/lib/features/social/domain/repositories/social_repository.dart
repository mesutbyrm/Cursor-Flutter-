import '../../../feed/domain/entities/post_entity.dart';
import '../entities/create_social_post_input.dart';
import '../entities/share_fortune_input.dart';
import '../entities/social_comment_entity.dart';

/// Tek sayfa sonucu — sunucu `pagination.totalPages` ile sınırlama.
class SocialFeedPage {
  const SocialFeedPage({required this.posts, required this.hasMore});

  final List<PostEntity> posts;
  final bool hasMore;
}

abstract class SocialRepository {
  Future<SocialFeedPage> fetchPage({int page});

  /// Kullanıcı profilinde TikTok tarzı ızgara için paylaşımlar.
  Future<List<PostEntity>> fetchPostsByUser(String userId, {int page = 1});

  Future<SocialFeedPage> fetchPostsByUserPage(String userId, {int page = 1});

  /// Instagram / Facebook tarzı yeni paylaşım.
  Future<PostEntity> createPost(CreateSocialPostInput input);

  /// Fal baktırıldığında otomatik sosyal gönderi.
  Future<PostEntity> shareFortuneAuto(ShareFortuneInput input);

  Future<void> deletePost(String postId);

  Future<({bool liked, int likesCount})> toggleLike(String postId);

  Future<List<SocialCommentEntity>> fetchComments(String postId);

  Future<SocialCommentEntity> addComment(String postId, String text);

  Future<void> createStoryImage(String imagePath);
}
