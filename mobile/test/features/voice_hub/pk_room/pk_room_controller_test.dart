import 'dart:async';

import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/live/data/datasources/live_gifts_remote_datasource.dart';
import 'package:canlifal_social/features/live/domain/entities/live_gift_event.dart';
import 'package:canlifal_social/features/voice_hub/data/datasources/chat_room_gifts_remote_datasource.dart';
import 'package:canlifal_social/features/voice_hub/data/pk_room_api.dart';
import 'package:canlifal_social/features/voice_hub/data/services/voice_room_gift_realtime_service.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk_room/pk_gift_queue_core.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk_room/pk_room_match.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk_room/pk_server_clock.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk_room/pk_wire_event.dart';
import 'package:canlifal_social/features/voice_hub/presentation/pk_room/pk_room_controller.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/voice_gift_providers.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/voice_room_session_registry.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _room = 'room-1';
final _t0 = DateTime.utc(2026, 10, 1, 12, 0, 0);

class _FakeAuth extends AuthController {
  _FakeAuth(this._id);
  final String _id;
  @override
  Future<UserEntity?> build() async =>
      UserEntity(id: _id, username: _id, displayName: _id);
}

class _FakeApi implements PkRoomApi {
  Map<String, dynamic>? current;
  int fetchCount = 0;
  int endCount = 0;
  Object? endError;
  Completer<void>? endGate;

  /// `fetchCurrent` her çağrıda dönecek gövdeyi üretir (sunucu saatini taklit eder).
  Map<String, dynamic>? Function(int call)? onFetch;

  @override
  Future<Map<String, dynamic>?> fetchCurrent(
    String roomId, {
    String? alternateRoomId,
  }) async {
    fetchCount++;
    return onFetch != null ? onFetch!(fetchCount) : current;
  }

  @override
  Future<void> end(
    String roomId,
    String battleId, {
    String? alternateRoomId,
  }) async {
    endCount++;
    if (endGate != null) await endGate!.future;
    if (endError != null) throw endError!;
  }
}

Map<String, dynamic> _active({
  int score1 = 0,
  int score2 = 0,
  String endsAt = '2026-10-01T12:05:00.000Z',
  String serverNow = '2026-10-01T12:00:00.000Z',
  String status = 'active',
  List<Map<String, dynamic>>? participants,
}) => {
  'id': 'pk1',
  'status': status,
  'scope': 'room_user',
  'mode': '2v2',
  'stream1Id': _room,
  'stream2Id': _room,
  'user1Id': 'a',
  'user2Id': 'c',
  'duration': 300,
  'score1': score1,
  'score2': score2,
  'endsAt': endsAt,
  'serverNow': serverNow,
  'participants':
      participants ??
      [
        {'userId': 'a', 'side': 1, 'name': 'Ali', 'isCaptain': true},
        {'userId': 'b', 'side': 1, 'name': 'Bora'},
        {'userId': 'c', 'side': 2, 'name': 'Can', 'isCaptain': true},
        {'userId': 'd', 'side': 2, 'name': 'Deniz'},
      ],
};

final List<_Device> _live = [];

/// Her "cihaz": kendi (yanlış olabilen) saati + kendi konteyneri.
class _Device {
  _Device({required this.skew, required this.api, String userId = 'a'}) {
    now = _t0.add(skew);
    clock = PkServerClock(deviceNow: () => now);
    final dio = Dio();
    gifts = VoiceRoomGiftRealtimeService(
      ChatRoomGiftsRemoteDataSource(dio, LiveGiftsRemoteDataSource(dio)),
    );
    container = ProviderContainer(
      overrides: [
        pkServerClockProvider.overrideWithValue(clock),
        pkRoomApiProvider.overrideWithValue(api),
        authControllerProvider.overrideWith(() => _FakeAuth(userId)),
        voiceRoomGiftRealtimeProvider.overrideWithValue(gifts),
      ],
    );
    // Konteyneri canlı tut (autoDispose olmayan ama dinleyici garantisi).
    sub = container.listen(pkRoomControllerProvider(_room), (_, __) {});
    // Auth'u çöz.
    container.read(authControllerProvider);
    _live.add(this);
  }

