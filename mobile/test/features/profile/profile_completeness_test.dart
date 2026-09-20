import 'package:canlifal_social/features/profile/domain/profile_completeness.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('missingProfileItems', () {
    test('all empty → all six fields missing', () {
      final missing = missingProfileItems(username: 'ali');
      expect(missing.map((e) => e.key), [
        'avatar',
        'displayName',
        'bio',
        'city',
        'zodiac',
        'favoriteTeam',
      ]);
    });

    test('fully filled → nothing missing', () {
      final missing = missingProfileItems(
        username: 'ali',
        avatarUrl: 'https://x/a.png',
        displayName: 'Ali Veli',
        bio: 'Merhaba',
        city: 'İstanbul',
        zodiac: 'Koç',
        favoriteTeam: 'GS',
      );
      expect(missing, isEmpty);
    });

    test('displayName equal to username counts as missing', () {
      final missing = missingProfileItems(
        username: 'ali',
        avatarUrl: 'https://x/a.png',
        displayName: 'ali',
        bio: 'Merhaba',
        city: 'İzmir',
        zodiac: 'Koç',
        favoriteTeam: 'FB',
      );
      expect(missing.map((e) => e.key), ['displayName']);
    });

    test('whitespace-only values count as missing', () {
      final missing = missingProfileItems(
        username: 'ali',
        avatarUrl: '  ',
        displayName: 'Ali',
        bio: '   ',
        city: 'İstanbul',
        zodiac: 'Koç',
        favoriteTeam: 'BJK',
      );
      expect(missing.map((e) => e.key), ['avatar', 'bio']);
    });
  });

  group('profileCompletionPercent', () {
    test('0 missing → 100%', () {
      expect(profileCompletionPercent(0), 100);
    });
    test('all 6 missing → 0%', () {
      expect(profileCompletionPercent(6), 0);
    });
    test('3 missing → 50%', () {
      expect(profileCompletionPercent(3), 50);
    });
  });
}
