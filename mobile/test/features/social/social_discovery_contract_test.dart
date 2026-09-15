import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:canlifal_social/features/social/domain/entities/social_discovery_feed.dart';
import 'package:canlifal_social/features/social/domain/entities/social_discovery_user.dart';
import 'package:canlifal_social/features/social/domain/entities/user_location_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tanış Kaynaş Abacus endpoints', () {
    test('canonical paths', () {
      expect(ApiEndpoints.socialDiscovery, '/api/social/discovery');
      expect(ApiEndpoints.socialActions, '/api/social/actions');
      expect(ApiEndpoints.userLocation, '/api/user/location');
      expect(ApiEndpoints.socialProfile, '/api/social/profile');
      expect(ApiEndpoints.shareCard, '/api/share-card');
      expect(ApiEndpoints.activities, '/api/activities');
    });
  });

  test('SocialDiscoveryUser parses production flat user in data.users', () {
    final u = SocialDiscoveryUser.fromJson({
      'id': 'u1',
      'name': 'Ayşe',
      'username': 'ayse',
      'image': 'https://example.com/a.jpg',
      'age': 28,
      'city': 'İstanbul',
      'membership': 'gold',
      'bio': 'Merhaba',
      'hobbies': ['müzik'],
    });
    expect(u.id, 'u1');
    expect(u.displayName, 'Ayşe');
    expect(u.age, 28);
    expect(u.city, 'İstanbul');
    expect(u.membership, 'gold');
    expect(u.hobbies, ['müzik']);
  });

  test('SocialDiscoveryUser parses nested user without inventing fields', () {
    final u = SocialDiscoveryUser.fromJson({
      'user': {'id': 'u1', 'displayName': 'Ayşe', 'username': 'ayse'},
      'distanceKm': 2.5,
    });
    expect(u.id, 'u1');
    expect(u.displayName, 'Ayşe');
    expect(u.distanceLabel, contains('km'));
  });

  test('SocialDiscoveryUser distanceKm and matchPercent from wire', () {
    final u = SocialDiscoveryUser.fromJson({
      'id': 'u2',
      'name': 'Test',
      'distanceKm': 12.5,
      'matchPercent': 88,
    });
    expect(u.distanceKm, 12.5);
    expect(u.matchPercent, 88);
  });

  test('SocialDiscoveryUser commonHobbies separate from hobbies', () {
    final u = SocialDiscoveryUser.fromJson({
      'id': 'u3',
      'name': 'Test',
      'hobbies': ['spor'],
      'commonHobbies': ['müzik'],
    });
    expect(u.hobbies, ['spor']);
    expect(u.commonHobbies, ['müzik']);
  });

  test('SocialDiscoveryUser actionAt from action row', () {
    final u = SocialDiscoveryUser.fromActionRow({
      'type': 'like',
      'createdAt': '2026-09-15T12:00:00.000Z',
      'otherUser': {'id': 'u9', 'name': 'Test'},
    });
    expect(u.id, 'u9');
    expect(u.actionAt?.toUtc().hour, 12);
  });

  test('SocialDiscoveryActionResult rate limit helper', () {
    const limited = SocialDiscoveryActionResult(
      success: false,
      statusCode: 429,
      message: 'Too many',
    );
    expect(limited.isRateOrQuotaLimit, isTrue);
    const msg = SocialDiscoveryActionResult(
      success: false,
      message: 'Günlük kota doldu',
    );
    expect(msg.isRateOrQuotaLimit, isTrue);
  });

  test('SocialDiscoveryFeed hasMore uses total from data envelope', () {
    const feed = SocialDiscoveryFeed(
      users: const [],
      total: 136,
      page: 1,
      limit: 20,
    );
    expect(feed.hasMore, isTrue);
  });

  test('UserLocationSettings POST body uses OpenAPI field names', () {
    final body = const UserLocationSettings().toPostBody(
      locationEnabled: true,
      showDistance: false,
      latitude: 41.0,
      longitude: 29.0,
    );
    expect(body['locationEnabled'], true);
    expect(body['showDistance'], false);
    expect(body['latitude'], 41.0);
    expect(body['longitude'], 29.0);
  });
}
