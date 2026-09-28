import '../../domain/entities/shorts_entity.dart';
import '../../domain/repositories/shorts_repository.dart';
import '../datasources/shorts_datasource.dart';

class ShortsRepositoryImpl implements ShortsRepository {
  final ShortsDataSource _dataSource;
  ShortsRepositoryImpl({required ShortsDataSource dataSource}) : _dataSource = dataSource;

  @override
  Future<List<ShortVideo>> getShorts({int limit = 20}) async => (await _dataSource.getShorts(limit: limit)).map((e) => e.toDomain()).toList();

  @override
  Future<List<ShortVideo>> getTrendingShorts() async => (await _dataSource.getTrendingShorts()).map((e) => e.toDomain()).toList();

  @override
  Future<ShortVideo> getShortDetail(String shortId) async => (await _dataSource.getShortDetail(shortId)).toDomain();

  @override
  Future<void> likeShort(String shortId) => _dataSource.likeShort(shortId);

  @override
  Future<void> unlikeShort(String shortId) => _dataSource.unlikeShort(shortId);

  @override
  Future<List<ShortVideoRemix>> getRemixes(String originalVideoId) async => (await _dataSource.getRemixes(originalVideoId)).map((e) => e.toDomain()).toList();

  @override
  Future<ShortVideoRemix> createRemix(String originalVideoId, String remixType) async => (await _dataSource.createRemix(originalVideoId, remixType)).toDomain();
}
