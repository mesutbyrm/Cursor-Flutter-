/// Tek sosyal gönderi detay rotası.
String buildSocialPostDetailRoute(String postId) =>
    '/social/post/${Uri.encodeComponent(postId.trim())}';
