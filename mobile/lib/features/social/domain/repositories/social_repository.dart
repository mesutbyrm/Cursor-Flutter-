import '../../../feed/domain/entities/post_entity.dart';
import '../entities/create_social_post_input.dart';
import '../entities/share_fortune_input.dart';

/// Tek sayfa sonucu — sunucu `pagination.totalPages` ile sınırlama.
class SocialFeedPage {
  const SocialFeedPage({required this.posts, required this.hasMore});

  final List<PostEntity> posts;
  final bool hasMore;
}

abstract class SocialRepository {
  Future<SocialFeedPage> fetchPage({int page});

  /// Instagram / Facebook tarzı yeni paylaşım.
  Future<PostEntity> createPost(CreateSocialPostInput input);

  /// Fal baktırıldığında otomatik sosyal gönderi.
  Future<PostEntity> shareFortuneAuto(ShareFortuneInput input);

  Future<void> deletePost(String postId);
}
