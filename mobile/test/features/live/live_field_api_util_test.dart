import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/features/live/data/datasources/live_field/live_field_api_util.dart';

void main() {
  group('LiveFieldApiUtil', () {
    test('unwrapData başarılı data döner', () {
      final map = LiveFieldApiUtil.unwrapData({
        'success': true,
        'data': {'roomId': 'abc', 'onlineCount': 3},
      });
      expect(map?['roomId'], 'abc');
      expect(map?['onlineCount'], 3);
    });

    test('unwrapData hata fırlatır', () {
      expect(
        () => LiveFieldApiUtil.unwrapData({
          'success': false,
          'error': {'code': 'ROOM_NOT_FOUND', 'message': 'Oda yok'},
        }),
        throwsA(isA<ApiException>()),
      );
    });

    test('listFromData rooms listesi', () {
      final list = LiveFieldApiUtil.listFromData(
        {
          'success': true,
          'data': {
            'rooms': [
              {'id': 'r1', 'roomType': 'voice'},
            ],
          },
        },
        listKey: 'rooms',
      );
      expect(list, hasLength(1));
      expect(list.first['id'], 'r1');
    });
  });
}
