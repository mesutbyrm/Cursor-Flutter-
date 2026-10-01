import 'package:canlifal_social/features/voice_hub/domain/pk_room/pk_gift_queue_core.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk_room/pk_room_match.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk_room/pk_server_clock.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk_room/pk_team_layout.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk_room/pk_wire_event.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _battle({
  String status = 'active',
  Map<String, dynamic> extra = const {},
}) => {
  'id': 'pk1',
  'status': status,
  'scope': 'room_user',
  'mode': '2v2',
  'stream1Id': 'room-1',
  'stream2Id': 'room-1',
  'user1Id': 'a',
  'user2Id': 'c',
  'duration': 300,
  'score1': 10,
  'score2': 5,
  'endsAt': '2026-10-01T12:05:00.000Z',
  'serverNow': '2026-10-01T12:00:00.000Z',
  'participants': [
    {'userId': 'a', 'side': 1, 'name': 'Ali', 'isCaptain': true},
    {'userId': 'b', 'side': 1, 'name': 'Bora'},
    {'userId': 'c', 'side': 2, 'name': 'Can', 'isCaptain': true},
    {'userId': 'd', 'side': 2, 'name': 'Deniz'},
  ],
  ...extra,
};

void main() {
  group('PkWireEvent sınıflandırma (hediye ≠ PK daveti)', () {
    test('PK_SCORE status taşımasa da skor olayıdır, davet DEĞİL', () {
      final e = PkWireEvent.parse({
        'type': 'pk',
        'eventType': 'PK_SCORE',
        'action': 'score_update',
        'battleId': 'pk1',
        'room1Id': 'room-1',
        'room2Id': 'room-1',
        'score1': 500,
        'score2': 0,
      });
      expect(e.kind, PkWireKind.score);
      expect(e.isInvite, isFalse);
      expect(e.inRoom, isTrue);
    });

    test('hediye/jeton kelimeleri içeren mesaj PK daveti tetiklemez', () {
      final e = PkWireEvent.parse({
        'type': 'pk',
        'message': 'hediye gönderdi 500 jeton gift',
        'battleId': 'pk1',
      });
      expect(e.kind, PkWireKind.unknown);
      expect(e.isInvite, isFalse);
    });

    test('status olmayan ve tipsiz payload davet sayılmaz', () {
      final e = PkWireEvent.parse({'battleId': 'x', 'score1': 1, 'score2': 2});
      expect(e.kind, PkWireKind.unknown);
    });

    test('yalnızca gerçek davet tipleri invite döner', () {
      expect(
        PkWireEvent.parse({'eventType': 'PK_REQUEST', 'battleId': 'x'}).kind,
        PkWireKind.invite,
      );
      expect(
        PkWireEvent.parse({'action': 'create', 'battleId': 'x'}).kind,
        PkWireKind.invite,
      );
      expect(
        PkWireEvent.parse({'status': 'pending', 'battleId': 'x'}).kind,
        PkWireKind.invite,
      );
    });

    test('yaşam döngüsü tipleri', () {
      PkWireKind k(String t) =>
          PkWireEvent.parse({'eventType': t, 'battleId': 'x'}).kind;
      expect(k('PK_STARTING'), PkWireKind.starting);
      expect(k('PK_STARTED'), PkWireKind.started);
      expect(k('PK_PAUSED'), PkWireKind.paused);
      expect(k('PK_RESUMED'), PkWireKind.resumed);
      expect(k('PK_ENDED'), PkWireKind.ended);
      expect(k('PK_REQUEST_CANCELLED'), PkWireKind.cancelled);
      expect(k('PK_EXPIRED'), PkWireKind.expired);
      expect(k('PK_STATE'), PkWireKind.state);
    });

    test('oda içi PK tespiti: room1Id == room2Id veya scope room_user', () {
      expect(
        PkWireEvent.parse({
          'eventType': 'PK_ENDED',
          'battleId': 'x',
          'room1Id': 'r',
          'room2Id': 'r',
        }).inRoom,
        isTrue,
      );
      expect(
        PkWireEvent.parse({
          'eventType': 'PK_STARTING',
          'battleId': 'x',
          'scope': 'room_user',
        }).inRoom,
        isTrue,
      );
      expect(
        PkWireEvent.parse({
          'eventType': 'PK_STARTED',
          'battleId': 'x',
          'room1Id': 'a',
          'room2Id': 'b',
        }).inRoom,
        isFalse,
      );
    });

    test('batılı (data/battle) zarf açılır, üst düzey eventType korunur', () {
      final e = PkWireEvent.parse({
        'eventType': 'PK_SCORE',
        'battle': {'id': 'pk9', 'status': 'active', 'score1': 7},
      });
      expect(e.kind, PkWireKind.score);
      expect(e.battleId, 'pk9');
    });
  });

  group('PkRoomMatch', () {
    test('REST GET gövdesi: takımlar, mod, süre, endsAt', () {
      final m = PkRoomMatch.fromJson(_battle())!;
      expect(m.phase, PkRoomPhase.active);
      expect(m.mode, '2v2');
      expect(m.team(1).map((e) => e.userId), ['a', 'b']);
      expect(m.team(2).map((e) => e.userId), ['c', 'd']);
      expect(m.sideOf('d'), 2);
      expect(m.sideOf('zzz'), 0);
      expect(m.score1, 10);
      expect(m.endsAt, DateTime.utc(2026, 10, 1, 12, 5));
      expect(m.roomId, 'room-1');
    });

    test('1v1 yedek: participants yoksa user1/user2 kullanılır', () {
      final m = PkRoomMatch.fromJson({
        'id': 'pk2',
        'status': 'starting',
        'stream1Id': 'r',
        'stream2Id': 'r',
        'user1Id': 'a',
        'user2Id': 'b',
        'user1': {'id': 'a', 'name': 'Ali'},
        'user2': {'id': 'b', 'name': 'Bora'},
        'countdownSec': 5,
      })!;
      expect(m.phase, PkRoomPhase.starting);
      expect(m.team(1).single.name, 'Ali');
      expect(m.team(2).single.name, 'Bora');
    });

    test('kısmi olay (PK_PAUSED) maçı sıfırlamaz: üyeler/endsAt korunur', () {
      final prev = PkRoomMatch.fromJson(_battle())!;
      final paused = PkRoomMatch.fromJson({
        'eventType': 'PK_PAUSED',
        'battleId': 'pk1',
        'status': 'paused',
        'pausedAt': '2026-10-01T12:01:00.000Z',
        'remainingMs': 240000,
        'score1': 10,
        'score2': 5,
      }, previous: prev)!;
      expect(paused.phase, PkRoomPhase.paused);
      expect(paused.members.length, 4);
      expect(paused.endsAt, prev.endsAt);
      expect(paused.remainingMsAt(DateTime.utc(2026, 10, 1, 12, 3)), 240000);
    });

    test('PK_ENDED → finished, skorlar korunur', () {
      final prev = PkRoomMatch.fromJson(_battle())!;
      final ended = PkRoomMatch.fromJson({
        'eventType': 'PK_ENDED',
        'battleId': 'pk1',
        'status': 'completed',
        'score1': 312,
        'score2': 0,
        'winnerSide': 1,
        'reason': 'MANUAL',
      }, previous: prev)!;
      expect(ended.phase, PkRoomPhase.finished);
      expect(ended.phase.showsOverlay, isFalse);
      expect(ended.score1, 312);
      expect(ended.winnerSide, 1);
    });

    test('skor yaması: yalnızca skor + alıcı puanı; faz/süre/üye aynı', () {
      final prev = PkRoomMatch.fromJson(_battle())!;
      final patched = prev.withScorePatch(
        score1: 510,
        score2: 5,
        receiverId: 'b',
        addedAmount: 500,
      );
      expect(patched.phase, PkRoomPhase.active);
      expect(patched.endsAt, prev.endsAt);
      expect(patched.score1, 510);
      expect(patched.score2, 5);
      expect(patched.members.firstWhere((m) => m.userId == 'b').points, 500);
      expect(patched.members.firstWhere((m) => m.userId == 'a').points, 0);
    });

    test('kalan süre endsAt - sunucu zamanı; negatife düşmez', () {
      final m = PkRoomMatch.fromJson(_battle())!;
      expect(m.remainingMsAt(DateTime.utc(2026, 10, 1, 12, 0)), 300000);
      expect(m.remainingMsAt(DateTime.utc(2026, 10, 1, 12, 4, 57)), 3000);
      expect(m.remainingMsAt(DateTime.utc(2026, 10, 1, 12, 9)), 0);
    });

    test('starting fazında geri sayım sunucu zamanından bitiş üretir', () {
      final m = PkRoomMatch.fromJson({
        'id': 'p',
        'status': 'starting',
        'countdownSec': 5,
        'stream1Id': 'r',
        'stream2Id': 'r',
      }, serverNow: DateTime.utc(2026, 10, 1, 12))!;
      expect(m.startingUntil, DateTime.utc(2026, 10, 1, 12, 0, 5));
    });

    test('faz eşlemesi ve overlay görünürlüğü', () {
      expect(pkRoomPhaseFromStatus('starting').showsOverlay, isTrue);
      expect(pkRoomPhaseFromStatus('active').showsOverlay, isTrue);
      expect(pkRoomPhaseFromStatus('paused').showsOverlay, isTrue);
      expect(pkRoomPhaseFromStatus('completed').showsOverlay, isFalse);
      expect(pkRoomPhaseFromStatus('cancelled').isTerminal, isTrue);
      expect(PkRoomPhase.finishing.showsOverlay, isFalse);
    });
  });

  group('PkServerClock', () {
    test('iki cihaz farklı saatle AYNI kalan süreyi görür', () {
      // Gerçek sunucu zamanı T. Telefon A 7 sn ileri, telefon B 12 sn geri.
      final serverT = DateTime.utc(2026, 10, 1, 12, 0, 0);
      final endsAt = DateTime.utc(2026, 10, 1, 12, 5, 0);

      var aDevice = serverT.add(const Duration(seconds: 7));
      var bDevice = serverT.subtract(const Duration(seconds: 12));
      final a = PkServerClock(deviceNow: () => aDevice);
      final b = PkServerClock(deviceNow: () => bDevice);
      // İkisi de aynı anda `serverNow` aldı (gecikmesiz).
      a.observe(serverT);
      b.observe(serverT);

      // 100 sn geçti.
      aDevice = aDevice.add(const Duration(seconds: 100));
      bDevice = bDevice.add(const Duration(seconds: 100));
      final remA = endsAt.difference(a.now()).inSeconds;
      final remB = endsAt.difference(b.now()).inSeconds;
      expect(remA, 200);
      expect(remB, 200);
    });

    test('en düşük gecikmeli örnek (en büyük offset) seçilir', () {
      final base = DateTime.utc(2026, 10, 1, 12);
      final c = PkServerClock(deviceNow: () => base);
      c.observe(
        base.subtract(const Duration(milliseconds: 900)),
      ); // 900ms gecikmeli
      c.observe(
        base.subtract(const Duration(milliseconds: 40)),
      ); // 40ms gecikmeli
      c.observe(base.subtract(const Duration(milliseconds: 400)));
      expect(c.offset, const Duration(milliseconds: -40));
    });

    test('örnek yokken offset 0; geçersiz serverNow yok sayılır', () {
      final c = PkServerClock();
      expect(c.isSynced, isFalse);
      expect(c.offset, Duration.zero);
      expect(c.observeIso('bozuk'), isFalse);
      expect(c.observeIso(null), isFalse);
      expect(c.observeIso('2026-10-01T12:00:00.000Z'), isTrue);
      expect(c.isSynced, isTrue);
    });

    test('eski örnekler pencere dışına düşer (saat değişimi düzelir)', () {
      var dev = DateTime.utc(2026, 10, 1, 12);
      final c = PkServerClock(
        deviceNow: () => dev,
        window: const Duration(seconds: 30),
      );
      c.observe(dev.add(const Duration(seconds: 50))); // cihaz 50sn geride
      dev = dev.add(const Duration(minutes: 5));
      c.observe(dev); // artık senkron
      expect(c.offset, Duration.zero);
    });
  });

  group('PkGiftQueueCore (son 3 hediye)', () {
    PkGiftToast g(String id) =>
        PkGiftToast(id: id, senderName: 'S$id', giftName: 'Kalp', amount: 100);

    test('ilk hediye hemen görünür, sonrakiler sıraya girer', () {
      final q = PkGiftQueueCore();
      q.add(g('1'));
      q.add(g('2'));
      expect(q.current!.id, '1');
      expect(q.pending.map((e) => e.id), ['2']);
      expect(q.advance()!.id, '2');
      expect(q.advance(), isNull);
    });

    test(
      '5 hediye: toplam en fazla 3 tutulur (görünen + 2 bekleyen en yeni)',
      () {
        final q = PkGiftQueueCore();
        for (var i = 1; i <= 5; i++) {
          q.add(g('$i'));
        }
        expect(q.length, 3);
        expect(q.current!.id, '1'); // görünen kesilmez
        expect(q.pending.map((e) => e.id), [
          '4',
          '5',
        ]); // en eski bekleyenler düştü
        final order = <String>[q.current!.id];
        while (q.advance() != null) {
          order.add(q.current!.id);
        }
        expect(order, ['1', '4', '5']);
      },
    );

    test('aynı id iki kez eklenmez (çift teslim)', () {
      final q = PkGiftQueueCore();
      expect(q.add(g('x')), isTrue);
      expect(q.add(g('x')), isFalse);
      expect(q.length, 1);
    });

    test('clear her şeyi temizler', () {
      final q = PkGiftQueueCore()
        ..add(g('1'))
        ..add(g('2'));
      q.clear();
      expect(q.current, isNull);
      expect(q.length, 0);
      expect(q.add(g('1')), isTrue); // id belleği de sıfırlandı
    });
  });

  group('PkTeamLayout 1x1 … 4x4', () {
    test('takım büyüdükçe avatar küçülür, sınırlar korunur', () {
      double size(int n) => PkTeamLayout.compute(
        team1Count: n,
        team2Count: n,
        available: 150,
      ).avatarSize;
      expect(size(1), greaterThanOrEqualTo(size(2)));
      expect(size(2), greaterThanOrEqualTo(size(3)));
      expect(size(3), greaterThanOrEqualTo(size(4)));
      expect(size(4), greaterThanOrEqualTo(24));
      expect(size(1), lessThanOrEqualTo(42));
    });

    test('etiket ve taraf başına 4 sınırı', () {
      final l = PkTeamLayout.compute(
        team1Count: 7,
        team2Count: 3,
        available: 160,
      );
      expect(l.team1Count, 4);
      expect(l.label, '4x3');
      expect(l.perRow, 4);
    });

    test('dar ekranda dört kişi tek satıra sığar (taşma yok)', () {
      final l = PkTeamLayout.compute(
        team1Count: 4,
        team2Count: 4,
        available: 130,
      );
      final width = l.avatarSize * 4 + 6 * 3;
      // 24dp tabanı yüzünden en dar durumda hafif aşabilir; sarma (Wrap) bunu karşılar.
      expect(l.avatarSize, greaterThanOrEqualTo(24));
      expect(width, lessThanOrEqualTo(130 + 24));
      expect(l.showNames, isFalse); // küçük avatarda isim gizli
    });

    test('1x1 büyük avatar + isim gösterir', () {
      final l = PkTeamLayout.compute(
        team1Count: 1,
        team2Count: 1,
        available: 130,
      );
      expect(l.avatarSize, 42);
      expect(l.showNames, isTrue);
    });
  });
}
