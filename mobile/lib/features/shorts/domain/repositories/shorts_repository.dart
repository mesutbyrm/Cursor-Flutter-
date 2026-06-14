import '../entities/short_comment_entity.dart';
import '../entities/short_video_entity.dart';

class ShortVideoFeedPage {
  const ShortVideoFeedPage({
    required this.videos,
    this.nextCursor,
    this.hasMore = false,
  });

  final List<ShortVideoEntity> videos;
  final String? nextCursor;
  final bool hasMore;
}

abstract class ShortsRepository {
  Future<ShortVideoFeedPage> fetchFeed({String? cursor, int limit = 10});

  Future<ShortVideoEntity> uploadVideo({
    required String videoPath,
    String? thumbnailPath,
    String? description,
  });

  Future<({bool liked, int likesCount})> toggleLike(String videoId);

  Future<List<ShortCommentEntity>> fetchComments(String videoId);

  Future<({ShortCommentEntity comment, int commentsCount})> addComment(
    String videoId,
    String content,
  );

  Future<({bool counted, int viewsCount})> recordView(
    String videoId, {
    required double watchedSec,
  });

  Future<void> deleteVideo(String videoId);

  Future<List<ShortVideoEntity>> fetchByUser(String userId);
}
