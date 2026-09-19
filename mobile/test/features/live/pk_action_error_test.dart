import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/features/live/domain/pk/pk_action_error.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cihazda görülen hata: süre 0'a indiğinde sunucu maçı kendisi bitiriyor.
/// Kullanıcı bu sırada "PK'yi Bitir"e basınca sunucu `400 — PK zaten bitmiş`
/// dönüyor ve ekranda ham metin beliriyordu:
///
///     ApiException(400): PK zaten bitmiş
///
/// İstenen sonuç (maç bitti) zaten sağlandığı için bu bir hata değil.
void main() {
  group('sunucu istenen sonucu zaten uygulamış', () {
    test('cihazda görülen tam mesaj tanınır', () {
      expect(
        pkActionErrorMeansAlreadySettled(
          const ApiException('PK zaten bitmiş', statusCode: 400),
        ),
        isTrue,
      );
    });

    test('düz metin olarak da tanınır', () {
      expect(pkActionErrorMeansAlreadySettled('PK zaten bitmiş'), isTrue);
      expect(pkActionErrorMeansAlreadySettled('Bu PK zaten bitti'), isTrue);
      expect(pkActionErrorMeansAlreadySettled('PK zaten iptal edildi'), isTrue);
    });

    test('mevcut "durumu değişti" davranışı korunur', () {
      expect(
        pkActionErrorMeansAlreadySettled('PK durumu değişti, yenileniyor'),
        isTrue,
      );
    });

    test('İngilizce karşılıkları da tanınır', () {
      expect(pkActionErrorMeansAlreadySettled('Battle already ended'), isTrue);
      expect(pkActionErrorMeansAlreadySettled('ALREADY FINISHED'), isTrue);
    });
  });

  group('gerçek hatalar yutulmaz', () {
    test('yetki hatası hata olarak kalır', () {
      expect(
        pkActionErrorMeansAlreadySettled(
          const ApiException('Bu işlem için yetkiniz yok', statusCode: 403),
        ),
        isFalse,
      );
    });

    test('bağlantı hatası hata olarak kalır', () {
      expect(
        pkActionErrorMeansAlreadySettled(
          const ApiException('Bağlantı kurulamadı'),
        ),
        isFalse,
      );
    });

    test('PK bulunamadı hata olarak kalır', () {
      expect(
        pkActionErrorMeansAlreadySettled(
          const ApiException('PK bulunamadı', statusCode: 404),
        ),
        isFalse,
      );
    });

    test('null güvenli', () {
      expect(pkActionErrorMeansAlreadySettled(null), isFalse);
    });
  });

  // Snackbar doğrudan state.error'ı basıyor; oraya ham toString girerse
  // kullanıcı "ApiException(400): ..." görüyor.
  group('kullanıcıya gösterilecek metin ham değil', () {
    test('userMessage ApiException önekini taşımaz', () {
      const err = ApiException('PK zaten bitmiş', statusCode: 400);
      expect(err.toString(), contains('ApiException'));
      expect(ApiException.userMessage(err), 'PK zaten bitmiş');
      expect(ApiException.userMessage(err), isNot(contains('ApiException')));
    });
  });
}
