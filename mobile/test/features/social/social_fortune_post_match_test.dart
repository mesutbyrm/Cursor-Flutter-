import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/feed/domain/entities/post_entity.dart';
import 'package:canlifal_social/features/social/presentation/services/social_fortune_post_match.dart';

void main() {
  const author = UserEntity(id: 'u1', username: 'alice', displayName: 'Alice');
  const other = UserEntity(id: 'u2', username: 'bob', displayName: 'Bob');

  PostEntity fortunePost({
    required String id,
    UserEntity author = author,
    String? fortuneId,
    bool isAutoShare = true,
    String? postType,
  }) {
    return PostEntity(
      id: id,
      author: author,
      isAutoShare: isAutoShare,
      postType: postType ?? 'fortune',
      fortuneId: fortuneId,
    );
  }

  test('findMatchingFortunePost prefers postIdHint', () {
    final posts = [
      fortunePost(id: 'p1', fortuneId: 'f1'),
      fortunePost(id: 'p2', fortuneId: 'f2'),
    ];
    final match = findMatchingFortunePost(
      posts: posts,
      postIdHint: 'p2',
      authorId: 'u1',
      fortuneId: 'f1',
    );
    expect(match?.id, 'p2');
  });

  test('findMatchingFortunePost matches author + fortune type', () {
    final posts = [
      PostEntity(id: 'plain', author: author, caption: 'hello'),
      fortunePost(id: 'f-post', fortuneId: 'reading-9'),
    ];
    final match = findMatchingFortunePost(
      posts: posts,
      authorId: 'u1',
      fortuneId: 'reading-9',
    );
    expect(match?.id, 'f-post');
  });

  test('findMatchingFortunePost skips wrong author', () {
    final posts = [fortunePost(id: 'p1', author: other, fortuneId: 'f1')];
    final match = findMatchingFortunePost(
      posts: posts,
      authorId: 'u1',
      fortuneId: 'f1',
    );
    expect(match, isNull);
  });

  test('findMatchingFortunePost skips non-fortune posts', () {
    final posts = [
      PostEntity(id: 'p1', author: author, caption: 'photo'),
    ];
    final match = findMatchingFortunePost(posts: posts, authorId: 'u1');
    expect(match, isNull);
  });
}
