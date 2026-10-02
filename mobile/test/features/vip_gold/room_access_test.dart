import 'dart:convert';
import 'dart:typed_data';

import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/vip_gold/data/room_access_remote_datasource.dart';
import 'package:canlifal_social/features/vip_gold/domain/room_access_models.dart';
import 'package:canlifal_social/features/vip_gold/domain/voice_room_access.dart';
import 'package:canlifal_social/features/vip_gold/presentation/providers/room_access_providers.dart';
import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/features/vip_gold/presentation/widgets/vip_locked_room_sheet.dart';
import 'package:canlifal_social/features/voice_hub/presentation/voice_room_gated_entry.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sabit yanıt veren sahte HTTP bağdaştırıcısı.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);
  final ({int status, Map<String, dynamic> body}) Function(RequestOptions) handler;
  final calls = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    final r = handler(options);
    return ResponseBody.fromString(
      jsonEncode(r.body),
      r.status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

RoomAccessRemoteDataSource _remote(_Adapter a) =>
    RoomAccessRemoteDataSource(Dio()..httpClientAdapter = a);

VoiceRoomEntity _room({String? type = 'VIP', bool? hasPassword = true}) =>
    VoiceRoomEntity(
      id: 'r1',
      slug: 'vip-oda',
      nameTr: 'VIP Oda',
      roomType: type,
      hasPassword: hasPassword,
    );

class _FakeRemote extends RoomAccessRemoteDataSource {
  _FakeRemote() : super(Dio());

  var remaining = 3;
  var locked = false;
  var verifyCalls = 0;
  var requestCalls = 0;
  bool alreadyRequested = false;

  @override
  Future<RoomAccessStatus> status(String roomKey) async => RoomAccessStatus(
        passwordProtected: true,
        remainingAttempts: remaining,
        locked: locked,
      );

  @override
  Future<PasswordVerifyResult> verifyPassword(
    String roomKey,
    String password,
  ) async {
    verifyCalls++;
    if (password == 'dogru') {
      return PasswordVerified(
        accessToken: 'tok',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
    }
    remaining = (remaining - 1).clamp(0, 3);
    locked = remaining == 0;
    return PasswordRejected(
      remainingAttempts: remaining,
      locked: locked,
      message: 'x',
    );
  }

  @override
  Future<JoinRequestSent> requestJoin(String roomKey) async {
    requestCalls++;
    return JoinRequestSent(
      requestId: alreadyRequested ? '' : 'req1',
      alreadySent: alreadyRequested,
      state: JoinRequestState.pending,
    );
  }

  @override
  Future<({JoinRequestState? state, bool allowed})> myRequest(
    String roomKey,
  ) async =>
      (state: JoinRequestState.pending, allowed: false);
}

Future<(ProviderContainer, _FakeRemote, ValueNotifier<bool?>)> _pumpSheet(
  WidgetTester tester, {
  _FakeRemote? remote,
}) async {
  final fake = remote ?? _FakeRemote();
  final container = ProviderContainer(
    overrides: [roomAccessRemoteProvider.overrideWithValue(fake)],
  );
  addTearDown(container.dispose);
  final result = ValueNotifier<bool?>(null);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => Center(
              child: ElevatedButton(
                onPressed: () async => result.value =
                    await showVipLockedRoomSheet(context, ref, room: _room()),
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('aç'));
  await tester.pumpAndSettle();
  return (container, fake, result);
}

void main() {
  gateTests();
  group('RoomAccessRemoteDataSource', () {
    test('verifyPassword: 200 → jeton döner', () async {
      final a = _Adapter(
        (_) => (
          status: 200,
          body: {
            'success': true,
            'data': {
              'accessToken': 'abc',
              'expiresAt': DateTime.now()
                  .add(const Duration(hours: 1))
                  .millisecondsSinceEpoch,
            },
          },
        ),
      );
      final res = await _remote(a).verifyPassword('r1', 'sifre');
      expect(res, isA<PasswordVerified>());
      expect((res as PasswordVerified).accessToken, 'abc');
      expect(a.calls.single.path, '/api/live/rooms/r1/verify-password');
      expect(a.calls.single.data, {'password': 'sifre'});
    });

    test('verifyPassword: yanlış → kalan hak okunur', () async {
      final a = _Adapter(
        (_) => (
          status: 403,
          body: {
            'success': false,
            'error': {
              'code': 'INVALID_ROOM_PASSWORD',
              'message': 'Şifre yanlış. 2 hakkınız kaldı.',
              'remainingAttempts': 2,
              'locked': false,
            },
          },
        ),
      );
      final res = await _remote(a).verifyPassword('r1', 'x');
      expect(res, isA<PasswordRejected>());
      final rej = res as PasswordRejected;
      expect(rej.remainingAttempts, 2);
      expect(rej.locked, isFalse);
    });

    test('verifyPassword: hak bitti → kilitli', () async {
      final a = _Adapter(
        (_) => (
          status: 403,
          body: {
            'success': false,
            'error': {
              'code': 'PASSWORD_ATTEMPTS_EXHAUSTED',
              'message': 'Giriş hakkınız kalmadı',
              'remainingAttempts': 0,
              'locked': true,
            },
          },
        ),
      );
      final rej = await _remote(a).verifyPassword('r1', 'x') as PasswordRejected;
      expect(rej.locked, isTrue);
      expect(rej.remainingAttempts, 0);
    });

    test('requestJoin: 409 → zaten istek gönderilmiş', () async {
      final a = _Adapter(
        (_) => (
          status: 409,
          body: {
            'success': false,
            'error': {
              'code': 'ALREADY_REQUESTED',
              'message': 'zaten',
              'status': 'pending',
            },
          },
        ),
      );
      final sent = await _remote(a).requestJoin('r1');
      expect(sent.alreadySent, isTrue);
      expect(sent.state, JoinRequestState.pending);
    });

    test('pending: sahibin bekleyen istekleri ayrıştırılır', () async {
      final a = _Adapter(
        (_) => (
          status: 200,
          body: {
            'success': true,
            'data': {
              'requests': [
                {
                  'id': 'q1',
                  'status': 'pending',
                  'user': {'id': 'u1', 'name': 'Ali', 'username': 'ali'},
                },
              ],
            },
          },
        ),
      );
      final list = await _remote(a).pending('r1');
      expect(list.single.handle, '@ali');
    });

    test('respond: 409 (başkası yanıtladı) hata sayılmaz', () async {
      final a = _Adapter((_) => (status: 409, body: {'success': false}));
      await _remote(a).respond('r1', 'q1', approve: true);
      expect(a.calls.single.path, endsWith('/join-request/q1/approve'));
    });
  });

  group('şifre kapısı yalnızca VIP odada', () {
    test('VIP + sunucu bayrağı → kilitli', () {
      expect(_room().isPasswordLockedRoom, isTrue);
    });
    test('normal oda şifreli sayılmaz', () {
      expect(_room(type: 'NORMAL').isPasswordLockedRoom, isFalse);
      expect(_room(type: 'FREE').isPasswordLockedRoom, isFalse);
    });
    test('VIP ama şifre yok → kilitsiz', () {
      expect(_room(hasPassword: false).isPasswordLockedRoom, isFalse);
      expect(_room(hasPassword: null).isPasswordLockedRoom, isFalse);
    });
  });

  group('VipLockedRoomSheet', () {
    testWidgets('ilk açılışta 3 hak ve istek butonu görünür', (tester) async {
      await _pumpSheet(tester);
      expect(find.text('Şifreli Oda'), findsOneWidget);
      expect(find.text('3 giriş hakkınız bulunmaktadır.'), findsOneWidget);
      expect(find.text('Odaya Gir'), findsOneWidget);
      expect(find.text('Oda Sahibine Bildir'), findsOneWidget);
    });

    testWidgets('yanlış şifre kalan hakkı gösterir; 3. yanlışta kilitlenir',
        (tester) async {
      final (_, fake, _) = await _pumpSheet(tester);
      for (final expected in const [
        'Şifre yanlış. 2 hakkınız kaldı.',
        'Şifre yanlış. 1 hakkınız kaldı.',
      ]) {
        await tester.enterText(find.byType(TextField), 'yanlis');
        await tester.tap(find.text('Odaya Gir'));
        await tester.pumpAndSettle();
        expect(find.text(expected), findsOneWidget);
      }
      await tester.enterText(find.byType(TextField), 'yanlis');
      await tester.tap(find.text('Odaya Gir'));
      await tester.pumpAndSettle();
      expect(find.text('Giriş hakkınız kalmadı.'), findsWidgets);
      expect(fake.verifyCalls, 3);
      // Kilitliyken buton ve alan devre dışı: yeni deneme yapılamaz.
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);
      await tester.tap(find.text('Odaya Gir'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(fake.verifyCalls, 3);
    });

    testWidgets('doğru şifre jetonu saklar ve true döner', (tester) async {
      final (container, _, result) = await _pumpSheet(tester);
      await tester.enterText(find.byType(TextField), 'dogru');
      await tester.tap(find.text('Odaya Gir'));
      await tester.pumpAndSettle();
      expect(result.value, isTrue);
      expect(container.read(roomAccessTokenProvider.notifier).peek('r1'), 'tok');
    });

    testWidgets('izin isteği yalnızca bir kez gönderilebilir', (tester) async {
      final (_, fake, _) = await _pumpSheet(tester);
      await tester.tap(find.text('Oda Sahibine Bildir'));
      await tester.pumpAndSettle();
      expect(
        find.text('Oda sahibine giriş isteğiniz gönderildi.'),
        findsOneWidget,
      );
      expect(find.text('İstek gönderildi — yanıt bekleniyor'), findsOneWidget);
      // Buton artık devre dışı: ikinci dokunuş istek göndermez.
      await tester.tap(
        find.text('İstek gönderildi — yanıt bekleniyor'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(fake.requestCalls, 1);
      // Sayfa kapanırken yoklama zamanlayıcısı temizlenir.
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('erişim jetonu', () {
    test('süresi dolan jeton döndürülmez', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(roomAccessTokenProvider.notifier);
      n.set('a', 't1', DateTime.now().subtract(const Duration(seconds: 1)));
      n.set('b', 't2', DateTime.now().add(const Duration(minutes: 5)));
      expect(n.peek('a'), isNull);
      expect(n.peek('b'), 't2');
      n.clear('b');
      expect(n.peek('b'), isNull);
    });
  });
}

class _GateRemote extends RoomAccessRemoteDataSource {
  _GateRemote(this.onStatus) : super(Dio());
  final Future<RoomAccessStatus> Function() onStatus;
  @override
  Future<RoomAccessStatus> status(String roomKey) => onStatus();
}

Future<void> _pumpGate(WidgetTester tester, RoomAccessRemoteDataSource remote) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [roomAccessRemoteProvider.overrideWithValue(remote)],
      child: MaterialApp(
        home: VoiceRoomGatedEntry(room: _room(), prepareSwitch: false),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void gateTests() {
  group('VoiceRoomGatedEntry (tek şifre kapısı)', () {
    testWidgets('şifreli odada kapı geçilmeden oda sayfası oluşturulmaz',
        (tester) async {
      await _pumpGate(
        tester,
        _GateRemote(
          () async => const RoomAccessStatus(passwordProtected: true),
        ),
      );
      // Şifre sayfası açık; oda içeriği yok.
      expect(find.text('Şifreli Oda'), findsOneWidget);
      // Sayfayı kapat → engel ekranı; oda içeriği hâlâ yok.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Bu odaya girmek için şifre gerekli'), findsOneWidget);
      expect(find.text('Şifre gir'), findsOneWidget);
    });

    testWidgets('durum alınamazsa (ağ hatası) oda açılmaz, tekrar dene çıkar',
        (tester) async {
      await _pumpGate(
        tester,
        _GateRemote(() async => throw const ApiException('Bağlantı yok')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tekrar dene'), findsOneWidget);
    });
  });
}
