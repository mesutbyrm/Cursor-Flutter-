class ShortVideo {
  final String id, userId, username, title, description, videoUrl;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final int likes, comments, shares, views;
  final bool isLiked;

  ShortVideo({required this.id, required this.userId, required this.username, required this.title, required this.description, required this.videoUrl, this.thumbnailUrl, required this.createdAt, required this.likes, required this.comments, required this.shares, required this.views, required this.isLiked});
}

class ShortVideoRemix {
  final String id, originalVideoId, remixUserId, title;
  final String remixType;
  final int duets;
  final DateTime createdAt;
  final bool trending;

  ShortVideoRemix({required this.id, required this.originalVideoId, required this.remixUserId, required this.title, required this.remixType, required this.duets, required this.createdAt, required this.trending});
}
