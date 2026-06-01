import '../../domain/entities/search_user_entity.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_datasource.dart';

class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(this._remote);

  final SearchRemoteDataSource _remote;

  @override
  Future<List<SearchUserEntity>> searchUsers(String query) =>
      _remote.searchUsers(query);
}
