import '../entities/shorts_entity.dart';

abstract class ShortsRepository {
  Future<List<ShortVideo>> getShorts({int limit = 20});
  Future<List<ShortVideo>> getTrendingShorts();
  Future<ShortVideo> getShortDetail(String shortId);
  Future<void> likeShort(String shortId);
  Future<void> unlikeShort(String shortId);
  Future<List<ShortVideoRemix>> getRemixes(String originalVideoId);
  Future<ShortVideoRemix> createRemix(String originalVideoId, String remixType);
}
