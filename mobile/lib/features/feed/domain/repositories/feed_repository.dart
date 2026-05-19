import '../entities/post_entity.dart';

abstract class FeedRepository {
  Future<List<PostEntity>> fetchFeed({int page});
}
