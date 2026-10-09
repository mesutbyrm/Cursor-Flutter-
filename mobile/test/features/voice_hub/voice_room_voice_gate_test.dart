import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/data/datasources/chat_room_remote_datasource.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/voice_room_state_snapshot.dart';
import 'package:canlifal_social/features/voice_hub/presentation/audio/voice_room_audio_coordinator.dart';

void main() {
  group('/voice body', () {
    test('join/leave tek istek, backend `type` alanını taşır', () async {
      final bodies = <Map<String, dynamic>>[];
      final ds = ChatRoomRemoteDataSource(
        _dio((o) async {
          bodies.add(Map<String, dynamic>.from(o.data as Map));
          return _json(200, {'success': true});
        }),
      );
      await ds.joinVoiceSession('room-a');
      await ds.leaveVoiceSession('room-a');
      expect(bodies, [
        {'type': 'join', 'action': 'join'},
        {'type': 'leave', 'action': 'leave'},
      ]);
    });
  });

  group('VoiceRoomAudioCoordinator /voice gate', () {
    late List<String> calls;
    late int status;
    late Completer<void>? hold;
    late ChatRoomRemoteDataSource ds;

    setUp(() {
      calls = [];
      status = 200;
      hold = null;
      ds = ChatRoomRemoteDataSource(
        _dio((o) async {
          calls.add((o.data as Map)['type'].toString());
          final h = hold;
          if (h != null) await h.future;
          return _json(status, {'error': status == 403 ? 'No voice permission' : null});
        }),
      );
    });

    test('koltuk yokken /voice join gönderilmez', () async {
      final c = VoiceRoomAudioCoordinator()..setMicPublishGate(() => false);
      await c.ensureVoiceSessionForTest(ds, 'room-a');
      expect(calls, isEmpty);
      expect(c.voiceSessionJoined, isFalse);
    });

    test('eşzamanlı join tek POST (single-flight)', () async {
      final c = VoiceRoomAudioCoordinator()..setMicPublishGate(() => true);
      hold = Completer<void>();
      final a = c.ensureVoiceSessionForTest(ds, 'room-a');
      final b = c.ensureVoiceSessionForTest(ds, 'room-a');
      hold!.complete();
      await Future.wait([a, b]);
      await c.ensureVoiceSessionForTest(ds, 'room-a');
      expect(calls, ['join']);
      expect(c.voiceSessionJoined, isTrue);
    });

    test('403 sonrası yeniden deneme yok', () async {
      final c = VoiceRoomAudioCoordinator()..setMicPublishGate(() => true);
      status = 403;
      await expectLater(c.ensureVoiceSessionForTest(ds, 'room-a'), throwsA(anything));
      await expectLater(c.ensureVoiceSessionForTest(ds, 'room-a'), throwsA(anything));
      expect(calls, ['join']);
      expect(c.isVoiceBlocked('room-a'), isTrue);
      c.resetVoiceApiBlock();
      expect(c.isVoiceBlocked('room-a'), isFalse);
    });

    test('leave yalnız join edilmişse gönderilir', () async {
      final c = VoiceRoomAudioCoordinator()..setMicPublishGate(() => true);
      await c.leaveVoiceSessionIfJoinedForTest(ds, 'room-a');
      await c.leaveVoiceSessionIfJoinedForTest(ds, 'room-a');
      expect(calls, isEmpty);
      await c.ensureVoiceSessionForTest(ds, 'room-a');
      await c.leaveVoiceSessionIfJoinedForTest(ds, 'room-a');
      await c.leaveVoiceSessionIfJoinedForTest(ds, 'room-a');
      expect(calls, ['join', 'leave']);
    });
  });

  group('speak-requests 403', () {
    test('403 sonrası oda için tekrar istek atılmaz', () async {
      var count = 0;
      final ds = ChatRoomRemoteDataSource(
        _dio((o) async {
          count++;
          return _json(403, {'error': 'Forbidden'});
        }),
      );
      expect(await ds.fetchSpeakRequests('room-a'), isEmpty);
      expect(await ds.fetchSpeakRequests('room-a'), isEmpty);
      expect(count, 1);
      expect(ds.isSpeakRequestsBlocked('room-a'), isTrue);
    });
  });

  group('VoiceRoomStateSnapshot', () {
    test('{success,data} zarfını açar; katılımcı `me` yetki sayılmaz', () {
      final snap = VoiceRoomStateSnapshot.fromJson({
        'success': true,
        'data': {
          'participants': [
            {'id': 'u1', 'name': 'A', 'seatIndex': -1},
          ],
          'seats': <dynamic>[],
          'me': {'id': 'u1', 'name': 'A', 'seatIndex': -1, 'isAdmin': false},
        },
      }, roomId: 'room-a');
      expect(snap.participants, hasLength(1));
      expect(snap.me, isNull);
    });
  });
}

ResponseBody _json(int status, Map<String, dynamic> body) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Dio _dio(Future<ResponseBody> Function(RequestOptions o) responder) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://canlifal.example.test',
      validateStatus: (s) => s != null && s >= 200 && s < 300,
    ),
  );
  dio.httpClientAdapter = _FakeAdapter(responder);
  return dio;
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responder);

  final Future<ResponseBody> Function(RequestOptions o) responder;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      responder(options);

  @override
  void close({bool force = false}) {}
}
