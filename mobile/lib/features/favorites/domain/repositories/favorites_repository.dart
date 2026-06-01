import '../../../../core/pagination/paged_result.dart';
import '../entities/user_fortune_entity.dart';

abstract class FavoritesRepository {
  Future<PagedResult<UserFortuneEntity>> fortuneHistory({
    int page = 1,
    int limit = 20,
  });
}
