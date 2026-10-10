import 'package:canlifal_social/features/inbox/domain/system_notifications_read_sync.dart';
import 'package:canlifal_social/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotificationEntity n(String id, {String? type, String? path, bool read = false}) =>
    AppNotificationEntity(id: id, title: 't', read: read, type: type, targetPath: path);

void main() {
  test('yalnız sistem bildirimleri okundu yapılır; DM türü dokunulmaz', () async {
    final sent = <List<String>>[];
    final sync = SystemNotificationsReadSync(
      fetchUnreadPage: (p) async => p == 1
          ? [
              n('s1', type: 'live_started'),
              n('d1', type: 'new_message'),
              n('d2', type: 'system', path: '/chat/u9'),
              n('s2', type: 'earning'),
            ]
          : [],
      markReadIds: (ids) async => sent.add(ids),
    );
    final ids = await sync.run();
    expect(ids, {'s1', 's2'});
    expect(sent.expand((e) => e), unorderedEquals(['s1', 's2']));
  });

  test('sayfalama: dolu sayfa sonrası devam eder, eksik sayfada durur', () async {
    final pages = <int>[];
    final sync = SystemNotificationsReadSync(
      pageSize: 2,
      chunkSize: 2,
      fetchUnreadPage: (p) async {
        pages.add(p);
        if (p == 1) return [n('a'), n('b')];
        if (p == 2) return [n('c')];
        return [n('x')];
      },
      markReadIds: (_) async {},
    );
    expect(await sync.run(), {'a', 'b', 'c'});
    expect(pages, [1, 2]);
  });

  test('okunmamış yoksa istek atılmaz (idempotent)', () async {
    var calls = 0;
    final sync = SystemNotificationsReadSync(
      fetchUnreadPage: (_) async => [n('s1', read: true)],
      markReadIds: (_) async => calls++,
    );
    expect(await sync.run(), isEmpty);
    expect(calls, 0);
  });

  test('sunucu hatası fırlatılır (yerel durum değişmemeli)', () async {
    final sync = SystemNotificationsReadSync(
      fetchUnreadPage: (_) async => [n('s1')],
      markReadIds: (_) async => throw Exception('500'),
    );
    await expectLater(sync.run(), throwsException);
  });

  test('parçalara bölerek gönderir', () async {
    final sent = <List<String>>[];
    final sync = SystemNotificationsReadSync(
      chunkSize: 2,
      fetchUnreadPage: (_) async => [n('1'), n('2'), n('3')],
      markReadIds: (ids) async => sent.add(ids),
    );
    await sync.run();
    expect(sent.map((e) => e.length), [2, 1]);
  });
}
