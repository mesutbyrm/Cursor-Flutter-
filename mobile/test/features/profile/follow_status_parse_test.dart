import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:canlifal_social/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('takip ve engel uçları kılavuz §9.2 ile aynı', () {
    expect(ApiEndpoints.userFollow('u1'), '/api/user/u1/follow');
    expect(ApiEndpoints.userFollowStatus('u1'), '/api/user/u1/follow-status');
    expect(ApiEndpoints.userBlocked, '/api/user/blocked');
    expect(ApiEndpoints.userSiteProfile, '/api/user/profile');
    expect(ApiEndpoints.userWatchAd, '/api/user/watch-ad');
    expect(ApiEndpoints.fanClubJoin('c1'), '/api/fan-clubs/c1/join');
  });

  group('parseFollowStatusBody', () {
    test('isFollowing ve nested data', () {
      expect(parseFollowStatusBody({'isFollowing': true}), isTrue);
      expect(
        parseFollowStatusBody({
          'success': true,
          'data': {'following': true},
        }),
        isTrue,
      );
      expect(parseFollowStatusBody({'data': true}), isTrue);
      expect(parseFollowStatusBody({'status': 'following'}), isTrue);
      expect(parseFollowStatusBody({'isFollowing': false}), isFalse);
      expect(parseFollowStatusBody({'status': 'none'}), isFalse);
    });
  });

  group('parseProfileUserList', () {
    test('blocked ve data listesini okur', () {
      final blocked = parseProfileUserList({
        'blocked': [
          {'id': 'u1', 'username': 'ali', 'name': 'Ali'},
        ],
      });
      expect(blocked, hasLength(1));
      expect(blocked.first.id, 'u1');

      final nested = parseProfileUserList({
        'success': true,
        'data': [
          {'id': 'u2', 'username': 'ayse'},
        ],
      });
      expect(nested.map((u) => u.id), ['u2']);
    });

    test('boş id atılır', () {
      expect(
        parseProfileUserList([
          {'username': 'ghost'},
          {'id': 'ok', 'username': 'ok'},
        ]).map((u) => u.id),
        ['ok'],
      );
    });
  });
}
