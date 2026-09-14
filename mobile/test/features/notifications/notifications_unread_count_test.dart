import 'package:canlifal_social/core/util/json_util.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors [NotificationsRemoteDataSource._unreadCountFromBody] contract.
int? unreadCountFromBody(dynamic body) {
  if (body is! Map) return null;
  final map = asJsonMap(body);
  if (map['success'] == true && map['data'] != null) {
    return unreadCountFromBody(map['data']);
  }
  final layer = map['data'] is Map ? asJsonMap(map['data']) : map;
  final countRaw = pick(layer, [
    'unreadCount',
    'count',
    'unread',
    'totalUnread',
  ]);
  if (countRaw != null) return asInt(countRaw);
  return null;
}

void main() {
  test('parses unread count from notifications envelope', () {
    expect(
      unreadCountFromBody({
        'success': true,
        'data': {'unreadCount': 3},
      }),
      3,
    );
  });

  test('parses flat unread count', () {
    expect(unreadCountFromBody({'count': 7}), 7);
  });
}
