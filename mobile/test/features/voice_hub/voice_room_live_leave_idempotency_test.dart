import 'package:canlifal_social/features/voice_hub/presentation/coordinators/room_leave_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RoomLeaveCoordinator blocks parallel leave', () async {
    final coordinator = RoomLeaveCoordinator();
    var runs = 0;

    final first = coordinator.leave(
      roomId: 'r1',
      source: 'test',
      steps: [
        () async {
          runs++;
          await Future<void>.delayed(const Duration(milliseconds: 50));
        },
      ],
    );

    final second = coordinator.leave(
      roomId: 'r1',
      source: 'test',
      steps: [
        () async {
          runs++;
        },
      ],
    );

    await Future.wait([first, second]);
    expect(runs, 1);
  });
}
