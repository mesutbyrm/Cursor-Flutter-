import 'package:canlifal_social/features/live/domain/utils/co_guest_camera_signal_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('co_guest_camera signal util', () {
    test('isCoGuestCameraSignal detects type variants', () {
      expect(
        isCoGuestCameraSignal({'type': 'co_guest_camera'}),
        isTrue,
      );
      expect(
        isCoGuestCameraSignal({'event': 'co_guest_camera'}),
        isTrue,
      );
      expect(isCoGuestCameraSignal({'type': 'like'}), isFalse);
    });

    test('coGuestCameraTargetsUser respects receiverId', () {
      const sig = {
        'type': 'co_guest_camera',
        'receiverId': 'guest-1',
        'data': {'enabled': true},
      };
      expect(coGuestCameraTargetsUser(sig, 'guest-1'), isTrue);
      expect(coGuestCameraTargetsUser(sig, 'guest-2'), isFalse);
      expect(coGuestCameraTargetsUser({'type': 'co_guest_camera'}, 'any'), isTrue);
    });

    test('parseCoGuestCameraEnabled handles bool and string', () {
      expect(
        parseCoGuestCameraEnabled({
          'type': 'co_guest_camera',
          'data': {'enabled': true},
        }),
        isTrue,
      );
      expect(
        parseCoGuestCameraEnabled({
          'type': 'co_guest_camera',
          'payload': {'enabled': 'off'},
        }),
        isFalse,
      );
      expect(
        parseCoGuestCameraEnabled({
          'type': 'co_guest_camera',
          'enabled': 1,
        }),
        isTrue,
      );
    });

    test('resolveCoGuestCameraForUser returns null when not targeted', () {
      expect(
        resolveCoGuestCameraForUser(
          sig: {
            'type': 'co_guest_camera',
            'receiverId': 'a',
            'data': {'enabled': false},
          },
          selfUserId: 'b',
        ),
        isNull,
      );
      expect(
        resolveCoGuestCameraForUser(
          sig: {
            'type': 'co_guest_camera',
            'receiverId': 'a',
            'data': {'enabled': false},
          },
          selfUserId: 'a',
        ),
        isFalse,
      );
    });
  });
}
