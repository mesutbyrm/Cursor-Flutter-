import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:canlifal_social/features/bana_ozel/domain/entities/bana_ozel_entities.dart';
import 'package:canlifal_social/features/home/domain/entities/home_page_button_entity.dart';
import 'package:canlifal_social/features/home/presentation/navigation/home_page_button_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveHomePageButtonRoute', () {
    test('maps bana-ozel specialBehavior', () {
      const button = HomePageButtonEntity(
        id: '1',
        label: 'Bana Özel',
        linkUrl: '/bana-ozel',
        specialBehavior: 'bana-ozel',
      );
      expect(resolveHomePageButtonRoute(button), '/fortune/bana-ozel');
    });

    test('maps teller specialBehavior to falci-ol', () {
      const button = HomePageButtonEntity(
        id: '2',
        label: 'Falcı Ol',
        linkUrl: '/falci-ol',
        specialBehavior: 'teller',
      );
      expect(resolveHomePageButtonRoute(button), '/falci-ol');
    });

    test('maps Yayıncı Ol label to live type even if teller behavior', () {
      const button = HomePageButtonEntity(
        id: '2b',
        label: 'Yayıncı Ol',
        linkUrl: '/yayinci-ol',
        specialBehavior: 'teller',
      );
      expect(resolveHomePageButtonRoute(button), '/live/type');
    });

    test('maps broadcaster specialBehavior to live type', () {
      const button = HomePageButtonEntity(
        id: '2c',
        label: 'Canlı yayın',
        specialBehavior: 'broadcaster',
      );
      expect(resolveHomePageButtonRoute(button), '/live/type');
    });

    test('falls back to href when no specialBehavior', () {
      const button = HomePageButtonEntity(
        id: '3',
        label: 'Oyunlar',
        linkUrl: '/oyunlar',
      );
      expect(resolveHomePageButtonRoute(button), '/oyunlar');
    });
  });

  group('BanaOzelTodayTask routes', () {
    test('login and watch_ad open growth hub', () {
      expect(BanaOzelTodayTask.login.routePath, '/profile/growth');
      expect(BanaOzelTodayTask.watchAd.routePath, '/profile/growth');
    });

    test('share opens social create', () {
      expect(BanaOzelTodayTask.share.routePath, '/social/create');
    });
  });

  test('kılavuz ana sayfa buton ve liderlik uçları', () {
    expect(ApiEndpoints.homepageButtons, '/api/homepage-buttons');
    expect(ApiEndpoints.leaderboards, '/api/leaderboards');
  });

  test('kılavuz online-fal, rozet ve izleyici uçları', () {
    expect(ApiEndpoints.onlineFal, '/api/online-fal');
    expect(ApiEndpoints.userAchievements, '/api/user/achievements');
    expect(
      ApiEndpoints.videoStreamViewers('abc'),
      '/api/video-streams/abc/viewers',
    );
  });
}
