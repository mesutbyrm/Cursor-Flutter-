import '../../domain/repositories/social_repository.dart';
import '../datasources/social_remote_datasource.dart';

class SocialRepositoryImpl implements SocialRepository {
  SocialRepositoryImpl(this._remote);

  final SocialRemoteDataSource _remote;

  @override
  Future<SocialFeedPage> fetchPage({int page = 1}) async {
    final r = await _remote.fetch(page: page);
    return SocialFeedPage(
      posts: r.posts.map((e) => e.toEntity()).toList(),
      hasMore: r.hasMore,
    );
  }
}
