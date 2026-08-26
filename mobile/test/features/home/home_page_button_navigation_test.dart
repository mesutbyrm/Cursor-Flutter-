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

  test('kılavuz müzik, PK geçmiş, yorum ve istatistik uçları', () {
    expect(ApiEndpoints.shortVideosMusic, '/api/short-videos/music');
    expect(ApiEndpoints.pkHistory, '/api/pk/history');
    expect(
      ApiEndpoints.socialPostComments('post-1'),
      '/api/social/posts/post-1/comments',
    );
    expect(ApiEndpoints.userStats, '/api/user/stats');
  });

  test('kılavuz profil, üyelik, fal, oyun ve hediye uçları', () {
    expect(ApiEndpoints.userProfile('u1'), '/api/users/u1');
    expect(ApiEndpoints.membershipsCatalog, '/api/memberships');
    expect(ApiEndpoints.userActivity, '/api/user/activity');
    expect(ApiEndpoints.searchAll('ali'), '/api/search?q=ali');
    expect(ApiEndpoints.userFortunes, '/api/user/fortunes');
    expect(ApiEndpoints.userFortuneDetail('f1'), '/api/user/fortunes/f1');
    expect(ApiEndpoints.gameLeaderboard, '/api/games/leaderboard');
    expect(ApiEndpoints.gameRooms, '/api/games/rooms');
    expect(ApiEndpoints.giftsTypes, '/api/gifts/types');
  });

  test('kılavuz falcı, shorts, paylaşım ve PK liderlik uçları', () {
    expect(
      ApiEndpoints.fortuneTellerReviews('t1'),
      '/api/fortune-tellers/t1/reviews',
    );
    expect(
      ApiEndpoints.fortuneTellerAwards('t1'),
      '/api/fortune-tellers/awards?tellerId=t1',
    );
    expect(
      ApiEndpoints.shortVideosByUser('u1'),
      '/api/short-videos/user/u1',
    );
    expect(ApiEndpoints.userPosts('u1'), '/api/users/u1/posts');
    expect(ApiEndpoints.pkLeaderboard, '/api/pk/leaderboard');
  });

  test('kılavuz çekim, referans, site CMS ve mesaj uçları', () {
    expect(ApiEndpoints.withdrawals, '/api/withdrawals');
    expect(ApiEndpoints.referral, '/api/referral');
    expect(ApiEndpoints.sitePage('kvkk'), '/api/site-pages/kvkk');
    expect(ApiEndpoints.messages, '/api/messages');
    expect(ApiEndpoints.giftsTypes, '/api/gifts/types');
    expect(ApiEndpoints.tournaments, '/api/tournaments');
  });

  test('kılavuz cüzdan ve shorts uçları', () {
    expect(ApiEndpoints.wallet, '/api/wallet');
    expect(ApiEndpoints.shortVideos, '/api/short-videos');
    expect(ApiEndpoints.me, '/api/me');
  });

  test('kılavuz falcı ödül ve destekçi rozet uçları', () {
    expect(
      ApiEndpoints.fortuneTellerAwards('t1'),
      '/api/fortune-tellers/awards?tellerId=t1',
    );
    expect(ApiEndpoints.giftsInsightsMeBadge, '/api/gifts/insights/me/badge');
  });

  test('kılavuz canlı fal, PK ve ortak yayın uçları', () {
    expect(
      ApiEndpoints.videoStreamFortuneRequests('s1'),
      '/api/video-streams/s1/fortune-requests',
    );
    expect(
      ApiEndpoints.videoStreamFortuneMyStatus('s1'),
      '/api/video-streams/s1/fortune-requests/my-status',
    );
    expect(ApiEndpoints.fortuneRequestTypes, '/api/fortune-request-types');
    expect(
      ApiEndpoints.videoStreamPkBattle('s1'),
      '/api/video-streams/s1/pk-battle',
    );
    expect(
      ApiEndpoints.videoStreamCoBroadcast('s1'),
      '/api/video-streams/s1/co-broadcast',
    );
  });

  test('kılavuz alınan hediyeler ve oyun uçları', () {
    expect(ApiEndpoints.userReceivedGifts, '/api/user/received-gifts');
    expect(ApiEndpoints.homeGames, '/api/games');
    expect(ApiEndpoints.gameLeaderboard, '/api/games/leaderboard');
  });

  test('kılavuz istatistik, takip, arama ve yorum uçları', () {
    expect(ApiEndpoints.userStats, '/api/user/stats');
    expect(ApiEndpoints.userActivity, '/api/user/activity');
    expect(ApiEndpoints.userFollowers, '/api/user/followers');
    expect(ApiEndpoints.dailyMissions, '/api/daily-missions');
    expect(ApiEndpoints.searchAll('ali'), '/api/search?q=ali');
    expect(
      ApiEndpoints.shortVideoComments('v1'),
      '/api/short-videos/v1/comments',
    );
  });

  test('kılavuz rozet, çerçeve ve başarım uçları', () {
    expect(ApiEndpoints.membershipBadges, '/api/membership-badges');
    expect(ApiEndpoints.profileFrames, '/api/profile-frames');
    expect(ApiEndpoints.userAchievements, '/api/user/achievements');
  });

  test('kılavuz duyuru, falcı hediye/yorum ve liderlik uçları', () {
    expect(ApiEndpoints.announcements, '/api/announcements');
    expect(ApiEndpoints.fortuneRequestTypes, '/api/fortune-request-types');
    expect(
      ApiEndpoints.fortuneTellerReviews('t1'),
      '/api/fortune-tellers/t1/reviews',
    );
    expect(
      ApiEndpoints.fortuneTellerGifts('t1'),
      '/api/fortune-tellers/gifts?tellerId=t1',
    );
    expect(ApiEndpoints.fortuneTellerSession, '/api/fortune-tellers/session');
    expect(ApiEndpoints.leaderboards, '/api/leaderboards');
  });

  test('kılavuz futbol, kişiler, ajans ve favori falcı uçları', () {
    expect(ApiEndpoints.football, '/api/football');
    expect(ApiEndpoints.usersOnline, '/api/users/online');
    expect(ApiEndpoints.userLikers, '/api/user/likers');
    expect(ApiEndpoints.agencyMembers, '/api/agency/members');
    expect(ApiEndpoints.agencyEarnings, '/api/agency/earnings');
    expect(ApiEndpoints.agencyLeaderboard, '/api/agency/leaderboard');
    expect(ApiEndpoints.favoriteTellers, '/api/favorite-tellers');
    expect(
      ApiEndpoints.videoStreamGiftLeaderboard('s1'),
      '/api/video-streams/s1/gifts/leaderboard',
    );
  });

  test('kılavuz izleyici, fal kartı, günlük ödül ve içerik hub uçları', () {
    expect(
      ApiEndpoints.videoStreamViewers('s1'),
      '/api/video-streams/s1/viewers',
    );
    expect(ApiEndpoints.homepageFortuneCards, '/api/homepage-fortune-cards');
    expect(ApiEndpoints.homeDailyRewards, '/api/daily-rewards');
    expect(ApiEndpoints.homepageButtons, '/api/homepage-buttons');
    expect(ApiEndpoints.dreams, '/api/dreams');
    expect(ApiEndpoints.blog, '/api/blog');
  });

  test('kılavuz falcı listesi, profilim ve seviye uçları', () {
    expect(ApiEndpoints.fortuneTellers, '/api/fortune-tellers');
    expect(ApiEndpoints.fortuneTellerMyProfile, '/api/fortune-tellers/my-profile');
    expect(ApiEndpoints.me, '/api/me');
  });

  test('kılavuz mesaj, ajans profilim ve oyun skor uçları', () {
    expect(ApiEndpoints.messages, '/api/messages');
    expect(ApiEndpoints.messagesConversations, '/api/messages/conversations');
    expect(ApiEndpoints.agencyMy, '/api/agency/my');
    expect(ApiEndpoints.gameMiniScores, '/api/games/mini-scores');
    expect(ApiEndpoints.gameHistory, '/api/games/history');
  });

  test('kılavuz falcı çevrimiçi ve üyelik katalog uçları', () {
    expect(
      ApiEndpoints.fortuneTellerToggleOnline,
      '/api/fortune-tellers/toggle-online',
    );
    expect(ApiEndpoints.membershipPackages, '/api/memberships/packages');
    expect(ApiEndpoints.membershipsCatalog, '/api/memberships');
  });
}
