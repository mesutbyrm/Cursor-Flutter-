import 'package:canlifal_social/features/gift_box/domain/entities/gift_box_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GiftBoxListSnapshot parses boxes and limits', () {
    final snap = GiftBoxListSnapshot.fromApi({
      'limits': {'minAmount': 10, 'maxAmount': 5000, 'allowedDurations': [30, 60]},
      'boxes': [
        {
          'id': 'b1',
          'status': 'active',
          'totalAmount': 200,
          'winnerCount': 5,
          'remainingWinners': 3,
          'remainingSec': 45,
          'taskType': 'share',
        },
      ],
      'me': {'joinedBoxIds': ['b0']},
    });
    expect(snap.boxes.length, 1);
    expect(snap.boxes.first.id, 'b1');
    expect(snap.limits.minAmount, 10);
    expect(snap.limits.allowedDurations, [30, 60]);
  });
}
