import '../../domain/entities/short_comment_entity.dart';
import '../../domain/entities/short_video_entity.dart';
import '../../domain/repositories/shorts_repository.dart';
import '../datasources/shorts_remote_datasource.dart';

class ShortsRepositoryImpl implements ShortsRepository {
  ShortsRepositoryImpl(this._remote);

  final ShortsRemoteDataSource _remote;

  @override
  Future<ShortVideoFeedPage> fetchFeed({String? cursor, int limit = 10}) async {
    final page = await _remote.fetchFeed(cursor: cursor, limit: limit);
    return ShortVideoFeedPage(
      videos: page.videos,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }

  @override
  Future<ShortVideoEntity> uploadVideo({
    required String videoPath,
    String? thumbnailPath,
    String? description,
  }) =>
      _remote.uploadVideo(
        videoPath: videoPath,
        thumbnailPath: thumbnailPath,
        description: description,
      );

  @override
  Future<({bool liked, int likesCount})> toggleLike(String videoId) =>
      _remote.toggleLike(videoId);

  @override
  Future<List<ShortCommentEntity>> fetchComments(String videoId) =>
      _remote.fetchComments(videoId);

  @override
  Future<({ShortCommentEntity comment, int commentsCount})> addComment(
    String videoId,
    String content,
  ) =>
      _remote.addComment(videoId, content);

  @override
  Future<({bool counted, int viewsCount})> recordView(
    String videoId, {
    required double watchedSec,
  }) =>
      _remote.recordView(videoId, watchedSec: watchedSec);

  @override
  Future<void> deleteVideo(String videoId) => _remote.deleteVideo(videoId);

  @override
  Future<List<ShortVideoEntity>> fetchByUser(String userId) =>
      _remote.fetchByUser(userId);
}
