import '../../../../core/pagination/paged_result.dart';
import '../../domain/entities/user_fortune_entity.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_remote_datasource.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl(this._remote);

  final FavoritesRemoteDataSource _remote;

  @override
  Future<PagedResult<UserFortuneEntity>> fortuneHistory({
    int page = 1,
    int limit = 20,
  }) =>
      _remote.fortuneHistory(page: page, limit: limit);
}
