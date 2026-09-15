import 'package:canlifal_social/core/me/vip_preferences_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VipPreferences round-trip json', () {
    const prefs = VipPreferences(
      hideOnlineStatus: true,
      hiddenRoomEntry: true,
    );
    final back = VipPreferences.fromJson(prefs.toJson());
    expect(back.hideOnlineStatus, isTrue);
    expect(back.hiddenRoomEntry, isTrue);
  });

  test('parses rejected list', () {
    final p = VipPreferences.fromJson({
      'hideVipBadge': false,
      'rejected': ['hiddenOnline'],
    });
    expect(p.rejected, ['hiddenOnline']);
  });
}
