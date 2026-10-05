import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/feed/domain/entities/post_entity.dart';
import 'package:canlifal_social/features/social/presentation/utils/fortune_co_viewers.dart';

PostEntity _p(String id, String uid, String? type, DateTime t) => PostEntity(
      id: id,
      author: UserEntity(id: uid, username: 'u$uid'),
      fortuneType: type,
      postType: type == null ? 'text' : 'fortune',
      createdAt: t,
    );

void main() {
  final base = DateTime(2026, 10, 1, 12);
  test('aynı türde son 5 farklı kullanıcı, en yeni önce, sahibi hariç', () {
    final post = _p('p0', 'a', 'coffee', base);
    final feed = [
      post,
      _p('p1', 'b', 'kahve-fali', base.subtract(const Duration(minutes: 1))),
      _p('p2', 'c', 'coffee', base.subtract(const Duration(minutes: 5))),
      _p('p3', 'b', 'coffee', base.subtract(const Duration(minutes: 6))),
      _p('p4', 'd', 'coffee', base.subtract(const Duration(minutes: 7))),
      _p('p5', 'e', 'coffee', base.subtract(const Duration(minutes: 8))),
      _p('p6', 'f', 'tarot', base.subtract(const Duration(minutes: 2))),
      _p('p7', 'g', null, base.subtract(const Duration(minutes: 3))),
      _p('p8', 'a', 'coffee', base.subtract(const Duration(minutes: 4))),
      _p('p9', 'h', 'coffee', base.subtract(const Duration(minutes: 9))),
      _p('p10', 'i', 'coffee', base.subtract(const Duration(minutes: 10))),
      _p('p11', 'j', 'coffee', base.subtract(const Duration(minutes: 11))),
    ];
    final out = recentFortuneCoViewers(feed, post);
    expect(out.map((u) => u.id), ['b', 'c', 'd', 'e', 'h']);
  });

  test('tür bilinmiyorsa veya akışta yoksa boş', () {
    final post = _p('p0', 'a', 'xyz', base);
    expect(recentFortuneCoViewers([post], post), isEmpty);
    final coffee = _p('p1', 'a', 'coffee', base);
    expect(recentFortuneCoViewers([coffee], coffee), isEmpty);
  });
}
