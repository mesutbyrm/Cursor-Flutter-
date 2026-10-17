import 'package:canlifal_social/features/voice_hub/girlive/girlive_bot_avatar.dart';
import 'package:canlifal_social/features/voice_hub/girlive/girlive_bot_guard.dart';
import 'package:canlifal_social/features/voice_hub/girlive/girlive_word_bank.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GirLiveWordBank', () {
    final bank = GirLiveWordBank.instance;

    test('yerleşik listedeki kelime yakalanır (büyük harf / tekrar / ı-i)', () {
      expect(bank.containsBanned('siktir git'), isTrue);
      expect(bank.containsBanned('SİKTİR git'), isTrue);
      expect(bank.containsBanned('siiiktir'), isTrue);
      expect(bank.containsBanned('amcik'), isTrue);
    });

    test('ekli hâller 4+ harfli kelimede yakalanır', () {
      expect(bank.containsBanned('orospusu'), isTrue);
    });

    test('yaygın masum ifadeler yakalanmaz', () {
      expect(bank.containsBanned('sık sık görüşelim'), isFalse);
      expect(bank.containsBanned('şikayet ediyorum'), isFalse);
      expect(bank.containsBanned('merhaba nasılsınız'), isFalse);
    });

    test('liste ayrıştırma: boş / yorum / fazla uzun satırlar atılır', () {
      final out = GirLiveWordBank.parseList(
        '# başlık\n\nkelime1\nkelime2\r\nkelime1\n${'x' * 60}\n',
      );
      expect(out, ['kelime1', 'kelime2']);
    });
  });

  group('GirLiveBotGuard', () {
    test('uyarı → uyarı → susturma, süre dolunca serbest', () {
      final guard = GirLiveBotGuard();
      final t0 = DateTime(2026, 10, 17, 12);

      final v1 = guard.evaluate(roomKey: 'r', text: 'siktir', now: t0);
      expect(v1.allowed, isFalse);
      expect(v1.muted, isFalse);
      expect(v1.notice, contains('1/3'));

      final v2 = guard.evaluate(
        roomKey: 'r',
        text: 'siktir',
        now: t0.add(const Duration(minutes: 1)),
      );
      expect(v2.notice, contains('2/3'));

      final v3 = guard.evaluate(
        roomKey: 'r',
        text: 'siktir',
        now: t0.add(const Duration(minutes: 2)),
      );
      expect(v3.muted, isTrue);

      // Susturuluyken temiz mesaj bile gitmez.
      final blocked = guard.evaluate(
        roomKey: 'r',
        text: 'merhaba',
        now: t0.add(const Duration(minutes: 3)),
      );
      expect(blocked.allowed, isFalse);
      expect(blocked.muted, isTrue);

      // 5 dk sonra serbest.
      final free = guard.evaluate(
        roomKey: 'r',
        text: 'merhaba',
        now: t0.add(const Duration(minutes: 8)),
      );
      expect(free.allowed, isTrue);
    });

    test('odanın kendi kelimesi tam kelime olarak engellenir', () {
      final guard = GirLiveBotGuard();
      expect(
        guard.evaluate(roomKey: 'r', text: 'x deneme y', roomWords: ['deneme'])
            .allowed,
        isFalse,
      );
      expect(
        guard.evaluate(roomKey: 'r2', text: 'denemeler', roomWords: ['deneme'])
            .allowed,
        isTrue,
      );
    });

    test('ihlaller odalar arasında karışmaz', () {
      final guard = GirLiveBotGuard();
      final t = DateTime(2026, 10, 17, 12);
      guard.evaluate(roomKey: 'a', text: 'siktir', now: t);
      final v = guard.evaluate(roomKey: 'b', text: 'siktir', now: t);
      expect(v.notice, contains('1/3'));
    });
  });

  group('GirLiveBotAvatar.isBot', () {
    test('yalnızca birebir bot kimliği / adı', () {
      expect(GirLiveBotAvatar.isBot(name: 'GirLive Bot'), isTrue);
      expect(GirLiveBotAvatar.isBot(userId: 'girlive-bot'), isTrue);
      expect(GirLiveBotAvatar.isBot(userId: 'girlive_bot'), isTrue);
      expect(GirLiveBotAvatar.isBot(name: 'girlivehayran'), isFalse);
      expect(GirLiveBotAvatar.isBot(name: 'Ayşe'), isFalse);
    });
  });
}
