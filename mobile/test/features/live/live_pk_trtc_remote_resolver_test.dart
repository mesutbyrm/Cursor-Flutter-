import 'package:canlifal_social/features/live/domain/pk/live_pk_trtc_remote_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveLivePkTrtcRemoteUserId', () {
    test('prefers exact preferred id when present in remotes', () {
      expect(
        resolveLivePkTrtcRemoteUserId(
          preferredUserId: 'user-guest',
          remoteUserIds: ['user-host', 'user-guest'],
          localTrtcUserId: 'user-host',
        ),
        'user-guest',
      );
    });

    test('falls back to sole remote when preferred missing', () {
      expect(
        resolveLivePkTrtcRemoteUserId(
          preferredUserId: 'wrong-id',
          remoteUserIds: ['trtc-abc'],
          localTrtcUserId: 'me',
        ),
        'trtc-abc',
      );
    });

    test('returns null when no remotes', () {
      expect(
        resolveLivePkTrtcRemoteUserId(
          preferredUserId: 'u1',
          remoteUserIds: const [],
          localTrtcUserId: 'me',
        ),
        isNull,
      );
    });
  });
}
