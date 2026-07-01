import '../entities/short_comment_entity.dart';
import '../entities/short_explore_entity.dart';
import '../entities/short_video_entity.dart';

enum ShortsFeedTab { forYou, following }

enum ShortUserVideosTab { videos, liked, saved }

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
  Future<ShortVideoFeedPage> fetchFeed({
    String? cursor,
    int limit = 10,
    ShortsFeedTab tab = ShortsFeedTab.forYou,
  });

  Future<ShortExplorePage> fetchExplore({
    String? query,
    String? cursor,
    int limit = 12,
  });

  Future<ShortVideoEntity> fetchVideo(String videoId);

  Future<ShortVideoEntity> uploadVideo({
    required String videoPath,
    String? thumbnailPath,
    String? description,
  });

  Future<({bool liked, int likesCount})> toggleLike(String videoId);

  Future<({bool saved, int savesCount})> toggleSave(String videoId);

  Future<int> recordShare(String videoId);

  Future<List<ShortCommentEntity>> fetchComments(String videoId);

  Future<({ShortCommentEntity comment, int commentsCount})> addComment(
    String videoId,
    String content, {
    String? parentId,
  });

  Future<void> deleteComment(String videoId, String commentId);

  Future<({bool liked, int likesCount})> toggleCommentLike(
    String videoId,
    String commentId,
  );

  Future<({bool counted, int viewsCount})> recordView(
    String videoId, {
    required double watchedSec,
  });

  Future<void> deleteVideo(String videoId);

  Future<List<ShortVideoEntity>> fetchByUser(
    String userId, {
    ShortUserVideosTab tab = ShortUserVideosTab.videos,
  });

  Future<ShortProfileStats> fetchProfileStats(String userId);

  Future<List<ShortVideoEntity>> fetchViewedByMe({int limit = 20});

  Future<List<ShortVideoEntity>> fetchDuets(String videoId);

  Future<List<ShortHashtagEntity>> searchHashtags(String query);

  Future<List<ShortHashtagEntity>> fetchTrendingHashtags();

  Future<List<ShortMusicEntity>> searchMusic(String query);
}
