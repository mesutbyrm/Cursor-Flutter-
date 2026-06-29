import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/fortune/domain/fortune_zodiac.dart';

void main() {
  group('FortuneZodiac', () {
    test('Koç — mart sonu', () {
      expect(
        FortuneZodiac.fromBirthDate(DateTime(2000, 3, 25)).sign,
        'Koç',
      );
    });

    test('Yengeç — temmuz başı', () {
      expect(
        FortuneZodiac.fromBirthDate(DateTime(1998, 7, 5)).sign,
        'Yengeç',
      );
    });

    test('Oğlak — yılbaşı', () {
      expect(
        FortuneZodiac.fromBirthDate(DateTime(1990, 1, 5)).sign,
        'Oğlak',
      );
    });

    test('Balık — şubat sonu', () {
      expect(
        FortuneZodiac.fromBirthDate(DateTime(1992, 2, 28)).sign,
        'Balık',
      );
    });
  });
}
