import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/feed/data/models/post_dto.dart';
import 'package:canlifal_social/features/feed/domain/entities/post_entity.dart';

void main() {
  const author = UserEntity(id: 'u1', username: 'admin', displayName: 'Admin');

  test('displayFortuneBody prefers fortuneDetail over short caption', () {
    const post = PostEntity(
      id: 'p1',
      author: author,
      caption: 'Semboller senin için fısıldıyor: Tarot...',
      fortuneDetail: 'Sevgili soru sahibim, bu soruya cevap ararken tarot kartları yol gösterici olacak.',
      postType: 'fortune',
      isAutoShare: true,
    );
    expect(post.displayFortuneBody, contains('tarot kartları'));
    expect(post.isFortunePost, isTrue);
  });

  test('PostDto.entityFromApiMap parses fortune detail and share count', () {
    final entity = PostDto.entityFromApiMap({
      'id': 'p2',
      'author': {'id': 'u1', 'username': 'admin'},
      'caption': 'Kısa özet',
      'detail': 'Uzun fal metni burada devam ediyor.',
      'postType': 'fortune',
      'isAutoShare': true,
      'fortuneCount': 5,
      'viewsCount': 31,
      'shareCount': 2,
    });
    expect(entity.fortuneDetail, 'Uzun fal metni burada devam ediyor.');
    expect(entity.displayFortuneBody, contains('Uzun fal'));
    expect(entity.displayViewCount, 31);
    expect(entity.shareCount, 2);
    expect(entity.fortuneCount, 5);
  });
}
