import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/gifts/domain/gift_display_settings.dart';
import 'package:canlifal_social/features/gifts/domain/gift_feed_item.dart';
import 'package:canlifal_social/features/gifts/domain/homepage_gift_ticker.dart';
import 'package:canlifal_social/features/gifts/presentation/global/global_gift_notification.dart';
import 'package:canlifal_social/features/gifts/presentation/global/global_gift_queue.dart';
import 'package:canlifal_social/features/home/presentation/providers/home_providers.dart';
import 'package:canlifal_social/features/home/presentation/widgets/home_ticker_strip.dart';
import 'package:canlifal_social/features/voice_hub/domain/voice_official_join.dart';

void main() {
  const screenshot =
      '🎁 Admin -> 🌸 Pembe çiçek (299 Jeton) -> ilhamperisi 🎁';

  group('homepage gift ticker detect/parse', () {
    test('screenshot ticker format is a gift announcement', () {
      expect(VoiceOfficialJoin.isHomeBannerGiftAnnouncement(screenshot), isTrue);
      expect(HomepageGiftTicker.isGiftLine(screenshot), isTrue);
    });

    test('parses sender, gift, jeton and receiver', () {
      final parsed = HomepageGiftTicker.tryParse(screenshot);
      expect(parsed, isNotNull);
      expect(parsed!.senderName, 'Admin');
      expect(parsed.giftName, '🌸 Pembe çiçek');
      expect(parsed.amount, 299);
      expect(parsed.receiverName, 'ilhamperisi');
    });

    test('composeAnnouncement builds top overlay line', () {
      expect(
        HomepageGiftTicker.composeAnnouncement(
          senderName: 'Admin',
          giftName: '🌸 Pembe çiçek',
          receiverName: 'ilhamperisi',
          amount: 299,
        ),
        '🎁 Admin → 🌸 Pembe çiçek (299 Jeton) → ilhamperisi',
      );
    });

    test('newsLines drops gifts and keeps official copy', () {
      final news = HomepageGiftTicker.newsLines([
        screenshot,
        'Yeni fal kampanyası bu hafta',
        'Admin -> Gül (50 Jeton) -> ayse',
      ]);
      expect(news, ['Yeni fal kampanyası bu hafta']);
    });

    test('first poll seeds history; later poll overlays only new gifts', () {
      final gate = HomepageGiftTickerGate();
      expect(
        gate.takeNewGiftAnnouncements([screenshot, 'eski hediye etti biri']),
        isEmpty,
      );
      expect(gate.seeded, isTrue);

      final second = gate.takeNewGiftAnnouncements([
        screenshot,
        '🎁 Ali -> 🌹 Gül (10 Jeton) -> veli 🎁',
      ]);
      expect(second, hasLength(1));
      expect(second.single.senderName, 'Ali');
      expect(second.single.receiverName, 'veli');
    });
  });

  group('insights feed gate', () {
    test('first batch is not replayed', () {
      final gate = GlobalGiftFeedGate();
      const older = GiftFeedItem(
        id: 'g1',
        senderName: 'Admin',
        receiverName: 'ilhamperisi',
        giftName: 'Pembe çiçek',
        amount: 299,
      );
      expect(gate.takeNew([older]), isEmpty);

      const newer = GiftFeedItem(
        id: 'g2',
        senderName: 'Ali',
        receiverName: 'veli',
        giftName: 'Gül',
        amount: 10,
      );
      final fresh = gate.takeNew([newer, older]);
      expect(fresh.map((e) => e.id), ['g2']);
    });
  });

  group('global gift queue', () {
    test('same gift from two sources plays once', () {
      final queue = GlobalGiftQueue(
        settings: const GiftDisplaySettings(durationMs: 800, maxQueue: 3),
      );
      expect(
        queue.enqueue(GlobalGiftNotification.fromTicker(
          HomepageGiftTicker.tryParse(screenshot)!,
        )),
        isTrue,
      );
      expect(
        queue.enqueue(
          GlobalGiftNotification.fromFeedItem(
            const GiftFeedItem(
              id: 'feed-1',
              senderName: 'Admin',
              receiverName: 'ilhamperisi',
              giftName: '🌸 Pembe çiçek',
              amount: 299,
            ),
          ),
        ),
        isFalse,
      );
      queue.dispose();
    });
  });

  testWidgets('HomeTickerStrip hides gift-only ticker', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeTickerProvider.overrideWith((ref) async => [screenshot]),
        ],
        child: const MaterialApp(
          home: Scaffold(body: HomeTickerStrip()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Pembe çiçek'), findsNothing);
    expect(find.textContaining('ilhamperisi'), findsNothing);
  });

  testWidgets('HomeTickerStrip still shows non-gift news', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeTickerProvider.overrideWith(
            (ref) async => [screenshot, 'Yeni fal kampanyası'],
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: HomeTickerStrip()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Yeni fal kampanyası'), findsOneWidget);
    expect(find.textContaining('Pembe çiçek'), findsNothing);
  });
}
