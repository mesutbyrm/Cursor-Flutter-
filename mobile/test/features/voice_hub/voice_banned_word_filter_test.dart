import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/domain/utils/voice_banned_word_filter.dart';

void main() {
  const banned = ['am'];

  group('VoiceBannedWordFilter — tam kelime (Faz 5)', () {
    test('engeller: am, AM, Am (tek başına)', () {
      expect(VoiceBannedWordFilter.containsBannedWord('am', banned), isTrue);
      expect(VoiceBannedWordFilter.containsBannedWord('AM', banned), isTrue);
      expect(VoiceBannedWordFilter.containsBannedWord('Am', banned), isTrue);
    });

    test('engellemez: Ama, ama, amca, aman (içinde geçse bile tam kelime değil)', () {
      expect(VoiceBannedWordFilter.containsBannedWord('Ama', banned), isFalse);
      expect(VoiceBannedWordFilter.containsBannedWord('ama', banned), isFalse);
      expect(VoiceBannedWordFilter.containsBannedWord('amca', banned), isFalse);
      expect(VoiceBannedWordFilter.containsBannedWord('aman', banned), isFalse);
    });

    test('cümle içinde tam kelime olarak geçerse engeller', () {
      expect(
        VoiceBannedWordFilter.containsBannedWord('Merhaba am!', banned),
        isTrue,
      );
      expect(
        VoiceBannedWordFilter.containsBannedWord('x am y', banned),
        isTrue,
      );
    });

    test('boş liste veya kısa kelime eşleşmez', () {
      expect(
        VoiceBannedWordFilter.containsBannedWord('am', const []),
        isFalse,
      );
      expect(
        VoiceBannedWordFilter.containsBannedWord('test', ['a']),
        isFalse,
      );
    });
  });
}
