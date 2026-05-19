import '../../domain/entities/post_entity.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_remote_datasource.dart';

class FeedRepositoryImpl implements FeedRepository {
  FeedRepositoryImpl(this._remote);

  final FeedRemoteDataSource _remote;

  @override
  Future<List<PostEntity>> fetchFeed({int page = 1}) async {
    final rows = await _remote.fetch(page: page);
    return rows.map((e) => e.toEntity()).toList();
  }
}
