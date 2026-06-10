import '../../../../core/pagination/paged_result.dart';
import '../../domain/entities/fortune_type_entity.dart';
import '../../domain/entities/user_fortune_entity.dart';
import '../../domain/repositories/fortune_repository.dart';
import '../datasources/fortune_remote_datasource.dart';

class FortuneRepositoryImpl implements FortuneRepository {
  FortuneRepositoryImpl(this._remote);

  final FortuneRemoteDataSource _remote;

  @override
  Future<FortuneReadingResult> readFortune({
    required FortuneTypeEntity type,
    String? userInput,
    bool? yesNoChoice,
    DateTime? birthDate,
  }) => _remote.readFortune(
    type: type,
    userInput: userInput,
    yesNoChoice: yesNoChoice,
    birthDate: birthDate,
  );

  @override
  Future<PagedResult<UserFortuneEntity>> history({
    int page = 1,
    int limit = 20,
  }) => _remote.history(page: page, limit: limit);

  @override
  Future<UserFortuneEntity> detail(String fortuneId) =>
      _remote.detail(fortuneId);

  @override
  Future<UserFortuneEntity> save(SaveFortuneInput input) => _remote.save(input);
}