  final Duration skew;
  final _FakeApi api;
  late DateTime now;
  late PkServerClock clock;
  late VoiceRoomGiftRealtimeService gifts;
  late ProviderContainer container;
  late ProviderSubscription<PkRoomState> sub;

  PkRoomController get ctl =>
      container.read(pkRoomControllerProvider(_room).notifier);
  PkRoomState get state => container.read(pkRoomControllerProvider(_room));
  int get remaining => ctl.remainingSeconds.value;

  /// Gerçek zamanı [d] ilerlet: cihaz saati + sahte zamanlayıcılar birlikte.
  Future<void> advance(WidgetTester tester, Duration d) async {
    now = now.add(d);
    await tester.pump(d);
  }

  void dispose() => container.dispose();
}

/// Cihaz testi: gövdeden sonra tüm cihazları sıfırla ve bekleyen zamanlayıcıları boşalt.
void deviceTest(String name, Future<void> Function(WidgetTester t) body) {
  testWidgets(name, (tester) async {
    await body(tester);
    for (final d in List<_Device>.of(_live)) {
      d.ctl.reset();
    }
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    _live.clear();
  });
}

/// Birden çok cihazın gerçek zamanını AYNI anda ilerletir.
Future<void> advanceAll(
  WidgetTester tester,
  List<_Device> devices,
  Duration d,
) async {
  for (final x in devices) {
    x.now = x.now.add(d);
  }
  await tester.pump(d);
}

