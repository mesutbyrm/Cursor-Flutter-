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

    test('keeps every room whose leave was never confirmed', () async {
      await VoiceRoomPresencePersistence.recordJoin(
        roomId: 'room-a',
        userId: 'user-1',
      );
      await VoiceRoomPresencePersistence.recordJoin(
        roomId: 'room-b',
        userId: 'user-1',
      );

      final all = await VoiceRoomPresencePersistence.readPendingAll();
      expect(all.map((r) => r.roomId), ['room-a', 'room-b']);
    });

    test('clearRoom drops only the confirmed room', () async {
      await VoiceRoomPresencePersistence.recordJoin(roomId: 'room-a');
      await VoiceRoomPresencePersistence.recordJoin(roomId: 'room-b');

      await VoiceRoomPresencePersistence.clearRoom('room-b');

      final all = await VoiceRoomPresencePersistence.readPendingAll();
      expect(all.map((r) => r.roomId), ['room-a']);
    });

    test('clearRoom also matches the alternate key', () async {
      await VoiceRoomPresencePersistence.recordJoin(
        roomId: 'room-a',
        alternateRoomId: 'room-a-slug',
      );

      await VoiceRoomPresencePersistence.clearRoom('room-a-slug');

      expect(await VoiceRoomPresencePersistence.readPendingAll(), isEmpty);
    });

    test('re-joining the same room does not duplicate the record', () async {
      await VoiceRoomPresencePersistence.recordJoin(roomId: 'room-a');
      await VoiceRoomPresencePersistence.recordJoin(
        roomId: 'room-a',
        alternateRoomId: 'alt-a',
      );

      final all = await VoiceRoomPresencePersistence.readPendingAll();
      expect(all, hasLength(1));
      expect(all.single.alternate, 'alt-a');
    });

    test('migrates the single-slot record written by older builds', () async {
      SharedPreferences.setMockInitialValues({
        'voice_presence_room_id': 'room-legacy',
        'voice_presence_room_alt': 'legacy-slug',
        'voice_presence_user_id': 'user-9',
      });

      final all = await VoiceRoomPresencePersistence.readPendingAll();
      expect(all, hasLength(1));
      expect(all.single.roomId, 'room-legacy');
      expect(all.single.alternate, 'legacy-slug');
      expect(all.single.userId, 'user-9');

      // Taşındıktan sonra eski anahtarlar geri gelmemeli.
      await VoiceRoomPresencePersistence.clearRoom('room-legacy');
      expect(await VoiceRoomPresencePersistence.readPendingAll(), isEmpty);
    });

    test('keeps at most maxRecords rooms', () async {
      for (var i = 0; i < VoiceRoomPresencePersistence.maxRecords + 3; i++) {
        await VoiceRoomPresencePersistence.recordJoin(roomId: 'room-$i');
      }

      final all = await VoiceRoomPresencePersistence.readPendingAll();
      expect(all, hasLength(VoiceRoomPresencePersistence.maxRecords));
      expect(all.last.roomId, 'room-7');
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

    test('falls back to the alternate key when the primary key is unknown',
        () async {
      final seen = <String>[];
      final ds = ChatRoomRemoteDataSource(
        _dioWithAdapter(
          _FakeAdapter((options, _, _) async {
            seen.add(options.path);
            if (options.path.contains('room-slug')) return _json(200, {});
            return _json(404, {'error': 'not found'});
          }),
        ),
      );

      expect(
        await ds.leavePresence('room-a', alternateKey: 'room-slug'),
        isTrue,
      );
      expect(seen.any((p) => p.contains('room-slug')), isTrue);
    });

    test('does not retry the alternate key when it equals the primary',
        () async {
      final seen = <String>[];
      final ds = ChatRoomRemoteDataSource(
        _dioWithAdapter(
          _FakeAdapter((options, _, _) async {
            seen.add(options.path);
            return _json(404, {'error': 'not found'});
          }),
        ),
      );

      expect(await ds.leavePresence('room-a', alternateKey: 'room-a'), isFalse);
      expect(seen.every((p) => p.contains('room-a')), isTrue);
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
