import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/feed/domain/entities/post_entity.dart';
import 'package:canlifal_social/features/social/domain/entities/create_social_post_input.dart';
import 'package:canlifal_social/features/social/domain/entities/share_fortune_input.dart';
import 'package:canlifal_social/features/social/domain/entities/social_comment_entity.dart';
import 'package:canlifal_social/features/social/domain/repositories/social_repository.dart';
import 'package:canlifal_social/features/social/presentation/providers/social_providers.dart';
import 'package:canlifal_social/features/social/presentation/utils/social_feed_sync.dart';

const _author = UserEntity(id: 'u1', username: 'tester');

PostEntity _post(String id, {int comments = 0}) =>
    PostEntity(id: id, author: _author, commentsCount: comments);

class _FakeSocialRepository implements SocialRepository {
  _FakeSocialRepository(this._initial, {this.detail});

  final List<PostEntity> _initial;
  final PostEntity? detail;

  @override
  Future<SocialFeedPage> fetchPage({int page = 1, bool forceRefresh = false}) async {
    return SocialFeedPage(posts: List<PostEntity>.from(_initial), hasMore: false);
  }

  @override
  Future<List<PostEntity>> fetchPostsByUser(String userId, {int page = 1}) =>
      Future.value([]);

  @override
  Future<SocialFeedPage> fetchPostsByUserPage(String userId, {int page = 1}) =>
      Future.value(const SocialFeedPage(posts: [], hasMore: false));

  @override
  Future<PostEntity?> fetchPost(String postId) async => detail ?? _post(postId);

  @override
  Future<PostEntity> createPost(CreateSocialPostInput input) =>
      Future.value(_post('new'));

  @override
  Future<PostEntity> shareFortuneAuto(ShareFortuneInput input) =>
      Future.value(_post('fortune'));

  @override
  Future<void> deletePost(String postId) async {}

  @override
  Future<({bool liked, int likesCount})> toggleLike(String postId) async =>
      (liked: true, likesCount: 1);

  @override
  Future<List<SocialCommentEntity>> fetchComments(String postId) =>
      Future.value([]);

  @override
  Future<SocialCommentEntity> addComment(String postId, String text) {
    throw UnimplementedError();
  }

  @override
  Future<void> createStoryImage(String imagePath) async {}

  @override
  Future<void> createStoryVideo(String videoPath) async {}

  @override
  Future<void> deleteStory(String storyId) async {}
}

void main() {
  test('syncSocialPostCommentAdded bumps feed and invalidates detail', () async {
    final container = ProviderContainer(
      overrides: [
        socialRepositoryProvider.overrideWithValue(
          _FakeSocialRepository([_post('a', comments: 2)]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(socialNotifierProvider.future);
    var invalidated = false;
    syncSocialPostCommentAdded(
      feed: container.read(socialNotifierProvider.notifier),
      invalidateDetail: (_) => invalidated = true,
      postId: 'a',
    );

    final post = container.read(socialNotifierProvider).value!.first;
    expect(post.commentsCount, 3);
    expect(invalidated, isTrue);
  });
}
