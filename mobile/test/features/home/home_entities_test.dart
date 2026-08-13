import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/home/domain/entities/home_broadcast_image_entity.dart';
import 'package:canlifal_social/features/home/domain/entities/home_football_match_entity.dart';
import 'package:canlifal_social/features/home/domain/entities/home_online_fal_entity.dart';
import 'package:canlifal_social/features/home/domain/entities/home_user_liker_entity.dart';

void main() {
  group('HomeFootballMatchEntity', () {
    test('parses nested team names and scores', () {
      final match = HomeFootballMatchEntity.fromJson({
        'homeTeam': {'name': 'Galatasaray'},
        'awayTeam': {'name': 'Fenerbahçe'},
        'homeScore': 2,
        'awayScore': 1,
        'league': 'Süper Lig',
      });

      expect(match.homeTeam, 'Galatasaray');
      expect(match.awayTeam, 'Fenerbahçe');
      expect(match.scoreLabel, '2 - 1');
      expect(match.hasTeams, isTrue);
    });
  });

  group('HomeBroadcastImageEntity', () {
    test('parses image url and title', () {
      final image = HomeBroadcastImageEntity.fromJson({
        'id': 'bg-1',
        'imageUrl': 'https://canlifal.com/bg.jpg',
        'title': 'Neon',
      });

      expect(image.isValid, isTrue);
      expect(image.imageUrl, contains('bg.jpg'));
      expect(image.title, 'Neon');
    });
  });

  group('HomeOnlineFalEntity', () {
    test('parses section title and route', () {
      final section = HomeOnlineFalEntity.fromJson({
        'title': 'Canlı Tarot',
        'route': '/fortune/tarot',
      });

      expect(section.isValid, isTrue);
      expect(section.title, 'Canlı Tarot');
      expect(section.route, '/fortune/tarot');
    });
  });

  group('HomeUserLikerEntity', () {
    test('parses nested user', () {
      final liker = HomeUserLikerEntity.fromJson({
        'user': {
          'id': 'u1',
          'displayName': 'Ayşe',
          'avatarUrl': 'https://canlifal.com/a.jpg',
        },
        'timeLabel': '2 dk önce',
      });

      expect(liker.isValid, isTrue);
      expect(liker.displayName, 'Ayşe');
      expect(liker.timeLabel, '2 dk önce');
    });
  });
}
