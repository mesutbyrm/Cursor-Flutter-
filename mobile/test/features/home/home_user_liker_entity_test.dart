import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:canlifal_social/features/content_hub/domain/content_link.dart';
import 'package:canlifal_social/features/home/domain/entities/home_user_liker_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeUserLikerEntity.fromJson', () {
    test('nested user map', () {
      final e = HomeUserLikerEntity.fromJson({
        'likedAt': '2 dk',
        'user': {
          'id': 'u-9',
          'displayName': 'Ada',
          'avatarUrl': 'https://cdn.example/a.png',
        },
      });
      expect(e.id, 'u-9');
      expect(e.displayName, 'Ada');
      expect(e.avatarUrl, 'https://cdn.example/a.png');
      expect(e.timeLabel, '2 dk');
      expect(e.isValid, isTrue);
    });

    test('flat online user with username only', () {
      final e = HomeUserLikerEntity.fromJson({
        'userId': '42',
        'username': 'mesut',
        'lastSeen': 'şimdi',
      });
      expect(e.id, '42');
      expect(e.displayName, 'mesut');
      expect(e.timeLabel, 'şimdi');
      expect(e.isValid, isTrue);
    });

    test('id without name falls back to Kullanıcı', () {
      final e = HomeUserLikerEntity.fromJson({'id': 'x1'});
      expect(e.id, 'x1');
      expect(e.displayName, 'Kullanıcı');
      expect(e.isValid, isTrue);
    });

    test('empty payload is invalid', () {
      expect(HomeUserLikerEntity.fromJson({}).isValid, isFalse);
    });
  });

  test('kılavuz çevrimiçi ve beğenenler uçları', () {
    expect(ApiEndpoints.usersOnline, '/api/users/online');
    expect(ApiEndpoints.userLikers, '/api/user/likers');
  });

  test('içerik hubında çevrimiçi ve beğenenler var', () {
    final paths = ContentHubCatalog.sections
        .expand((s) => s.$2)
        .map((l) => l.path)
        .toSet();
    expect(paths, containsAll(['/cevrimici', '/likers']));
  });
}
