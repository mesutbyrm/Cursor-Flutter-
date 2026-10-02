import 'package:canlifal_social/core/push/notification_channels.dart';
import 'package:canlifal_social/features/notifications/presentation/pages/notification_channel_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('4 kanal listelenir; anahtar tercihi kalıcı yazar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: NotificationChannelSettingsPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    for (final c in AppNotificationChannel.values) {
      expect(find.text(c.label), findsOneWidget);
    }
    expect(find.text('Mesajlar'), findsOneWidget);
    expect(find.text('Canlı yayın başlatanlar'), findsOneWidget);
    expect(find.text('Günlük fal önerisi'), findsOneWidget);
    expect(find.text('Diğer'), findsOneWidget);

    // "Mesajlar" kapat.
    await tester.tap(find.byKey(const ValueKey('notif-switch-messages')));
    await tester.pump(const Duration(milliseconds: 200));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AppNotificationChannel.messages.prefsKey), isFalse);
    expect(prefs.getBool(AppNotificationChannel.other.prefsKey), isNull);
  });
}
