import '../../domain/entities/user_favorite_entity.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_remote_datasource.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl(this._remote);

  final FavoritesRemoteDataSource _remote;

  @override
  Future<List<UserFavoriteEntity>> list() => _remote.list();

  @override
  Future<UserFavoriteEntity> add(AddFavoriteInput input) => _remote.add(input);

  @override
  Future<void> remove(String id) => _remote.remove(id);
}
