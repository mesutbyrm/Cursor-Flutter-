import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:canlifal_social/features/voice_hub/data/datasources/chat_room_remote_datasource.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_presence_persistence.dart';

void main() {
  group('VoiceRoomPresencePersistence', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('records the room, alternate key and owning user', () async {
      await VoiceRoomPresencePersistence.recordJoin(
        roomId: 'room-a',
        alternateRoomId: 'room-a-slug',
        userId: 'user-1',
      );

      final pending = await VoiceRoomPresencePersistence.readPending();
      expect(pending?.roomId, 'room-a');
      expect(pending?.alternate, 'room-a-slug');
      expect(pending?.userId, 'user-1');
    });

    test('clear removes the whole record', () async {
      await VoiceRoomPresencePersistence.recordJoin(
        roomId: 'room-a',
        userId: 'user-1',
      );
      await VoiceRoomPresencePersistence.clear();

      expect(await VoiceRoomPresencePersistence.readPending(), isNull);
    });

    test('a later join does not leak the previous alternate key', () async {
      await VoiceRoomPresencePersistence.recordJoin(
        roomId: 'room-a',
        alternateRoomId: 'alt-a',
        userId: 'user-1',
      );
      await VoiceRoomPresencePersistence.recordJoin(
        roomId: 'room-b',
        userId: 'user-1',
      );

      final pending = await VoiceRoomPresencePersistence.readPending();
      expect(pending?.roomId, 'room-b');
      expect(pending?.alternate, isNull);
    });
  });

  group('ChatRoomRemoteDataSource.leavePresence', () {
    test('reports success when the server accepts a variant', () async {
      final ds = ChatRoomRemoteDataSource(
        _dioWithAdapter(_FakeAdapter((_, _, _) async => _json(200, {}))),
      );

      expect(await ds.leavePresence('room-a'), isTrue);
    });

    test('reports failure instead of pretending success when no variant exists',
        () async {
      var calls = 0;
      final ds = ChatRoomRemoteDataSource(
        _dioWithAdapter(
          _FakeAdapter((_, _, _) async {
            calls++;
            return _json(404, {'error': 'not found'});
          }),
        ),
      );

      expect(await ds.leavePresence('room-a'), isFalse);
      expect(
        calls,
        greaterThan(1),
        reason: 'every fallback variant should be attempted before giving up',
      );
    });
  });
}

ResponseBody _json(int status, Map<String, dynamic> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

Dio _dioWithAdapter(HttpClientAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://canlifal.example.test',
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    ),
  );
  dio.httpClientAdapter = adapter;
  return dio;
}

typedef _Responder = Future<ResponseBody> Function(
  RequestOptions options,
  Stream<Uint8List>? requestStream,
  Future<void>? cancelFuture,
);

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responder);

  final _Responder responder;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      responder(options, requestStream, cancelFuture);

  @override
  void close({bool force = false}) {}
}
