import 'dart:io';

import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';

/// Harici servisler (Invidious, Piped vb.) — canlifal legacy path değil.
bool _isExternalApiPath(String path) {
  return path.contains('piped') ||
      path.contains('invidious') ||
      path.contains('kavin.rocks') ||
      path.contains('pipedapi') ||
      path.contains('piped.video') ||
      path.contains('googlevideo.com') ||
      path.contains('youtube.com/api/');
}

bool _isLegacyCanlifalPath(String path) {
  if (_isExternalApiPath(path)) return false;
  if (path.startsWith('/api/v1/') || path.startsWith('/api/v2/')) return true;
  if (path.startsWith('/api/payment/')) return true;
  if (path == '/api/membership/packages') return true;
  if (RegExp(r'^/api/rooms/[^/]+/music').hasMatch(path)) return true;
  return false;
}

Set<String> _collectApiLiteralsFromSource(String source) {
  return RegExp(r"""['"](/api/[^'"]+)['"]""")
      .allMatches(source)
      .map((match) => match.group(1)!)
      .toSet();
}

Iterable<File> _dartSourcesUnderLib() sync* {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) return;
  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      yield entity;
    }
  }
}

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

    test('api_endpoints.dart literals do not reintroduce removed API paths', () {
      final source = File('lib/core/network/api_endpoints.dart').readAsStringSync();
      final literals = _collectApiLiteralsFromSource(source);

      expect(literals.where(_isLegacyCanlifalPath), isEmpty);
      expect(literals, isNot(contains('/api/payment-methods')));
      expect(literals, isNot(contains('/api/gifts')));
      expect(literals, isNot(contains(r'/api/chat/rooms/$roomId/skip')));
      expect(literals, isNot(contains(r'/api/chat/rooms/$roomId/pause')));
      expect(literals, isNot(contains(r'/api/chat/rooms/$roomId/resume')));
      expect(literals, isNot(contains(r'/api/rooms/$roomId/music/current')));
    });

    test('production lib/ sources do not embed legacy canlifal API paths', () {
      final violations = <String>[];
      for (final file in _dartSourcesUnderLib()) {
        final relative = file.path.replaceAll('\\', '/');
        // v1 mirror yalnızca opt-in dart-define ile; üretimde kullanılmaz.
        if (relative.endsWith('api_path_v1.dart') ||
            relative.endsWith('api_version_interceptor.dart') ||
            relative.endsWith('api_config.dart')) {
          continue;
        }
        final literals = _collectApiLiteralsFromSource(file.readAsStringSync());
        for (final path in literals.where(_isLegacyCanlifalPath)) {
          violations.add('$relative → $path');
        }
      }
      expect(
        violations,
        isEmpty,
        reason: 'Legacy canlifal paths found:\n${violations.join('\n')}',
      );
    });

    test('canonical payment, membership and music paths are present in lib/', () {
      final allLiterals = <String>{};
      for (final file in _dartSourcesUnderLib()) {
        allLiterals.addAll(
          _collectApiLiteralsFromSource(file.readAsStringSync()),
        );
      }
      expect(allLiterals, contains('/api/payments/config'));
      expect(allLiterals, contains('/api/payments/requests'));
      expect(allLiterals, contains('/api/memberships/packages'));
      expect(
        allLiterals.any((p) => p.contains('/api/chat/rooms/') && p.endsWith('/music')),
        isTrue,
      );
    });
  });
}
