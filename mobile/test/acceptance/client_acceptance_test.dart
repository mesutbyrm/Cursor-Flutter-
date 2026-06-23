import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:canlifal_social/core/storage/theme_preferences.dart';
import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/voice_hub/domain/voice_music_sync.dart';

/// İstemci tarafı acceptance testleri — 18, 19, 20.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('18 — Müzik sistemi (!istek)', () {
    test('!istek komutu parse edilir', () {
      expect(
        VoiceMusicSync.parseIstekSongTitle('!istek Tarkan - Kış Güneşi'),
        'Tarkan - Kış Güneşi',
      );
    });

    test('SONG_REQUEST_FREE kuyruk satırı tanınır', () {
      expect(
        VoiceMusicSync.isQueueUpdateMessage(
          '[SONG_REQUEST_FREE] abc|Title|||',
        ),
        isTrue,
      );
    });
  });

  group('19 — Tema değiştirme', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ThemePreferences.init();
    });

    test('açık/koyu/sistem teması kaydedilir ve okunur', () async {
      await ThemePreferences.saveThemeMode(ThemeMode.light);
      expect(ThemePreferences.loadThemeMode(), ThemeMode.light);

      await ThemePreferences.saveThemeMode(ThemeMode.dark);
      expect(ThemePreferences.loadThemeMode(), ThemeMode.dark);

      await ThemePreferences.saveThemeMode(ThemeMode.system);
      expect(ThemePreferences.loadThemeMode(), ThemeMode.system);
    });

    test('AMOLED bayrağı kalıcıdır', () async {
      await ThemePreferences.saveAmoledDark(true);
      expect(ThemePreferences.loadAmoledDark(), isTrue);
      await ThemePreferences.saveAmoledDark(false);
      expect(ThemePreferences.loadAmoledDark(), isFalse);
    });

    testWidgets('tema modları MaterialApp oluşturur', (tester) async {
      for (final mode in ThemeMode.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: mode,
            home: const Scaffold(body: Text('tema')),
          ),
        );
        expect(find.text('tema'), findsOneWidget);
      }
    });
  });

  group('20 — Uygulama performans testi', () {
    test('tema fabrikası 50 çağrı < 2 sn', () {
      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 50; i++) {
        AppTheme.light();
        AppTheme.dark();
        AppTheme.amoled();
      }
      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000),
        reason: 'Tema oluşturma çok yavaş',
      );
    });
  });
}
