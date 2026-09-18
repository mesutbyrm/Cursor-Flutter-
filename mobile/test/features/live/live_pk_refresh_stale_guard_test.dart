import 'package:canlifal_social/features/live/domain/pk/live_pk_refresh_stale_guard.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ürün kararı (2026-09-18): **süren bir maçta PK ekranı kalır.** Sunucudan
/// doğrulama gelmemesi "maç bitti" bilgisi değildir.
///
/// Önceki davranış: son doğrulamadan 90 sn sonra battle siliniyordu. Varsayılan
/// maç süresi 180 sn olduğu için 90 sn'yi aşan bir ağ sorunu maç hâlâ canlıyken
/// PK ekranını single-live moda düşürüyordu.
void main() {
  final now = DateTime.utc(2026, 9, 18, 12, 0, 0);

  Map<String, dynamic> battleAt({
    required String status,
    Duration? endsIn,
    bool dualStreams = false,
  }) {
    return {
      'id': 'pk-1',
      'status': status,
      if (endsIn != null) 'endsAt': now.add(endsIn).toIso8601String(),
      if (dualStreams) 'liveStreamId': 's-host',
      if (dualStreams) 'opponentLiveStreamId': 's-opp',
    };
  }

  group('süren maç korunur', () {
    test('aktif maç, bitişine daha var → korunur', () {
      expect(
        shouldRetainPkBattleOnEmptyRefresh(
          battle: battleAt(status: 'active', endsIn: const Duration(minutes: 2)),
          status: 'active',
          now: now,
        ),
        isTrue,
      );
    });

    // Eski davranışın düşürdüğü vaka: 90 sn'lik istemci sayacı dolmuştu ama
    // maç (180 sn) hâlâ sürüyordu. Artık ekran kalır.
    test('çift yayın kimliği yokken de aktif maç korunur', () {
      expect(
        shouldRetainPkBattleOnEmptyRefresh(
          battle: battleAt(status: 'active', endsIn: const Duration(seconds: 90)),
          status: 'active',
          now: now,
        ),
        isTrue,
        reason: 'doğrulama gelmemesi maçın bittiği anlamına gelmez',
      );
    });

    test('duraklatılmış maç korunur', () {
      expect(
        shouldRetainPkBattleOnEmptyRefresh(
          battle: battleAt(status: 'paused', endsIn: const Duration(minutes: 1)),
          status: 'paused',
          now: now,
        ),
        isTrue,
      );
    });

    test('bitiş zamanı bilinmiyorsa koruma tarafında kalınır', () {
      expect(
        shouldRetainPkBattleOnEmptyRefresh(
          battle: battleAt(status: 'active'),
          status: 'active',
          now: now,
        ),
        isTrue,
      );
    });

    test('bekleyen davet otorite zamanı olmadan korunur', () {
      expect(
        shouldRetainPkBattleOnEmptyRefresh(
          battle: const {'status': 'pending', 'id': 'pk-2'},
          status: 'pending',
          now: now,
        ),
        isTrue,
      );
    });

    test('çift yayınlı yayın aşaması korunur', () {
      expect(
        shouldRetainPkBattleOnEmptyRefresh(
          battle: battleAt(status: 'active', dualStreams: true),
          status: 'active',
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('ekran sonsuza kadar takılı kalmaz', () {
    // Tek çıkış maçın kendi bitiş zamanı — istemci sayacı değil, sunucudan
    // gelen (ya da startedAt + duration'dan türetilen) gerçek.
    test('bitiş zamanı + tolerans geçtiyse artık korunmaz', () {
      expect(
        shouldRetainPkBattleOnEmptyRefresh(
          battle: battleAt(status: 'active', endsIn: const Duration(minutes: -5)),
          status: 'active',
          now: now,
        ),
        isFalse,
      );
    });

    test('bitiş geçmiş ama tolerans içindeyse hâlâ korunur', () {
      expect(
        shouldRetainPkBattleOnEmptyRefresh(
          battle: battleAt(status: 'active', endsIn: const Duration(seconds: -30)),
          status: 'active',
          now: now,
        ),
        isTrue,
        reason: 'sunucunun bitişi doğrulaması için kısa bir pencere bırakılır',
      );
    });

    test('gerçekten bitmiş maç silinir', () {
      expect(
        shouldRetainPkBattleOnEmptyRefresh(
          battle: const {'status': 'completed', 'id': 'pk-3'},
          status: 'completed',
          now: now,
        ),
        isFalse,
      );
    });

    test('battle yoksa korunacak bir şey yok', () {
      expect(
        shouldRetainPkBattleOnEmptyRefresh(
          battle: null,
          status: 'active',
          now: now,
        ),
        isFalse,
      );
    });
  });

  // Tek bir geçici ağ hatası PK ekranını single-live moda düşürüyordu:
  // hata yolu ile "sunucu battle yok dedi" yolu aynı sonuca bağlanmıştı.
  // Hata bilgi yokluğudur; yalnızca sunucu açıkça bildirdiğinde silinir.
  group('pkRefreshErrorMeansBattleGone', () {
    test('404 ve 410 maçın gerçekten yok olduğunu bildirir', () {
      expect(pkRefreshErrorMeansBattleGone(404), isTrue);
      expect(pkRefreshErrorMeansBattleGone(410), isTrue);
    });

    test('ağ hatası (durum kodu yok) maçın bittiğinin kanıtı değildir', () {
      expect(pkRefreshErrorMeansBattleGone(null), isFalse);
    });

    test('sunucu hataları maçın bittiğinin kanıtı değildir', () {
      expect(pkRefreshErrorMeansBattleGone(500), isFalse);
      expect(pkRefreshErrorMeansBattleGone(502), isFalse);
      expect(pkRefreshErrorMeansBattleGone(503), isFalse);
      expect(pkRefreshErrorMeansBattleGone(504), isFalse);
    });

    test('yetki ve hız sınırı hataları maçın bittiğinin kanıtı değildir', () {
      expect(pkRefreshErrorMeansBattleGone(401), isFalse);
      expect(pkRefreshErrorMeansBattleGone(403), isFalse);
      expect(pkRefreshErrorMeansBattleGone(429), isFalse);
    });
  });
}
