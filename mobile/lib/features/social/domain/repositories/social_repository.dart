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
  Future<SocialFeedPage> fetchPage({int page = 1, bool forceRefresh = false});

  /// Kullanıcı profilinde TikTok tarzı ızgara için paylaşımlar.
  Future<List<PostEntity>> fetchPostsByUser(String userId, {int page = 1});

  Future<SocialFeedPage> fetchPostsByUserPage(String userId, {int page = 1});

  /// Tek gönderi — kılavuz §9.10 `getPost`.
  Future<PostEntity?> fetchPost(String postId);

  /// Instagram / Facebook tarzı yeni paylaşım.
  Future<PostEntity> createPost(CreateSocialPostInput input);

  /// Fal baktırıldığında otomatik sosyal gönderi.
  ///
  /// **Kullanılmıyor:** Backend fal tamamlanınca paylaşımı oluşturur; mobil yalnızca
  /// `SocialFortuneFeedSync` ile senkronize eder.
  @Deprecated('Backend creates fortune posts; use SocialFortuneFeedSync instead')
  Future<PostEntity> shareFortuneAuto(ShareFortuneInput input);

  Future<void> deletePost(String postId);

  Future<({bool liked, int likesCount})> toggleLike(String postId);

  Future<List<SocialCommentEntity>> fetchComments(String postId);

  Future<SocialCommentEntity> addComment(String postId, String text);

  Future<void> createStoryImage(String imagePath);

  /// DELETE `/api/stories` — üretim sözleşmesi.
  Future<void> deleteStory(String storyId);
}
