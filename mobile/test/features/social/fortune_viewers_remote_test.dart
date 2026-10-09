import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/feed/domain/entities/post_entity.dart';
import 'package:canlifal_social/features/social/data/datasources/social_remote_datasource.dart';
import 'package:canlifal_social/features/social/presentation/providers/social_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Remote extends SocialRemoteDataSource {
  _Remote(this.result) : super(Dio());
  final FortuneViewers? result;
  var calls = 0;
  @override
  Future<FortuneViewers?> fetchFortuneViewers(String type, {int limit = 6}) async {
    calls++;
    return result;
  }
}

class _StubSocial extends SocialNotifier {
  @override
  Future<List<PostEntity>> build() async => [];
}

PostEntity _post({int fortuneCount = 0}) => PostEntity(
      id: 'p1',
      author: const UserEntity(id: 'owner', username: 'owner'),
      fortuneType: 'coffee',
      postType: 'fortune',
      fortuneCount: fortuneCount,
    );

void main() {
  test('sunucudan son bakanlar gelir; gönderi sahibi çıkarılır, en çok 5', () async {
    final remote = _Remote(FortuneViewers(
      count: 42,
      users: [
        for (final id in ['owner', 'a', 'b', 'c', 'd', 'e', 'f'])
          UserEntity(id: id, username: id),
      ],
    ));
    final c = ProviderContainer(
      overrides: [
        socialRemoteProvider.overrideWithValue(remote),
        socialNotifierProvider.overrideWith(_StubSocial.new),
      ],
    );
    addTearDown(c.dispose);
    final post = _post();
    final sub = c.listen(fortuneCoViewersProvider(post), (_, _) {});
    final countSub = c.listen(fortuneViewCountProvider(post), (_, _) {});
    await c.read(fortuneViewersByTypeProvider('coffee').future);
    expect(sub.read().map((u) => u.id), ['a', 'b', 'c', 'd', 'e']);
    expect(countSub.read(), 42);
    expect(remote.calls, 1);
  });

  test('gönderide sayı varsa o kullanılır; sunucu yoksa sayı korunur', () async {
    final c = ProviderContainer(
      overrides: [
        socialRemoteProvider.overrideWithValue(_Remote(null)),
        socialNotifierProvider.overrideWith(_StubSocial.new),
      ],
    );
    addTearDown(c.dispose);
    final post = _post(fortuneCount: 7);
    final countSub = c.listen(fortuneViewCountProvider(post), (_, _) {});
    await c.read(fortuneViewersByTypeProvider('coffee').future);
    expect(countSub.read(), 7);
  });
}
