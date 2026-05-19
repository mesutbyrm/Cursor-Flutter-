import '../../domain/entities/live_stream_entity.dart';
import '../../domain/repositories/live_repository.dart';
import '../datasources/live_remote_datasource.dart';

class LiveRepositoryImpl implements LiveRepository {
  LiveRepositoryImpl(this._remote);

  final LiveRemoteDataSource _remote;

  @override
  Future<List<LiveStreamEntity>> fetchStreams({int page = 1}) =>
      _remote.fetch(page: page);
}
