import 'package:canlifal_social/features/auth/domain/entities/active_session_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ActiveSessionEntity uses deviceId when id missing', () {
    final entity = ActiveSessionEntity.fromJson({
      'deviceId': 'dev-1',
      'deviceLabel': 'Pixel',
      'devicePlatform': 'android',
      'lastSeenAt': '2026-09-12T10:00:00.000Z',
      'createdAt': '2026-09-01T10:00:00.000Z',
      'expiresAt': '2027-09-01T10:00:00.000Z',
    });
    expect(entity.id, 'dev-1');
    expect(entity.deviceLabel, 'Pixel');
  });
}
