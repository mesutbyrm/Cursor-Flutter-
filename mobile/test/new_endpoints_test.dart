import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/auth/data/models/apple_full_name.dart';
import 'package:canlifal_social/core/config/models/mobile_config.dart';
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
