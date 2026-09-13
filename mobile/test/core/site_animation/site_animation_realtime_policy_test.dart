import 'package:canlifal_social/core/site_animation/domain/site_animation_type.dart';
import 'package:canlifal_social/core/site_animation/presentation/site_animation_realtime_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('activeGoldEntranceMembershipFromPayload', () {
    test('gold membership qualifies', () {
      expect(
        activeGoldEntranceMembershipFromPayload({'membership': 'gold'}),
        isTrue,
      );
    });

    test('basic membership does not qualify', () {
      expect(
        activeGoldEntranceMembershipFromPayload({'membership': 'basic'}),
        isFalse,
      );
    });

    test('expired gold does not qualify when days known', () {
      expect(
        activeGoldEntranceMembershipFromPayload({
          'membership': 'gold',
          'daysRemaining': 0,
        }),
        isFalse,
      );
    });
  });

  group('shouldPlayRealtimeMemberEntranceExit', () {
    const epoch = 1000000;

    test('blocks before session armed', () {
      expect(
        shouldPlayRealtimeMemberEntranceExit(
          type: SiteAnimationType.memberJoined,
          payload: {'membership': 'gold', 'timestamp': epoch + 100},
          effectsArmed: false,
          sessionEpochMs: epoch,
          memberWasAlreadyKnown: false,
        ),
        isFalse,
      );
    });

    test('blocks historical event before epoch', () {
      expect(
        shouldPlayRealtimeMemberEntranceExit(
          type: SiteAnimationType.memberJoined,
          payload: {'membership': 'gold', 'timestamp': epoch - 1},
          effectsArmed: true,
          sessionEpochMs: epoch,
          memberWasAlreadyKnown: false,
        ),
        isFalse,
      );
    });

    test('allows gold join after epoch', () {
      expect(
        shouldPlayRealtimeMemberEntranceExit(
          type: SiteAnimationType.memberJoined,
          payload: {'membership': 'gold', 'timestamp': epoch + 50},
          effectsArmed: true,
          sessionEpochMs: epoch,
          memberWasAlreadyKnown: false,
        ),
        isTrue,
      );
    });

    test('blocks duplicate known member', () {
      expect(
        shouldPlayRealtimeMemberEntranceExit(
          type: SiteAnimationType.memberJoined,
          payload: {'membership': 'gold', 'timestamp': epoch + 50},
          effectsArmed: true,
          sessionEpochMs: epoch,
          memberWasAlreadyKnown: true,
        ),
        isFalse,
      );
    });

    test('non-gold join blocked', () {
      expect(
        shouldPlayRealtimeMemberEntranceExit(
          type: SiteAnimationType.memberJoined,
          payload: {'membership': 'basic', 'timestamp': epoch + 50},
          effectsArmed: true,
          sessionEpochMs: epoch,
          memberWasAlreadyKnown: false,
        ),
        isFalse,
      );
    });
  });
}
