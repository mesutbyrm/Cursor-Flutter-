import 'package:canlifal_social/core/site_animation/data/site_animation_parser.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_type.dart';
import 'package:canlifal_social/core/site_animation/presentation/site_animation_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldSuppressSelfEntranceAnimation', () {
    SiteAnimationCommand cmd(String userId, SiteAnimationType type) {
      return SiteAnimationParser.fromRoomEvent(
        roomId: 'room-1',
        event: type.isEntrance ? 'user_joined' : 'user_left',
        payload: {
          'eventId': 'evt-$userId',
          'userId': userId,
          'name': 'Test',
        },
      )!;
    }

    test('suppresses own entrance', () {
      final base = cmd('self-1', SiteAnimationType.memberJoined);
      expect(
        shouldSuppressSelfEntranceAnimation(
          command: base,
          currentUserId: 'self-1',
        ),
        isTrue,
      );
    });

    test('shows other user entrance', () {
      final base = cmd('other-1', SiteAnimationType.memberJoined);
      expect(
        shouldSuppressSelfEntranceAnimation(
          command: base,
          currentUserId: 'self-1',
        ),
        isFalse,
      );
    });

    test('does not suppress own exit', () {
      final base = cmd('self-1', SiteAnimationType.memberLeft);
      expect(
        shouldSuppressSelfEntranceAnimation(
          command: base,
          currentUserId: 'self-1',
        ),
        isFalse,
      );
    });
  });
}
