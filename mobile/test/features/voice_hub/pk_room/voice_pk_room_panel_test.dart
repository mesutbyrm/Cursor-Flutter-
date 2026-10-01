import 'dart:math' as math;

import 'package:canlifal_social/core/economy/presentation/providers/economy_providers.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/live/data/datasources/live_gifts_remote_datasource.dart';
import 'package:canlifal_social/features/live/domain/entities/live_gift_event.dart';
import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/data/datasources/chat_room_gifts_remote_datasource.dart';
import 'package:canlifal_social/features/voice_hub/data/pk_room_api.dart';
import 'package:canlifal_social/features/voice_hub/data/services/voice_room_gift_realtime_service.dart';
import 'package:canlifal_social/features/voice_hub/presentation/pk_room/pk_room_controller.dart';
import 'package:canlifal_social/features/voice_hub/presentation/pk_room/voice_pk_room_panel.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/voice_gift_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _room = 'room-1';

class _FakeAuth extends AuthController {
  _FakeAuth(this._id);
  final String _id;
  @override
  Future<UserEntity?> build() async =>
      UserEntity(id: _id, username: _id, displayName: _id);
}

class _Api implements PkRoomApi {
  _Api(this.body);
  Map<String, dynamic>? body;
  int ends = 0;

  @override
  Future<Map<String, dynamic>?> fetchCurrent(
    String roomId, {
    String? alternateRoomId,
  }) async => body;

  @override
  Future<void> end(
    String roomId,
    String battleId, {
    String? alternateRoomId,
  }) async {
    ends++;
  }
}

/// [perSide] oyunculu (1–4) PK gövdesi; kullanıcı 'p1' Takım 1 kaptanı.
Map<String, dynamic> _pk(int perSide, {int score1 = 312, int score2 = 0}) => {
  'id': 'pk1',
  'status': 'active',
  'scope': 'room_user',
  'mode': perSide == 1 ? '1v1' : (perSide == 2 ? '2v2' : 'team'),
  'stream1Id': _room,
  'stream2Id': _room,
  'user1Id': 'p1',
  'user2Id': 'q1',
  'duration': 300,
  'score1': score1,
  'score2': score2,
  'endsAt': DateTime.now()
      .toUtc()
      .add(const Duration(minutes: 5))
      .toIso8601String(),
  'serverNow': DateTime.now().toUtc().toIso8601String(),
  'participants': [
    for (var i = 1; i <= perSide; i++)
      {
        'userId': 'p$i',
        'side': 1,
        'name': 'Oyuncu Bir $i',
        'isCaptain': i == 1,
      },
    for (var i = 1; i <= perSide; i++)
      {
        'userId': 'q$i',
        'side': 2,
        'name': 'Oyuncu İki $i',
        'isCaptain': i == 1,
      },
  ],
};

const _roomEntity = VoiceRoomEntity(id: _room, slug: 'oda', nameTr: 'Oda');

class _Harness {
  _Harness(this.api, {String userId = 'p1'}) {
    final dio = Dio();
    gifts = VoiceRoomGiftRealtimeService(
      ChatRoomGiftsRemoteDataSource(dio, LiveGiftsRemoteDataSource(dio)),
    );
    overrides = [
      pkRoomApiProvider.overrideWithValue(api),
      authControllerProvider.overrideWith(() => _FakeAuth(userId)),
      voiceRoomGiftRealtimeProvider.overrideWithValue(gifts),
      currencyBrandingProvider.overrideWith(
        (ref) async => throw StateError('offline'),
      ),
    ];
  }

  final _Api api;
  late VoiceRoomGiftRealtimeService gifts;
  late List<Override> overrides;
  var micToggles = 0;
  var chatToggles = 0;
  var giftTaps = 0;
  var chatOpen = false;
}

