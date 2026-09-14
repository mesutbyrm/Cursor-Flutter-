import 'package:canlifal_social/features/home/data/mobile_home_compound_lists.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rows returns first non-empty fan club list', () {
    final rows = MobileHomeCompoundLists.rows(
      {
        'fanClubs': [
          {'id': '1', 'title': 'A'},
        ],
      },
      MobileHomeCompoundLists.fanClubKeys,
    );
    expect(rows, hasLength(1));
  });

  test('rows wraps single dailyReward map', () {
    final rows = MobileHomeCompoundLists.rows(
      {'dailyReward': {'id': 'd1', 'title': 'Giriş'}},
      MobileHomeCompoundLists.dailyRewardKeys,
    );
    expect(rows, hasLength(1));
  });
}
