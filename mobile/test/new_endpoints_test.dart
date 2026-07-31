import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/auth/data/models/apple_full_name.dart';
import 'package:canlifal_social/core/config/models/mobile_config.dart';
import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/features/platform/data/models/fortune_request_type.dart';
import 'package:canlifal_social/features/platform/data/models/platform_ad.dart';
import 'package:canlifal_social/features/platform/data/models/platform_popup.dart';
import 'package:canlifal_social/services/models/user_action_models.dart';

void main() {
  group('AppleFullName', () {
    test('toJson omits empty names', () {
      expect(const AppleFullName().toJson(), isNull);
    });

    test('toJson maps given and family name', () {
      final json = const AppleFullName(
        givenName: 'Ali',
        familyName: 'Yılmaz',
      ).toJson();
      expect(json, {
        'givenName': 'Ali',
        'familyName': 'Yılmaz',
      });
    });
  });

  group('MobileConfig', () {
    test('parseRoot reads success wrapper', () {
      final config = MobileConfig.parseRoot({
        'success': true,
        'data': {
          'maintenance': {'enabled': true, 'message': 'Bakım'},
          'version': {
            'forceUpdate': true,
            'optionalUpdate': false,
            'storeUrl': 'https://store.example/app',
          },
          'features': {
            'liveStream': false,
            'chat': true,
          },
          'links': {
            'terms': 'https://canlifal.com/terms',
          },
        },
      });
      expect(config.maintenance.enabled, isTrue);
      expect(config.maintenance.message, 'Bakım');
      expect(config.version.forceUpdate, isTrue);
      expect(config.features.liveStream, isFalse);
      expect(config.features.chat, isTrue);
      expect(config.links.terms, 'https://canlifal.com/terms');
    });
  });

  group('Faz 5 platform endpoints', () {
    test('ApiEndpoints registry paths', () {
      expect(ApiEndpoints.popups, '/api/popups');
      expect(ApiEndpoints.adsActive, '/api/ads/active');
      expect(ApiEndpoints.adsReward, '/api/ads/reward');
      expect(ApiEndpoints.fortuneRequestTypes, '/api/fortune-request-types');
      expect(ApiEndpoints.userTheme, '/api/user/theme');
      expect(
        ApiEndpoints.videoStreamFortuneMyStatus('s1'),
        '/api/video-streams/s1/fortune-requests/my-status',
      );
    });

    test('PlatformPopup parses list item', () {
      final popup = PlatformPopup.fromJson({
        'id': 'p1',
        'title': 'Hoş geldin',
        'message': 'Yeni özellikler',
        'actionUrl': '/feed',
      });
      expect(popup.id, 'p1');
      expect(popup.title, 'Hoş geldin');
      expect(popup.actionUrl, '/feed');
    });

    test('PlatformAd parses placement', () {
      final ad = PlatformAd.fromJson({
        'id': 'a1',
        'placement': 'rewarded',
        'unitId': 'ca-app-pub-1',
      });
      expect(ad.id, 'a1');
      expect(ad.placement, 'rewarded');
    });

    test('FortuneRequestType parses slug', () {
      final type = FortuneRequestType.fromJson({
        'slug': 'tarot',
        'label': 'Tarot',
        'jetonCost': 50,
      });
      expect(type.key, 'tarot');
      expect(type.label, 'Tarot');
      expect(type.jetonCost, 50);
    });

    test('ApiException maps 429', () {
      final err = const ApiException('rate', statusCode: 429);
      expect(err.statusCode, 429);
      expect(ApiException.userMessage(err), contains('Çok fazla istek'));
    });
  });

  group('UserAction models', () {
    test('UserReportReason api values', () {
      expect(UserReportReason.harassment.apiValue, 'harassment');
      expect(
        UserReportReason.inappropriateContent.apiValue,
        'inappropriate_content',
      );
    });

    test('UserBlockResult parses toggle response', () {
      final result = UserBlockResult.fromJson({
        'success': true,
        'blocked': false,
        'message': 'Engel kaldırıldı',
      });
      expect(result.success, isTrue);
      expect(result.blocked, isFalse);
      expect(result.message, 'Engel kaldırıldı');
    });

    test('BlockedUserEntry parses list item', () {
      final entry = BlockedUserEntry.fromJson({
        'userId': 'u1',
        'name': 'Test',
        'username': 'tester',
        'image': 'https://cdn/img.png',
        'blockedAt': '2026-07-16T12:00:00.000Z',
      });
      expect(entry.userId, 'u1');
      expect(entry.username, 'tester');
      expect(entry.blockedAt, isNotNull);
    });
  });
}
