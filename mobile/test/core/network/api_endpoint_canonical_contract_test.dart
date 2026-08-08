import 'dart:io';

import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canonical API endpoint contracts', () {
    test('payment and membership endpoints use uploaded backend canonical paths', () {
      expect(ApiEndpoints.paymentConfig, '/api/payments/config');
      expect(ApiEndpoints.paymentMethods, '/api/payments/methods');
      expect(ApiEndpoints.paymentRequests, '/api/payments/requests');
      expect(ApiEndpoints.paymentRequestsCancel, '/api/payments/requests');
      expect(ApiEndpoints.membershipPackages, '/api/memberships/packages');
      expect(ApiEndpoints.membershipPurchase, '/api/memberships/purchase');
    });

    test('music controls prefer chat room canonical endpoints', () {
      expect(ApiEndpoints.chatRoomSongRequest('r1'), '/api/chat/rooms/r1/song-request');
      expect(ApiEndpoints.chatRoomSongSkip('r1'), '/api/chat/rooms/r1/music');
      expect(ApiEndpoints.chatRoomSongStop('r1'), '/api/chat/rooms/r1/music/stop');
    });

    test('production endpoint literals do not reintroduce removed API paths', () {
      final source = File('lib/core/network/api_endpoints.dart').readAsStringSync();
      final literals = RegExp(r"""['"](/api/[^'"]+)['"]""")
          .allMatches(source)
          .map((match) => match.group(1)!)
          .toSet();

      expect(literals.where((path) => path.startsWith('/api/v1/')), isEmpty);
      expect(literals.where((path) => path.startsWith('/api/v2/')), isEmpty);
      expect(literals.where((path) => path.startsWith('/api/payment/')), isEmpty);
      expect(literals, isNot(contains('/api/payment-methods')));
      expect(literals, isNot(contains('/api/membership/packages')));
      expect(literals, isNot(contains(r'/api/chat/rooms/$roomId/skip')));
      expect(literals, isNot(contains(r'/api/chat/rooms/$roomId/pause')));
      expect(literals, isNot(contains(r'/api/chat/rooms/$roomId/resume')));
      expect(literals, isNot(contains(r'/api/rooms/$roomId/music/current')));
    });
  });
}
