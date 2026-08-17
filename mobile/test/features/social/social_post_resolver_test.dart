import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/feed/domain/entities/post_entity.dart';
import 'package:canlifal_social/features/social/presentation/utils/social_post_resolver.dart';

const _author = UserEntity(id: 'u1', username: 'tester');

PostEntity _post(String id, {int comments = 0, int likes = 0}) => PostEntity(
      id: id,
      author: _author,
      commentsCount: comments,
      likesCount: likes,
    );

void main() {
  group('findSocialFeedPost', () {
    test('returns matching post', () {
      final posts = [_post('a'), _post('b')];
      expect(findSocialFeedPost(posts, 'b')?.id, 'b');
    });

    test('returns null when missing', () {
      expect(findSocialFeedPost([_post('a')], 'z'), isNull);
    });
  });

  group('mergeSocialPostDisplay', () {
    test('uses higher optimistic counts from feed', () {
      final merged = mergeSocialPostDisplay(
        primary: _post('a', comments: 1, likes: 2),
        feedOverlay: _post('a', comments: 3, likes: 2),
      );
      expect(merged.commentsCount, 3);
      expect(merged.likesCount, 2);
    });
  });

  group('resolveSocialPostForDetail', () {
    test('falls back to cache when remote is null', () {
      final cached = _post('a', comments: 4);
      final resolved = resolveSocialPostForDetail(
        feedPosts: [cached],
        remotePost: null,
        postId: 'a',
      );
      expect(resolved?.commentsCount, 4);
    });
  });
}
