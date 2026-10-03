import 'package:canlifal_social/features/profile/presentation/providers/account_privacy_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('engellenenler: {success,data:[…]} yanıtı çözülür', () {
    final rows = parseBlockedUsers({
      'success': true,
      'data': [
        {'id': 'b1', 'userId': 'u9', 'name': 'Ayşe', 'username': 'ayse', 'image': 'https://x/y.png'},
        {'id': 'b2', 'userId': 'u8', 'name': null, 'username': 'can'},
        {'id': 'b3', 'userId': ''},
      ],
    });
    expect(rows.length, 2);
    expect(rows.first.userId, 'u9');
    expect(rows.first.name, 'Ayşe');
    expect(rows.last.name, 'can');
  });

  test('engellenenler: boş / beklenmedik gövde → boş liste', () {
    expect(parseBlockedUsers(null), isEmpty);
    expect(parseBlockedUsers({'data': 'x'}), isEmpty);
  });
}
