import '../../domain/entities/short_video_analytics.dart';
import '../../domain/entities/short_comment_entity.dart';
import '../../domain/entities/short_explore_entity.dart';
import '../../domain/entities/short_video_entity.dart';
import '../../domain/entities/shorts_ai_metadata.dart';
import '../../domain/repositories/shorts_repository.dart';
import '../datasources/shorts_remote_datasource.dart';

class ShortsRepositoryImpl implements ShortsRepository {
  ShortsRepositoryImpl(this._remote);

  final ShortsRemoteDataSource _remote;

  @override
  Future<ShortVideoFeedPage> fetchFeed({
    String? cursor,
    int limit = 10,
    ShortsFeedTab tab = ShortsFeedTab.forYou,
  }) async {
    final page = await _remote.fetchFeed(cursor: cursor, limit: limit, tab: tab);
    return ShortVideoFeedPage(
      videos: page.videos,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }

  @override
  Future<ShortExplorePage> fetchExplore({
    String? query,
    String? cursor,
    int limit = 12,
    String? section,
    String? location,
    double? lat,
    double? lng,
    String? source,
  }) =>
      _remote.fetchExplore(
        query: query,
        cursor: cursor,
        limit: limit,
        section: section,
        location: location,
        lat: lat,
        lng: lng,
        source: source,
      );

  @override
  Future<ShortExplorePage> fetchExploreHub({
    String? locationLabel,
    double? lat,
    double? lng,
  }) =>
      _remote.fetchExploreHub(
        locationLabel: locationLabel,
        lat: lat,
        lng: lng,
      );

  @override
  Future<ShortVideoEntity> fetchVideo(String videoId) =>
      _remote.fetchVideo(videoId);

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
  Future<({bool saved, int savesCount})> toggleSave(String videoId) =>
      _remote.toggleSave(videoId);

  @override
  Future<int> recordShare(String videoId) => _remote.recordShare(videoId);

  @override
  Future<List<ShortCommentEntity>> fetchComments(String videoId) =>
      _remote.fetchComments(videoId);

  @override
  Future<({ShortCommentEntity comment, int commentsCount})> addComment(
    String videoId,
    String content, {
    String? parentId,
  }) =>
      _remote.addComment(videoId, content, parentId: parentId);

  @override
  Future<void> deleteComment(String videoId, String commentId) =>
      _remote.deleteComment(videoId, commentId);

  @override
  Future<({bool liked, int likesCount})> toggleCommentLike(
    String videoId,
    String commentId,
  ) =>
      _remote.toggleCommentLike(videoId, commentId);

  @override
  Future<({bool counted, int viewsCount})> recordView(
    String videoId, {
    required double watchedSec,
  }) =>
      _remote.recordView(videoId, watchedSec: watchedSec);

  @override
  Future<void> deleteVideo(String videoId) => _remote.deleteVideo(videoId);

  @override
  Future<List<ShortVideoEntity>> fetchByUser(
    String userId, {
    ShortUserVideosTab tab = ShortUserVideosTab.videos,
  }) =>
      _remote.fetchByUser(userId, tab: tab);

  @override
  Future<ShortProfileStats> fetchProfileStats(String userId) =>
      _remote.fetchProfileStats(userId);

  @override
  Future<List<ShortVideoEntity>> fetchViewedByMe({int limit = 20}) =>
      _remote.fetchViewedByMe(limit: limit);

  @override
  Future<List<ShortVideoEntity>> fetchDuets(String videoId) =>
      _remote.fetchDuets(videoId);

  @override
  Future<List<ShortHashtagEntity>> searchHashtags(String query) =>
      _remote.searchHashtags(query);

  @override
  Future<List<ShortHashtagEntity>> fetchTrendingHashtags() =>
      _remote.fetchTrendingHashtags();

  @override
  Future<List<ShortMusicEntity>> searchMusic(String query) =>
      _remote.searchMusic(query);

  @override
  Future<List<ShortVideoEntity>> fetchHashtagVideos(String name) =>
      _remote.fetchHashtagVideos(name);

  @override
  Future<List<ShortVideoAuthor>> searchMentions(String query) =>
      _remote.searchMentions(query);

  @override
  Future<void> pinComment(String videoId, String commentId) =>
      _remote.pinComment(videoId, commentId);

  @override
  Future<ShortVideoAnalytics> fetchVideoAnalytics(
    String videoId, {
    ShortVideoEntity? fallback,
  }) =>
      _remote.fetchVideoAnalytics(videoId, fallback: fallback);

  @override
  Future<ShortsAiMetadata> suggestMetadata({
    String? description,
    String? videoKey,
    String? liveClipId,
  }) =>
      _remote.suggestMetadata(
        description: description,
        videoKey: videoKey,
        liveClipId: liveClipId,
      );

  @override
  Future<ShortLiveClipSource> fetchLiveClip({
    required String liveClipId,
    String? sessionId,
    String? roomId,
  }) =>
      _remote.fetchLiveClip(
        liveClipId: liveClipId,
        sessionId: sessionId,
        roomId: roomId,
      );

  @override
  Future<List<ShortMusicEntity>> recommendMusic({
    String? description,
    List<String> hashtags = const [],
    String? videoKey,
  }) =>
      _remote.recommendMusic(
        description: description,
        hashtags: hashtags,
        videoKey: videoKey,
      );

  @override
  Future<String?> generateSubtitles({
    required String videoId,
    String? videoKey,
  }) =>
      _remote.generateSubtitles(videoId: videoId, videoKey: videoKey);

  @override
  Future<ShortGiftSendResult> sendGift({
    required String videoId,
    required String giftTypeId,
    required String senderName,
    int quantity = 1,
    String? senderId,
  }) async {
    final event = await _remote.sendShortGift(
      videoId: videoId,
      giftTypeId: giftTypeId,
      senderName: senderName,
      quantity: quantity,
      senderId: senderId,
    );
    return ShortGiftSendResult(event: event);
  }
}
