import 'package:canlifal_social/core/config/api_config.dart';
import 'package:canlifal_social/core/network/api_path_v1.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('API version contract', () {
    test('production default does not rewrite /api paths to /api/v1', () {
      expect(ApiConfig.useApiV1, isFalse);
      expect(ApiPathV1.fromLegacy('/api/me'), '/api/me');
      expect(ApiPathV1.fromLegacy('/api/chat/rooms'), '/api/chat/rooms');
      expect(ApiPathV1.fromLegacy('/api/trtc/token'), '/api/trtc/token');
    });
  });
}
