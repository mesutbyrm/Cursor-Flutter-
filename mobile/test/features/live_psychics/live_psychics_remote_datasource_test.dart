import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:canlifal_social/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_status.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LivePsychicsRemoteDataSource.createSession', () {
    test('uses teller-scoped POST path first', () async {
      RequestOptions? captured;
      final dio = _dioWithAdapter(
        _FakeAdapter((options, _, __) {
          captured = options;
          return _jsonResponse(200, {
            'sessionId': 'sess_primary',
            'status': 'pending',
            'maxMinutes': 10,
          });
        }),
      );
      final remote = LivePsychicsRemoteDataSource(dio);

      final result = await remote.createSession(
        tellerId: 'teller_abc',
        durationMinutes: 10,
        fortuneType: 'tarot',
      );

      expect(result?.sessionId, 'sess_primary');
      expect(captured?.method, 'POST');
      expect(captured?.path, ApiEndpoints.fortuneTellerSessionFor('teller_abc'));
      expect(captured?.data, {
        'fortuneType': 'tarot',
        'maxMinutes': 10,
      });
    });

    test('falls back to generic session POST on 404', () async {
      final paths = <String>[];
      final dio = _dioWithAdapter(
        _FakeAdapter((options, _, __) {
          paths.add(options.path);
          if (options.path.contains('/teller_abc/session')) {
            return _jsonResponse(404, {'error': 'not found'});
          }
          return _jsonResponse(200, {
            'data': {
              'session': {
                'id': 'sess_fallback',
                'status': 'pending',
                'maxMinutes': 15,
              },
            },
          });
        }),
        strictSuccess: true,
      );
      final remote = LivePsychicsRemoteDataSource(dio);

      final result = await remote.createSession(
        tellerId: 'teller_abc',
        durationMinutes: 15,
        fortuneType: 'general',
      );

      expect(result?.sessionId, 'sess_fallback');
      expect(paths, contains(ApiEndpoints.fortuneTellerSessionFor('teller_abc')));
      expect(paths, contains(ApiEndpoints.fortuneTellerSession));
    });
  });

  group('LivePsychicsRemoteDataSource.cancelSession', () {
    test('PATCHes cancel action', () async {
      RequestOptions? captured;
      final dio = _dioWithAdapter(
        _FakeAdapter((options, _, __) {
          captured = options;
          return _jsonResponse(200, {'success': true});
        }),
      );
      final remote = LivePsychicsRemoteDataSource(dio);

      final ok = await remote.cancelSession('sess_cancel_1');

      expect(ok, isTrue);
      expect(captured?.method, 'PATCH');
      expect(
        captured?.path,
        ApiEndpoints.fortuneTellerSessionPatch('sess_cancel_1'),
      );
      expect(captured?.data, {'action': 'cancel'});
    });
  });

  group('LivePsychicsRemoteDataSource.roomAction', () {
    test('PATCHes room end action', () async {
      RequestOptions? captured;
      final dio = _dioWithAdapter(
        _FakeAdapter((options, _, __) {
          captured = options;
          return _jsonResponse(200, {
            'data': {'status': 'ended'},
          });
        }),
      );
      final remote = LivePsychicsRemoteDataSource(dio);

      final result = await remote.roomAction('sess_end_1', 'end');

      expect(result, isNotNull);
      expect(captured?.method, 'PATCH');
      expect(captured?.path, ApiEndpoints.liveFortuneRoom('sess_end_1'));
      expect(captured?.data, {'action': 'end'});
    });
  });

  group('LivePsychicsRemoteDataSource.respondSession', () {
    test('returns success when roomId present', () async {
      final dio = _dioWithAdapter(
        _FakeAdapter((options, _, __) {
          expect(options.method, 'PATCH');
          return _jsonResponse(200, {
            'sessionId': 'sess_accept',
            'roomId': 'room_xyz',
            'status': 'active',
          });
        }),
      );
      final remote = LivePsychicsRemoteDataSource(dio);

      final result = await remote.respondSession('sess_accept', action: 'accept');

      expect(result.success, isTrue);
      expect(result.roomId, 'room_xyz');
    });
  });

  group('LivePsychicsRemoteDataSource.fetchSessionStatus', () {
    test('parses query endpoint response', () async {
      final dio = _dioWithAdapter(
        _FakeAdapter((options, _, __) {
          expect(options.path, contains('/api/fortune-tellers/session?sessionId='));
          return _jsonResponse(200, {
            'data': {
              'sessionId': 'sess_status',
              'status': 'active',
              'isClient': true,
              'maxMinutes': 12,
            },
          });
        }),
      );
      final remote = LivePsychicsRemoteDataSource(dio);

      final status = await remote.fetchSessionStatus('sess_status');

      expect(status?.sessionId, 'sess_status');
      expect(status?.status, PsychicSessionStatus.active);
      expect(status?.isClient, isTrue);
    });
  });
}

Dio _dioWithAdapter(HttpClientAdapter adapter, {bool strictSuccess = false}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://canlifalapi.example.test',
      validateStatus: strictSuccess
          ? (status) => status != null && status >= 200 && status < 300
          : (_) => true,
    ),
  );
  dio.httpClientAdapter = adapter;
  return dio;
}

ResponseBody _jsonResponse(int status, Object body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

typedef _Responder =
    FutureOr<ResponseBody> Function(
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
  ) async {
    return responder(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}
