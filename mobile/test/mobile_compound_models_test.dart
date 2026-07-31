import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/home/data/models/mobile_compound_models.dart';

void main() {
  group('MobileHomeBundle', () {
    test('parses success wrapper live streams and voice rooms', () {
      final bundle = MobileHomeBundle.fromJson({
        'liveStreams': [
          {
            'id': 's1',
            'title': 'Tarot',
            'hostId': 'u1',
            'hostName': 'Ayşe',
            'listenerCount': 12,
            'isLive': true,
          },
        ],
        'voiceRooms': [
          {
            'id': 'v1',
            'name': 'Genel',
            'hostId': 'u2',
            'listenerCount': 5,
          },
        ],
        'user': {'unreadNotifications': 3},
      });

      expect(bundle.liveStreams, hasLength(1));
      expect(bundle.liveStreams.first.id, 's1');
      expect(bundle.liveStreams.first.viewerCount, 12);
      expect(bundle.voiceRooms, hasLength(1));
      expect(bundle.voiceRooms.first.nameTr, 'Genel');
      expect(bundle.unreadNotifications, 3);
    });
  });

  group('MobileFortuneMenuBundle', () {
    test('parses fortune types and balances', () {
      final menu = MobileFortuneMenuBundle.fromJson({
        'fortuneTypes': [
          {
            'id': 't1',
            'slug': 'tarot-fali',
            'nameTr': 'Tarot',
            'creditCost': 10,
          },
        ],
        'userCredits': {'jetons': 50, 'credits': 100},
        'creditsPerMinute': 2,
      });

      expect(menu.fortuneTypes, hasLength(1));
      expect(menu.fortuneTypes.first.slug, 'tarot-fali');
      expect(menu.jetonBalance, 50);
      expect(menu.creditBalance, 100);
      expect(menu.creditsPerMinute, 2);
    });
  });

  group('MobileUserProfileBundle', () {
    test('parses user stats and relationship', () {
      final profile = MobileUserProfileBundle.fromJson({
        'user': {
          'id': 'u1',
          'name': 'Mehmet',
          'profileImageUrl': 'https://example.com/a.jpg',
        },
        'stats': {'followerCount': 10, 'followingCount': 5},
        'relationship': {'isFollowing': true, 'isFollowedBy': false},
        'isOwnProfile': false,
      });

      expect(profile.user.id, 'u1');
      expect(profile.user.displayName, 'Mehmet');
      expect(profile.user.isFollowing, isTrue);
      expect(profile.stats.followers, 10);
    });
  });
}
