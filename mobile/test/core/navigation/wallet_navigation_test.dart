import 'package:canlifal_social/core/navigation/wallet_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isInsufficientJetonMessage', () {
    test('detects Turkish jeton errors', () {
      expect(isInsufficientJetonMessage('Yetersiz jeton. Gerekli: 10'), isTrue);
      expect(isInsufficientJetonMessage('10 jeton gerekli'), isTrue);
    });

    test('ignores unrelated errors', () {
      expect(isInsufficientJetonMessage('Kick yetkiniz yok'), isFalse);
      expect(isInsufficientJetonMessage('Bağlantı hatası'), isFalse);
    });
  });
}
