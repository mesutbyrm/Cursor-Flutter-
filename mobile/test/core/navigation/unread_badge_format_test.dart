import 'package:canlifal_social/core/navigation/unread_badge_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('label formats counts', () {
    expect(UnreadBadgeFormat.label(0), '');
    expect(UnreadBadgeFormat.label(3), '3');
    expect(UnreadBadgeFormat.label(9), '9');
    expect(UnreadBadgeFormat.label(10), '9+');
    expect(UnreadBadgeFormat.label(999), '9+');
    expect(UnreadBadgeFormat.label(1000), '999+');
  });
}
