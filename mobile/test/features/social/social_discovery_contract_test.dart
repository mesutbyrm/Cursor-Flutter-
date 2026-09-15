import 'package:canlifal_social/core/network/api_endpoints.dart';
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
