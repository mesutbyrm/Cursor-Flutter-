import '../../../feed/domain/entities/post_entity.dart';

/// Tek sayfa sonucu — sunucu `pagination.totalPages` ile sınırlama.
class SocialFeedPage {
  const SocialFeedPage({required this.posts, required this.hasMore});

  final List<PostEntity> posts;
  final bool hasMore;
}

abstract class SocialRepository {
  Future<SocialFeedPage> fetchPage({int page});
}
