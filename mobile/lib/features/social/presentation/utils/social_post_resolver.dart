import '../../../feed/domain/entities/post_entity.dart';

/// Akış önbelleğinden gönderi bulur (detay sayfası için anında gösterim).
PostEntity? findSocialFeedPost(List<PostEntity>? posts, String postId) {
  final id = postId.trim();
  if (id.isEmpty || posts == null) return null;
  for (final post in posts) {
    if (post.id == id) return post;
  }
  return null;
}

/// Uzak detay ile akıştaki optimistik sayaçları birleştirir.
PostEntity mergeSocialPostDisplay({
  required PostEntity primary,
  PostEntity? feedOverlay,
}) {
  if (feedOverlay == null) return primary;
  return primary.copyWith(
    commentsCount: feedOverlay.commentsCount > primary.commentsCount
        ? feedOverlay.commentsCount
        : primary.commentsCount,
    likesCount: feedOverlay.likesCount > primary.likesCount
        ? feedOverlay.likesCount
        : primary.likesCount,
    viewsCount: feedOverlay.viewsCount > primary.viewsCount
        ? feedOverlay.viewsCount
        : primary.viewsCount,
    viewCount: feedOverlay.viewCount > primary.viewCount
        ? feedOverlay.viewCount
        : primary.viewCount,
    isLiked: feedOverlay.isLiked,
    likedByMe: feedOverlay.likedByMe,
  );
}

/// Detay ekranı için gösterilecek gönderi — önbellek + API birleşimi.
PostEntity? resolveSocialPostForDetail({
  required List<PostEntity>? feedPosts,
  required PostEntity? remotePost,
  required String postId,
}) {
  final cached = findSocialFeedPost(feedPosts, postId);
  if (remotePost == null) return cached;
  return mergeSocialPostDisplay(primary: remotePost, feedOverlay: cached);
}
