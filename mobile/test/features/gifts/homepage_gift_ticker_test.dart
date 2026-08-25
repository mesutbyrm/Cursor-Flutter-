import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/gifts/domain/gift_display_settings.dart';
import 'package:canlifal_social/features/gifts/domain/gift_feed_item.dart';
import 'package:canlifal_social/features/gifts/domain/homepage_gift_ticker.dart';
import 'package:canlifal_social/features/gifts/presentation/global/global_gift_notification.dart';
import 'package:canlifal_social/features/gifts/presentation/global/global_gift_queue.dart';
import 'package:canlifal_social/features/home/data/homepage_ticker_parser.dart';
import 'package:canlifal_social/features/home/presentation/providers/home_providers.dart';
import 'package:canlifal_social/features/home/presentation/widgets/home_ticker_strip.dart';
import 'package:canlifal_social/features/voice_hub/domain/voice_official_join.dart';

void main() {
  const screenshot =
      '🎁 Admin -> 🌸 Pembe çiçek (299 Jeton) -> ilhamperisi 🎁';

  group('homepage gift ticker detect/parse', () {
    test('promo copy is not a live gift announcement', () {
      expect(
        VoiceOfficialJoin.isHomeBannerGiftAnnouncement(
          '🎁 Jeton alarak hediye atabilirsiniz...',
        ),
        isFalse,
      );
      expect(
        VoiceOfficialJoin.isHomeBannerGiftAnnouncement(
          '☕ Fal bakarak eğlenebilirsiniz...',
        ),
        isFalse,
      );
    });

    test('screenshot ticker format is a gift announcement', () {
      expect(VoiceOfficialJoin.isHomeBannerGiftAnnouncement(screenshot), isTrue);
      expect(HomepageGiftTicker.isGiftLine(screenshot), isTrue);
    });

    test('parses unicode arrows', () {
      const line =
          '🎁 Admin → 🌸 Pembe çiçek (299 Jeton) → ilhamperisi';
      final parsed = HomepageGiftTicker.tryParse(line);
      expect(parsed?.senderName, 'Admin');
      expect(parsed?.receiverName, 'ilhamperisi');
      expect(parsed?.amount, 299);
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

  group('homepage ticker parser', () {
    test('reads production customMessages', () {
      final lines = HomepageTickerParser.linesFromBody({
        'onlineUsers': [],
        'customMessages': [
          {'id': '1', 'text': 'Jeton alarak hediye atabilirsiniz...', 'icon': '🎁'},
          {'id': '2', 'text': 'Fal bakarak eğlenebilirsiniz...', 'icon': '☕'},
        ],
      });
      expect(lines, [
        '🎁 Jeton alarak hediye atabilirsiniz...',
        '☕ Fal bakarak eğlenebilirsiniz...',
      ]);
      expect(
        HomepageGiftTicker.newsLines(lines),
        lines,
      );
    });
  });

  group('recent-big map', () {
    test('nested sender/gift objects become overlay label', () {
      final n = GlobalGiftNotification.fromMap({
        'id': 'rb1',
        'sender': {'name': 'Admin'},
        'receiver': {'name': 'ilhamperisi'},
        'gift': {'name': 'Pembe çiçek', 'icon': '🌸', 'price': 299},
      });
      expect(n.senderName, 'Admin');
      expect(n.receiverName, 'ilhamperisi');
      expect(n.giftName, 'Pembe çiçek');
      expect(n.amount, 299);
      expect(n.label(const GiftDisplaySettings()), contains('Admin'));
      expect(n.label(const GiftDisplaySettings()), contains('ilhamperisi'));
    });

    test('id gate seeds first poll', () {
      final gate = GlobalGiftIdGate();
      final first = [
        GlobalGiftNotification(
          eventId: 'a',
          senderName: 'A',
          giftName: 'G',
        ),
      ];
      expect(gate.takeNew(first, (n) => n.eventId), isEmpty);
      final second = [
        ...first,
        GlobalGiftNotification(
          eventId: 'b',
          senderName: 'B',
          giftName: 'G2',
        ),
      ];
      expect(
        gate.takeNew(second, (n) => n.eventId).map((n) => n.eventId),
        ['b'],
      );
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
