import 'dart:convert';
import 'dart:typed_data';

import 'package:canlifal_social/core/push/message_notification_data.dart';
import 'package:canlifal_social/core/push/notification_channels.dart';
import 'package:canlifal_social/core/push/notification_permission_prompter.dart';
import 'package:canlifal_social/core/push/notification_reply_sender.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Adapter implements HttpClientAdapter {
  RequestOptions? last;
  int status = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode({'ok': true}),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('MessageNotificationData', () {
    test('backend push (type/targetPath/targetId + gövde) → gönderen adı çıkarılır', () {
      final m = MessageNotificationData.tryParse(
        {'type': 'message', 'targetPath': '/chat/u42', 'targetId': 'u42'},
        fallbackTitle: 'Yeni mesaj',
        fallbackBody: 'Ayşe size bir mesaj gönderdi',
      );
      expect(m, isNotNull);
      expect(m!.senderId, 'u42');
      expect(m.senderName, 'Ayşe');
      expect(m.text, isNull, reason: 'metin yoksa uydurulmaz');
      expect(m.targetPath, '/chat/u42');
    });

    test('opsiyonel alanlar (avatar + metin) varsa kullanılır', () {
      final m = MessageNotificationData.tryParse({
        'type': 'message',
        'senderId': 'u7',
        'senderName': 'Mehmet',
        'senderAvatar': 'https://x/y.jpg',
        'text': 'Selam!',
      });
      expect(m!.senderName, 'Mehmet');
      expect(m.avatarUrl, 'https://x/y.jpg');
      expect(m.text, 'Selam!');
      expect(m.targetPath, '/chat/u7');
    });

    test('mesaj olmayan bildirim → null', () {
      expect(
        MessageNotificationData.tryParse({'type': 'like', 'targetPath': '/social/post/1'}),
        isNull,
      );
    });

    test('aynı kişi → aynı bildirim kimliği (birleşir)', () {
      final a = MessageNotificationData(senderId: 'u1', senderName: 'A', targetPath: '/chat/u1');
      final b = MessageNotificationData(senderId: 'u1', senderName: 'A', targetPath: '/chat/u1');
      expect(a.notificationId, b.notificationId);
    });
  });

  group('AppNotificationChannel', () {
    test('tür → kanal eşlemesi', () {
      expect(AppNotificationChannel.forType('message'), AppNotificationChannel.messages);
      expect(AppNotificationChannel.forType('live'), AppNotificationChannel.liveStarters);
      expect(AppNotificationChannel.forType('stream_live'), AppNotificationChannel.liveStarters);
      expect(AppNotificationChannel.forType('streamEnded'), AppNotificationChannel.other);
      expect(AppNotificationChannel.forType('daily_fortune'), AppNotificationChannel.dailyFortune);
      expect(AppNotificationChannel.forType('like'), AppNotificationChannel.other);
      expect(AppNotificationChannel.forType(null), AppNotificationChannel.other);
    });

    test('tercihler kalıcı; varsayılan açık', () async {
      SharedPreferences.setMockInitialValues({});
      const prefs = NotificationChannelPrefs();
      expect(await prefs.isEnabled(AppNotificationChannel.messages), isTrue);
      await prefs.setEnabled(AppNotificationChannel.liveStarters, false);
      final all = await prefs.loadAll();
      expect(all[AppNotificationChannel.liveStarters], isFalse);
      expect(all[AppNotificationChannel.messages], isTrue);
    });
  });

  group('NotificationReplySender', () {
    test('cevap POST /api/messages/{id} ile Bearer token kullanır', () async {
      final adapter = _Adapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://x.test'))..httpClientAdapter = adapter;
      await NotificationReplySender.sendDirect(
        'u42',
        'Tamam geliyorum',
        dio: dio,
        readToken: () async => 'tok123',
      );
      expect(adapter.last!.method, 'POST');
      expect(adapter.last!.path, '/api/messages/u42');
      expect(adapter.last!.headers['Authorization'], 'Bearer tok123');
      expect((adapter.last!.data as Map)['content'], 'Tamam geliyorum');
    });

    test('oturum yoksa hata fırlatır (bildirim "gönderilemedi" der)', () async {
      expect(
        () => NotificationReplySender.sendDirect(
          'u42',
          'x',
          dio: Dio(),
          readToken: () async => null,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('foreground handler varsa o kullanılır', () async {
      String? gotPeer, gotText;
      NotificationReplySender.foregroundHandler = (p, t) async {
        gotPeer = p;
        gotText = t;
      };
      addTearDown(() => NotificationReplySender.foregroundHandler = null);
      await NotificationReplySender.send(' u9 ', ' merhaba ');
      expect(gotPeer, 'u9');
      expect(gotText, 'merhaba');
    });
  });

  test('izin istemi: yalnızca verilmemiş ve daha önce sorulmamışsa', () {
    expect(NotificationPermissionPrompter.shouldPrompt(granted: false, prompted: false), isTrue);
    expect(NotificationPermissionPrompter.shouldPrompt(granted: true, prompted: false), isFalse);
    expect(NotificationPermissionPrompter.shouldPrompt(granted: false, prompted: true), isFalse);
  });
}
