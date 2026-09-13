import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('gift box canonical paths', () {
    test('matches Abacus OpenAPI paths', () {
      expect(ApiEndpoints.giftBox, '/api/gift-box');
      expect(ApiEndpoints.giftBoxById('b1'), '/api/gift-box/b1');
      expect(ApiEndpoints.giftBoxJoin('b1'), '/api/gift-box/b1/join');
      expect(ApiEndpoints.giftBoxShare, '/api/gift-box/share');
      expect(ApiEndpoints.chatRoomSync('r1'), '/api/chat/rooms/r1/sync');
      expect(
        ApiEndpoints.videoStreamSync('s1'),
        '/api/video-streams/s1/sync',
      );
    });
  });
}