void main() {
  deviceTest('İKİ CİHAZ, farklı cihaz saati: sayaç aynı değerde ilerler', (
    tester,
  ) async {
    final api = _FakeApi()..current = _active();
    final a = _Device(skew: const Duration(seconds: 7), api: api);
    final b = _Device(
      skew: const Duration(seconds: -12),
      api: api,
      userId: 'c',
    );
    addTearDown(a.dispose);
    addTearDown(b.dispose);

    await a.ctl.loadCurrent();
    await b.ctl.loadCurrent();
    await tester.pump();
    expect(a.remaining, 300);
    expect(b.remaining, 300);

    for (var i = 0; i < 40; i++) {
      await advanceAll(tester, [
        a,
        b,
      ], const Duration(seconds: 1)); // aynı gerçek zaman
    }
    await tester.pump();
    expect(a.remaining, 260);
    expect(b.remaining, 260);
    expect(a.remaining, b.remaining);
    a.ctl.reset();
    b.ctl.reset();
  });

  deviceTest(
    'hediye (PK_SCORE, status YOK): faz/süre bozulmaz, davet oluşmaz',
    (tester) async {
      final api = _FakeApi()..current = _active();
      final d = _Device(skew: Duration.zero, api: api);
      addTearDown(d.dispose);
      await d.ctl.loadCurrent();
      await d.advance(tester, const Duration(seconds: 10));
      expect(d.remaining, 290);
      final endsBefore = d.state.match!.endsAt;

      d.ctl.ingest(
        PkWireEvent.parse({
          'type': 'pk',
          'eventType': 'PK_SCORE',
          'action': 'score_update',
          'battleId': 'pk1',
          'room1Id': _room,
          'room2Id': _room,
          'score1': 500,
          'score2': 0,
          'addedAmount': 500,
          'receiverId': 'b',
        }),
      );
      await d.advance(tester, const Duration(seconds: 1));

      final m = d.state.match!;
      expect(m.phase, PkRoomPhase.active); // 'pending' (davet) olmadı
      expect(m.score1, 500);
      expect(m.score2, 0);
      expect(
        m.endsAt,
        endsBefore,
      ); // süre sıfırlanmadı (eski hata: 300 sn'ye dönüyordu)
      expect(m.members.firstWhere((e) => e.userId == 'b').points, 500);
      expect(d.remaining, 289); // sayaç kesintisiz devam etti
      expect(d.state.overlayVisible, isTrue);
      d.ctl.reset();
    },
  );

  deviceTest(
    'sayaç: skor/hediye/state olayları sırasında durmaz, geri sarmaz',
    (tester) async {
      final api = _FakeApi()..current = _active();
      final d = _Device(skew: Duration.zero, api: api);
      addTearDown(d.dispose);
      await d.ctl.loadCurrent();
      var last = d.remaining;
      for (var i = 0; i < 30; i++) {
        d.ctl.ingest(
          PkWireEvent.parse({
            'eventType': 'PK_SCORE',
            'battleId': 'pk1',
            'room1Id': _room,
            'room2Id': _room,
            'score1': i * 10,
            'score2': 0,
          }),
        );
        // Aynı maçın tam durum olayı (endsAt aynı) — sayacı sıfırlamamalı.
        d.ctl.ingest(
          PkWireEvent.parse({
            ..._active(score1: i * 10),
            'eventType': 'PK_STATE',
            'battleId': 'pk1',
          }),
        );
        await d.advance(tester, const Duration(seconds: 1));
        expect(d.remaining, lessThanOrEqualTo(last));
        last = d.remaining;
      }
      expect(d.remaining, 270);
      d.ctl.reset();
    },
  );

  deviceTest(
    '00:00 → finishing → sunucu bitirir → normal oda; iki cihaz aynı',
    (tester) async {
      final api = _FakeApi()
        ..current = _active(endsAt: '2026-10-01T12:00:03.000Z');
      final a = _Device(skew: const Duration(seconds: 4), api: api);
      final b = _Device(
        skew: const Duration(seconds: -9),
        api: api,
        userId: 'c',
      );
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      await a.ctl.loadCurrent();
      await b.ctl.loadCurrent();
      expect(a.remaining, 3);

      // Süre dolunca sunucu (GET) maçı bitmiş döndürür.
      api.onFetch = (_) => {
        ..._active(
          endsAt: '2026-10-01T12:00:03.000Z',
          score1: 312,
          status: 'completed',
        ),
        'winnerSide': 1,
      };
      for (var i = 0; i < 4; i++) {
        await advanceAll(tester, [a, b], const Duration(seconds: 1));
      }
      await tester.pump();
      for (final d in [a, b]) {
        expect(d.state.match!.phase, PkRoomPhase.finished);
        expect(d.state.overlayVisible, isFalse);
        expect(d.remaining, 0);
      }
      // Sonuç bildirimi iki cihazda aynı.
      expect(a.state.result!.score1, 312);
      expect(b.state.result!.winnerSide, 1);
      a.ctl.reset();
      b.ctl.reset();
    },
  );

  deviceTest(
    'sunucu PK_ENDED göndermese de ekran takılı kalmaz (zaman aşımı koruması)',
    (tester) async {
      final api = _FakeApi()
        ..current = _active(endsAt: '2026-10-01T12:00:02.000Z');
      final d = _Device(skew: Duration.zero, api: api);
      addTearDown(d.dispose);
      await d.ctl.loadCurrent();
      // Sunucu hep "active" döner (kapatmıyor).
      for (var i = 0; i < 20; i++) {
        await d.advance(tester, const Duration(seconds: 1));
        await tester.pump();
      }
      expect(d.state.match!.phase, PkRoomPhase.finished);
      expect(d.state.overlayVisible, isFalse);
      d.ctl.reset();
    },
  );

  deviceTest(
    '"PK Bitir": arayüz ANINDA normal odaya döner (API cevabı beklenmez)',
    (tester) async {
      final api = _FakeApi()
        ..current = _active()
        ..endGate = Completer<void>();
      final d = _Device(skew: Duration.zero, api: api);
      addTearDown(d.dispose);
      await d.ctl.loadCurrent();
      expect(d.state.overlayVisible, isTrue);

      final f = d.ctl.endNow();
      await tester.pump(); // API hâlâ bekliyor
      expect(d.state.overlayVisible, isFalse); // anında kalktı
      expect(d.state.ending, isTrue);
      expect(d.remaining, 0); // sayaç durdu

      // Geç gelen "active" olayı PK'yı diriltmez.
      d.ctl.ingest(
        PkWireEvent.parse({
          ..._active(),
          'eventType': 'PK_STATE',
          'battleId': 'pk1',
        }),
      );
      expect(d.state.overlayVisible, isFalse);

      api.endGate!.complete();
      await f;
      expect(api.endCount, 1);
      expect(d.state.ending, isFalse);
      expect(d.state.overlayVisible, isFalse);
      d.ctl.reset();
    },
  );

  deviceTest('"PK Bitir" başarısız (403) → PK geri gelir ve hata bildirilir', (
    tester,
  ) async {
    final api = _FakeApi()
      ..current = _active()
      ..endError = const ApiException('Yetkiniz yok', statusCode: 403);
    final d = _Device(skew: Duration.zero, api: api);
    addTearDown(d.dispose);
    await d.ctl.loadCurrent();
    await d.ctl.endNow();
    expect(d.state.overlayVisible, isTrue);
    expect(d.state.error, 'Yetkiniz yok');
    expect(d.state.ending, isFalse);
    d.ctl.reset();
  });

  deviceTest('"PK Bitir" 409 (zaten bitmiş) hata sayılmaz', (tester) async {
    final api = _FakeApi()
      ..current = _active()
      ..endError = const ApiException('PK zaten bitmiş', statusCode: 409);
    final d = _Device(skew: Duration.zero, api: api);
    addTearDown(d.dispose);
    await d.ctl.loadCurrent();
    await d.ctl.endNow();
    expect(d.state.overlayVisible, isFalse);
    expect(d.state.error, isNull);
    d.ctl.reset();
  });

  deviceTest(
    'PK bitince normal oda geri gelir; sonraki hediye PK yeniden AÇMAZ',
    (tester) async {
      final api = _FakeApi()..current = _active();
      final d = _Device(skew: Duration.zero, api: api);
      addTearDown(d.dispose);
      await d.ctl.loadCurrent();
      d.ctl.ingest(
        PkWireEvent.parse({
          'eventType': 'PK_ENDED',
          'battleId': 'pk1',
          'status': 'completed',
          'room1Id': _room,
          'room2Id': _room,
          'score1': 10,
          'score2': 3,
          'winnerSide': 1,
        }),
      );
      expect(d.state.overlayVisible, isFalse);

      // Bitişten sonra hediye puanı (gecikmeli) PK'yı canlandırmaz.
      d.ctl.ingest(
        PkWireEvent.parse({
          'eventType': 'PK_SCORE',
          'battleId': 'pk1',
          'room1Id': _room,
          'room2Id': _room,
          'score1': 510,
          'score2': 3,
        }),
      );
      expect(d.state.overlayVisible, isFalse);
      expect(d.state.match!.score1, 10);
      d.ctl.reset();
    },
  );

  deviceTest(
    'SSE yeniden bağlanınca sunucudan güncel PK alınır, sayaç sıfırlanmaz',
    (tester) async {
      final api = _FakeApi()..current = _active();
      final d = _Device(skew: Duration.zero, api: api);
      addTearDown(d.dispose);
      await d.ctl.loadCurrent();
      await d.advance(tester, const Duration(seconds: 100));
      expect(d.remaining, 200);

      // Bağlantı koptu: olaylar kaçtı. Sunucuda skor değişti, endsAt aynı.
      api.current = _active(
        score1: 900,
        score2: 40,
        serverNow: '2026-10-01T12:01:40.000Z',
      );
      final before = api.fetchCount;
      d.container.read(voiceRoomActiveSseConnectedProvider.notifier).state =
          false;
      d.container.read(voiceRoomActiveSseConnectedProvider.notifier).state =
          true;
      await tester.pump();
      await tester.pump();
      expect(api.fetchCount, greaterThan(before));
      expect(d.state.match!.score1, 900);
      expect(d.remaining, 200); // kalan süre sunucu endsAt'ından devam etti
      d.ctl.reset();
    },
  );

  deviceTest(
    'yerel susturma: yalnızca karşı takım, yalnızca PK açıkken, yalnızca bu cihazda',
    (tester) async {
      final api = _FakeApi()..current = _active();
      final d = _Device(skew: Duration.zero, api: api, userId: 'a'); // Takım 1
      addTearDown(d.dispose);
      await d.ctl.loadCurrent();

      Set<String> targets() =>
          d.container.read(pkLocalMuteTargetsProvider(_room));
      // Auth'un çözülmesi için bir kare.
      await tester.pump();
      expect(targets(), isEmpty); // varsayılan: kimse susturulmaz

      d.ctl.setMuteOpposing(true);
      await tester.pump();
      expect(targets(), {'c', 'd'}); // sadece Takım 2
      expect(targets().contains('b'), isFalse); // kendi takımım duyulur
      expect(d.state.match!.members.length, 4); // backend/üyeler değişmedi

      d.ctl.setMuteOpposing(false);
      await tester.pump();
      expect(targets(), isEmpty); // tekrar açılınca duyulur

      d.ctl.setMuteOpposing(true);
      d.ctl.ingest(
        PkWireEvent.parse({
          'eventType': 'PK_ENDED',
          'battleId': 'pk1',
          'status': 'completed',
          'room1Id': _room,
          'room2Id': _room,
        }),
      );
      await tester.pump();
      expect(targets(), isEmpty); // PK bitince yerel susturma kalkar
      expect(d.state.muteOpposing, isFalse);
      d.ctl.reset();
    },
  );

  deviceTest('izleyici (PK oyuncusu değil) için yerel susturma hedefi yok', (
    tester,
  ) async {
    final api = _FakeApi()..current = _active();
    final d = _Device(skew: Duration.zero, api: api, userId: 'viewer');
    addTearDown(d.dispose);
    await d.ctl.loadCurrent();
    d.ctl.setMuteOpposing(true);
    await tester.pump();
    expect(d.container.read(pkLocalMuteTargetsProvider(_room)), isEmpty);
    d.ctl.reset();
  });

  deviceTest('PK_STARTING → geri sayım; PK_STARTED → aktif (davet değil)', (
    tester,
  ) async {
    final api = _FakeApi();
    final d = _Device(skew: Duration.zero, api: api);
    addTearDown(d.dispose);
    d.clock.observe(_t0);
    d.ctl.ingest(
      PkWireEvent.parse({
        'eventType': 'PK_STARTING',
        'battleId': 'pk1',
        'room1Id': _room,
        'room2Id': _room,
        'scope': 'room_user',
        'mode': '1v1',
        'duration': 180,
        'countdownSec': 5,
        'participants': [
          {'userId': 'a', 'side': 1, 'name': 'Ali', 'isCaptain': true},
          {'userId': 'c', 'side': 2, 'name': 'Can', 'isCaptain': true},
        ],
        'serverNow': '2026-10-01T12:00:00.000Z',
      }),
    );
    expect(d.state.match!.phase, PkRoomPhase.starting);
    expect(d.state.overlayVisible, isTrue);
    expect(d.remaining, 5);
    await d.advance(tester, const Duration(seconds: 2));
    expect(d.remaining, 3);

    d.ctl.ingest(
      PkWireEvent.parse({
        'eventType': 'PK_STARTED',
        'battleId': 'pk1',
        'room1Id': _room,
        'room2Id': _room,
        'status': 'active',
        'endsAt': '2026-10-01T12:03:05.000Z',
        'serverNow': '2026-10-01T12:00:05.000Z',
      }),
    );
    expect(d.state.match!.phase, PkRoomPhase.active);
    expect(d.state.match!.members.length, 2); // üyeler korundu
    expect(d.remaining, 180);
    d.ctl.reset();
  });

  deviceTest('başka odanın / oda-vs-oda PK olayı oda içi kontrolcüye girmez', (
    tester,
  ) async {
    final api = _FakeApi();
    final d = _Device(skew: Duration.zero, api: api);
    addTearDown(d.dispose);
    d.ctl.ingest(
      PkWireEvent.parse({
        'eventType': 'PK_STARTED',
        'battleId': 'x',
        'room1Id': 'oda-a',
        'room2Id': 'oda-b', // iki farklı oda → oda içi PK değil
        'status': 'active',
      }),
    );
    expect(d.state.match, isNull);
    d.ctl.ingest(
      PkWireEvent.parse({
        'eventType': 'PK_REQUEST',
        'battleId': 'y',
        'room1Id': _room,
        'room2Id': _room,
        'status': 'pending',
      }),
    );
    expect(d.state.match, isNull); // davet olayı PK ekranı açmaz
  });

  group('PkGiftToastController (son 3 hediye, ~5 sn, sırayla fade-out)', () {
    PkGiftToast g(int i) => PkGiftToast(
      id: 'g$i',
      senderName: 'Kişi$i',
      giftName: 'Kalp',
      amount: 100 * i,
    );

    testWidgets('5 hediye → 3 kart, her biri ~5 sn, sırayla', (tester) async {
      final c = PkGiftToastController();
      for (var i = 1; i <= 5; i++) {
        c.add(g(i));
      }
      expect(c.current.value!.id, 'g1');

      await tester.pump(const Duration(milliseconds: 4900));
      expect(c.current.value!.id, 'g1'); // hâlâ görünür (≈5 sn)
      await tester.pump(const Duration(milliseconds: 200));
      expect(c.current.value, isNull); // fade-out aralığı
      await tester.pump(pkGiftToastGap);
      expect(c.current.value!.id, 'g4'); // en eski bekleyen (g2,g3) düştü
      await tester.pump(pkGiftToastVisible);
      expect(c.current.value, isNull);
      await tester.pump(pkGiftToastGap);
      expect(c.current.value!.id, 'g5');
      await tester.pump(pkGiftToastVisible + pkGiftToastGap);
      expect(c.current.value, isNull); // kuyruk boşaldı
      c.dispose();
    });

    testWidgets('kart yokken gelen hediye hemen görünür', (tester) async {
      final c = PkGiftToastController();
      c.add(g(1));
      await tester.pump(pkGiftToastVisible + pkGiftToastGap);
      expect(c.current.value, isNull);
      c.add(g(2));
      expect(c.current.value!.id, 'g2');
      c.dispose();
    });
  });

  deviceTest(
    'PK sırasında gelen hediye kartı gönderen/hediye/tutar ile görünür; PK sayacı sürer',
    (tester) async {
      final api = _FakeApi()..current = _active();
      final d = _Device(skew: Duration.zero, api: api);
      addTearDown(d.dispose);
      await d.ctl.loadCurrent();

      d.gifts.publishRemote(
        LiveGiftEvent(
          id: 'gift-1',
          senderName: 'İlham Perisi',
          receiverName: 'Bora',
          receiverId: 'b',
          giftId: 'heart',
          giftName: 'Kalp Hediyesi',
          quantity: 1,
          coinCost: 500,
          totalCoin: 500,
          timestamp: DateTime.now(),
        ),
      );
      await tester.pump();
      final toast = d.ctl.gifts.current.value!;
      expect(toast.senderName, 'İlham Perisi');
      expect(toast.giftName, 'Kalp Hediyesi');
      expect(toast.amount, 500);
      expect(toast.side, 1); // alıcı (Bora) Takım 1'de

      final before = d.remaining;
      await d.advance(tester, const Duration(seconds: 3));
      expect(d.remaining, before - 3); // hediye animasyonu sayacı durdurmaz
      d.ctl.reset();
    },
  );

  deviceTest(
    'hediye, PK bitince kart göstermez (normal hediye sistemi bağımsız)',
    (tester) async {
      final api = _FakeApi()..current = _active();
      final d = _Device(skew: Duration.zero, api: api);
      addTearDown(d.dispose);
      await d.ctl.loadCurrent();
      d.ctl.ingest(
        PkWireEvent.parse({
          'eventType': 'PK_ENDED',
          'battleId': 'pk1',
          'status': 'completed',
          'room1Id': _room,
          'room2Id': _room,
        }),
      );
      d.gifts.publishRemote(
        LiveGiftEvent(
          id: 'gift-2',
          senderName: 'Biri',
          receiverName: 'Bora',
          giftId: 'heart',
          giftName: 'Kalp',
          quantity: 1,
          coinCost: 100,
          timestamp: DateTime.now(),
        ),
      );
      await tester.pump();
      expect(d.ctl.gifts.current.value, isNull);
      expect(d.state.overlayVisible, isFalse);
    },
  );
}
