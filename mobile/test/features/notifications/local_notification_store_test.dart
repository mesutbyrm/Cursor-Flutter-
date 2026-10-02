import 'package:canlifal_social/features/notifications/data/local_notification_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('yerel bildirim kaydedilir ve en yeni önce listelenir', () async {
    await LocalNotificationStore.record(
      title: 'Yayın başlıyor',
      body: 'Ayşe 5 dk içinde yayında',
      targetPath: '/live',
      now: DateTime(2026, 10, 2, 10, 0),
    );
    await LocalNotificationStore.record(
      title: 'Günlük falın hazır',
      body: 'Bugünün kehaneti',
      now: DateTime(2026, 10, 2, 11, 0),
    );
    final list = await LocalNotificationStore.load();
    expect(list, hasLength(2));
    expect(list.first.title, 'Günlük falın hazır');
    expect(list.last.targetPath, '/live');
    expect(LocalNotificationStore.isLocalId(list.first.id), isTrue);
  });

  test('aynı bildirim 60 sn içinde tekrar kaydedilmez', () async {
    final t = DateTime(2026, 10, 2, 10, 0);
    await LocalNotificationStore.record(title: 'A', body: 'b', now: t);
    await LocalNotificationStore.record(
      title: 'A',
      body: 'b',
      now: t.add(const Duration(seconds: 20)),
    );
    expect(await LocalNotificationStore.load(), hasLength(1));
  });

  test('en fazla $LocalNotificationStore.maxItems kayıt; clear temizler', () async {
    for (var i = 0; i < LocalNotificationStore.maxItems + 5; i++) {
      await LocalNotificationStore.record(
        title: 'n$i',
        body: 'b$i',
        now: DateTime(2026, 10, 2).add(Duration(minutes: i)),
      );
    }
    expect(
      await LocalNotificationStore.load(),
      hasLength(LocalNotificationStore.maxItems),
    );
    await LocalNotificationStore.clear();
    expect(await LocalNotificationStore.load(), isEmpty);
  });
}
