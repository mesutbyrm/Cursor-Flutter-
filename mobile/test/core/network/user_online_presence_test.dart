import 'package:canlifal_social/core/network/user_online_presence_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseOnlineUserIds', () {
    test('parses list of string ids', () {
      final ids = parseOnlineUserIds(['a', 'b', 'c']);
      expect(ids, {'a', 'b', 'c'});
    });

    test('parses users array in map', () {
      final ids = parseOnlineUserIds({
        'users': [
          {'id': 'u1'},
          {'userId': 'u2'},
        ],
      });
      expect(ids, {'u1', 'u2'});
    });

    test('parses userIds field', () {
      final ids = parseOnlineUserIds({
        'userIds': ['x', 'y'],
      });
      expect(ids, {'x', 'y'});
    });
  });
}
