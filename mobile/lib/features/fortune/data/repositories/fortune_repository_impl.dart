import '../../../../core/pagination/paged_result.dart';
import '../../domain/entities/user_fortune_entity.dart';
import '../../domain/repositories/fortune_repository.dart';
import '../datasources/fortune_remote_datasource.dart';

class FortuneRepositoryImpl implements FortuneRepository {
  FortuneRepositoryImpl(this._remote);

  final FortuneRemoteDataSource _remote;

  @override
  Future<PagedResult<UserFortuneEntity>> history({
    int page = 1,
    int limit = 20,
  }) =>
      _remote.history(page: page, limit: limit);

  @override
  Future<UserFortuneEntity> detail(String fortuneId) =>
      _remote.detail(fortuneId);

  @override
  Future<UserFortuneEntity> save(SaveFortuneInput input) =>
      _remote.save(input);
}
