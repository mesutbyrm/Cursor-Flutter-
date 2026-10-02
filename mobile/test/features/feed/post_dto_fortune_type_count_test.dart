import 'package:canlifal_social/features/feed/data/models/post_dto.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json(Map<String, dynamic> extra) => {
      'id': 'p1',
      'author': {'id': 'u1', 'name': 'Ayşe'},
      'caption': 'x',
      ...extra,
    };

void main() {
  test('fortuneTypeCount öncelikli okunur', () {
    final p = PostDto.fromApiMap(_json({'fortuneTypeCount': 42, 'fortuneCount': 7}));
    expect(p.fortuneCount, 42);
  });

  test('fortuneTypeCount yoksa mevcut fortuneCount alanına düşer', () {
    expect(PostDto.fromApiMap(_json({'fortuneCount': 7})).fortuneCount, 7);
  });

  test('ikisi de yoksa 0 (kart gizlenir)', () {
    expect(PostDto.fromApiMap(_json({})).fortuneCount, 0);
  });
}