Future<void> _pump(
  WidgetTester tester,
  _Harness h, {
  required Size size,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: h.overrides,
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: SafeArea(
            child: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  VoicePkRoomHost(
                    roomKey: _room,
                    room: _roomEntity,
                    canManage: false,
                    micOn: true,
                    micEnabled: true,
                    onToggleMic: () => h.micToggles++,
                    onGift: () => h.giftTaps++,
                    chatOpen: h.chatOpen,
                    onToggleChat: () {
                      h.chatToggles++;
                      setState(() => h.chatOpen = !h.chatOpen);
                    },
                  ),
                  const Expanded(
                    child: SizedBox(key: ValueKey('seats-and-chat')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _done(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 2));
}

void main() {
  for (final c in <({String name, Size size, double scale})>[
    (name: '320x640', size: const Size(320, 640), scale: 1),
    (name: '360x800', size: const Size(360, 800), scale: 1),
    (name: '430x932', size: const Size(430, 932), scale: 1),
    (name: '360x800 yazı %160', size: const Size(360, 800), scale: 1.6),
    (name: 'yatay 800x360', size: const Size(800, 360), scale: 1),
  ]) {
    for (final n in [1, 2, 3, 4]) {
      testWidgets('PK ${n}x$n kompakt panel taşmadan çizilir: ${c.name}', (
        tester,
      ) async {
        final errors = <Object>[];
        final prev = FlutterError.onError;
        FlutterError.onError = (d) {
          errors.add(d.exception);
          prev?.call(d);
        };
        addTearDown(() => FlutterError.onError = prev);

        final h = _Harness(_Api(_pk(n)));
        await _pump(tester, h, size: c.size, textScale: c.scale);

        expect(find.text('1. TAKIM • SEN'), findsOneWidget);
        expect(find.text('2. TAKIM'), findsOneWidget);
        expect(find.text('VS'), findsOneWidget);
        expect(find.text('05:00'), findsOneWidget);
        expect(find.text('PK Bitir'), findsOneWidget); // kaptan

        // Panel yüksekliği ekranın ~%30'unu aşmaz (portrede); koltuklara yer kalır.
        final panel = tester.getSize(find.byType(VoicePkRoomHost));
        if (c.size.height > c.size.width) {
          expect(
            panel.height,
            lessThanOrEqualTo(math.max(c.size.height * 0.30, 200.0) + 12),
          );
        }
        expect(errors, isEmpty, reason: errors.join('\n'));
        await _done(tester);
      });
    }
  }

  testWidgets('kontroller: mikrofon, karşı takım sessiz, sohbet, hediye', (
    tester,
  ) async {
    final h = _Harness(_Api(_pk(2)));
    await _pump(tester, h, size: const Size(390, 844));

    await tester.tap(find.byTooltip('Mikrofonu kapat'));
    await tester.tap(find.byTooltip('Hediye'));
    await tester.tap(find.byTooltip('Sohbet'));
    await tester.pump();
    expect(h.micToggles, 1);
    expect(h.giftTaps, 1);
    expect(h.chatToggles, 1);
    expect(h.chatOpen, isTrue);

    // Karşı takımı sustur → yalnızca yerel durum + etiket değişir.
    expect(
      find.byTooltip('Karşı takımı sustur (yalnızca sende)'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Karşı takımı sustur (yalnızca sende)'));
    await tester.pump();
    expect(
      find.byTooltip('Karşı takım sessiz (yalnızca sende)'),
      findsOneWidget,
    );
    expect(h.api.ends, 0); // backend'e hiçbir şey gitmedi
    await _done(tester);
  });

  testWidgets('"PK Bitir": basınca panel ANINDA kaybolur, API çağrılır', (
    tester,
  ) async {
    final h = _Harness(_Api(_pk(2)));
    await _pump(tester, h, size: const Size(390, 844));
    expect(find.text('PK Bitir'), findsOneWidget);

    await tester.tap(find.text('PK Bitir'));
    await tester.pump(); // yalnızca bir kare
    expect(find.text('VS'), findsNothing); // normal odaya döndü
    expect(find.text('PK Bitir'), findsNothing);
    expect(find.byKey(const ValueKey('seats-and-chat')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 50));
    expect(h.api.ends, 1);
    await _done(tester);
  });

  testWidgets(
    'izleyici: mikrofon/karşı-takım düğmeleri yok; kaptan değil → PK Bitir yok',
    (tester) async {
      final h = _Harness(_Api(_pk(2)), userId: 'viewer');
      await _pump(tester, h, size: const Size(390, 844));
      expect(find.byTooltip('Mikrofonu kapat'), findsNothing);
      expect(
        find.byTooltip('Karşı takımı sustur (yalnızca sende)'),
        findsNothing,
      );
      expect(find.text('PK Bitir'), findsNothing);
      expect(find.byTooltip('Sohbet'), findsOneWidget);
      expect(find.byTooltip('Hediye'), findsOneWidget);
      await _done(tester);
    },
  );

  testWidgets('PK yokken panel hiç çizilmez (normal oda)', (tester) async {
    final h = _Harness(_Api(null));
    await _pump(tester, h, size: const Size(390, 844));
    expect(find.text('VS'), findsNothing);
    expect(tester.getSize(find.byType(VoicePkRoomHost)).height, 0);
    await _done(tester);
  });

  testWidgets(
    'hediye kartı: gönderen, hediye adı ve jeton görünür; sayaç sürer',
    (tester) async {
      final h = _Harness(_Api(_pk(2)));
      await _pump(tester, h, size: const Size(390, 844));

      h.gifts.publishRemote(
        LiveGiftEvent(
          id: 'g1',
          senderName: 'İlham Perisi',
          receiverName: 'Oyuncu Bir 2',
          receiverId: 'p2',
          giftId: 'heart',
          giftName: 'Kalp Hediyesi',
          quantity: 1,
          coinCost: 500,
          totalCoin: 500,
          timestamp: DateTime.now(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('İlham Perisi'), findsOneWidget);
      expect(find.textContaining('Kalp Hediyesi'), findsOneWidget);
      expect(find.textContaining('500'), findsWidgets);

      await tester.pump(const Duration(seconds: 3));

      // ~5 sn sonra kart fade-out olur, ipucu geri gelir.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('İlham Perisi'), findsNothing);
      expect(find.text('Hediye göndererek takımını destekle'), findsOneWidget);
      await _done(tester);
    },
  );

  testWidgets('skor çubuğu gerçek skoru gösterir (Takım 1: 312, Takım 2: 0)', (
    tester,
  ) async {
    final h = _Harness(_Api(_pk(1, score1: 312, score2: 0)));
    await _pump(tester, h, size: const Size(390, 844));
    expect(find.textContaining('312'), findsOneWidget);
    expect(find.textContaining('0 '), findsWidgets);
    await _done(tester);
  });
}
