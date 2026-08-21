import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/profile/domain/entities/profile_extended_entity.dart';
import 'package:canlifal_social/features/profile/presentation/profile_hub/profile_meta_helpers.dart';

void main() {
  group('ProfileExtendedEntity parse', () {
    test('parses zodiac team and online from nested user', () {
      final ext = ProfileExtendedEntity.fromJson({
        'user': {
          'zodiacSign': 'leo',
          'favoriteTeam': 'Galatasaray',
          'isOnline': true,
          'dailyStreak': 5,
        },
      });
      expect(ext.zodiacSign, 'leo');
      expect(ext.favoriteTeam, 'Galatasaray');
      expect(ext.isOnline, isTrue);
      expect(ext.dailyStreak, 5);
    });

    test('null bio fields stay null', () {
      final ext = ProfileExtendedEntity.fromJson({'user': {}});
      expect(ext.zodiacSign, isNull);
      expect(ext.favoriteTeam, isNull);
      expect(ext.city, isNull);
    });

    test('unknown fields do not break parse', () {
      final ext = ProfileExtendedEntity.fromJson({
        'user': {'futureField': 'x', 'zodiac': 'aries'},
      });
      expect(ext.zodiacSign, 'aries');
    });
  });

  group('profile meta helpers', () {
    test('zodiac emoji and tr label', () {
      expect(profileZodiacEmoji('leo'), '♌');
      expect(profileZodiacLabelTr('leo'), 'Aslan');
    });

    test('empty zodiac returns empty label', () {
      expect(profileZodiacLabelTr(''), '');
    });
  });
}
