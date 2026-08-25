import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/games/domain/game_center_models.dart';

void main() {
  test('parses nested daily-spin prize', () {
    final result = DailySpinResult.fromJson({
      'success': true,
      'data': {
        'jeton': 25,
        'prizeLabel': '25 Jeton',
      },
    });
    expect(result.alreadySpun, isFalse);
    expect(result.jetonWon, 25);
    expect(result.prizeLabel, '25 Jeton');
  });

  test('parses already spun flag', () {
    final result = DailySpinResult.fromJson({
      'alreadySpun': true,
      'message': 'Bugün çevrildi',
    });
    expect(result.alreadySpun, isTrue);
    expect(result.message, 'Bugün çevrildi');
  });
}
