import '../entities/search_user_entity.dart';

abstract class SearchRepository {
  Future<List<SearchUserEntity>> searchUsers(String query);
}
