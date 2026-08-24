import 'package:canlifal_social/features/gifts/domain/gift_goal.dart';
import 'package:canlifal_social/features/gifts/presentation/providers/gift_goal_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GiftGoalState dismissed hides completed goal', () {
    const st = GiftGoalState(
      goal: GiftGoal(
        id: 'g1',
        title: 'Hedef',
        targetAmount: 100,
        currentAmount: 100,
        status: 'completed',
      ),
      dismissed: true,
    );
    expect(st.dismissed, isTrue);
    expect(st.goal!.isCompleted, isTrue);
  });
}
