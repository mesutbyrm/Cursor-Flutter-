import 'package:canlifal_social/features/live/domain/pk/pk_leaderboard_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PkStats parses backend wrapper { success, stats, data }', () {
    const payload = {
      'success': true,
      'stats': {
        'wins': 3,
        'losses': 1,
        'draws': 0,
        'totalScore': 900,
        'bestScore': 400,
        'streak': 2,
        'winRate': 75,
      },
      'data': {
        'wins': 3,
        'losses': 1,
      },
    };
    final s = PkStats.fromJson(payload);
    expect(s.wins, 3);
    expect(s.losses, 1);
    expect(s.totalScore, 900);
    expect(s.streak, 2);
  });
}
