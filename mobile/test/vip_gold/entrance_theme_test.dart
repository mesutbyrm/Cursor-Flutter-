import 'package:canlifal_social/features/vip_gold/domain/entrance_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TeamCatalog', () {
    test('returns Turkey default when no team', () {
      final theme = TeamCatalog.resolve();
      expect(theme.isDefaultTurkey, isTrue);
      expect(theme.primary, EntranceTheme.turkey.primary);
      expect(theme.flagEmoji, '🇹🇷');
    });

    test('maps favoriteTeam aliases to club colors', () {
      final gs = TeamCatalog.resolve(favoriteTeam: 'galatasaray');
      expect(gs.teamName, 'Galatasaray');
      expect(gs.primary, const Color(0xFFA90432));

      final fb = TeamCatalog.resolve(favoriteTeam: 'Fenerbahçe');
      expect(fb.teamName, 'Fenerbahçe');
      expect(fb.secondary, const Color(0xFFFFED00));
    });

    test('prefers backend team object colors', () {
      final theme = TeamCatalog.resolve(
        favoriteTeam: 'ignored',
        teamJson: {
          'name': 'Özel Takım',
          'primaryColor': '#112233',
          'secondaryColor': '#AABBCC',
          'logoUrl': 'https://example.com/logo.png',
        },
      );
      expect(theme.teamName, 'Özel Takım');
      expect(theme.primary, const Color(0xFF112233));
      expect(theme.secondary, const Color(0xFFAABBCC));
      expect(theme.logoUrl, 'https://example.com/logo.png');
    });

    test('entranceThemeFromUserJson reads nested user team', () {
      final theme = entranceThemeFromUserJson({
        'favoriteTeam': 'besiktas',
        'team': {'primaryColor': '#000000', 'secondaryColor': '#FFFFFF'},
      });
      expect(theme.primary, const Color(0xFF000000));
    });

    test('maps city to regional colors', () {
      final izmir = CityCatalog.resolve(favoriteCity: 'İzmir');
      expect(izmir.teamName, 'İzmir');
      expect(izmir.primary, const Color(0xFF0EA5E9));
    });

    test('team catalog includes expanded super lig clubs', () {
      expect(TeamCatalog.options.length, greaterThanOrEqualTo(18));
    });
  });
}
