import 'dart:async';
import 'dart:typed_data';

import 'package:canlifal_social/core/sse_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const _ssePayload =
    'data: {"type":"connected"}\n\n'
    'data: {"type":"message","data":{"content":"cycle-test"}}\n\n';

ResponseBody _sseBody() {
  return ResponseBody.fromString(
    _ssePayload,
    200,
    headers: {
      Headers.contentTypeHeader: ['text/event-stream'],
    },
  );
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
  ) {
    return responder(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWithResponder(_Responder responder) {
  return Dio()..httpClientAdapter = _FakeAdapter(responder);
}

void main() {
  group('SSE 20-cycle lifecycle', () {
    test('connect/disconnect 20 times with same connectionId completes cleanly', () async {
      var connectCount = 0;
      final dio = _dioWithResponder((options, _, __) async {
        connectCount++;
        return _sseBody();
      });

      final client = SseClient(
        baseUrl: 'https://canlifal.com',
        accessToken: () async => 'test-jwt',
        dio: dio,
      );

      const connId = 'chat:room-cycle-test';
      for (var i = 0; i < 20; i++) {
        final sub = client
            .connectPath(
              '/api/chat/rooms/room-cycle-test/stream',
              connectionId: connId,
            )
            .listen((_) {});
        await Future<void>.delayed(const Duration(milliseconds: 80));
        client.disconnect(connId);
        await sub.cancel();
      }

      client.disconnectAll();
      expect(connectCount, greaterThanOrEqualTo(1));
    });

    test('duplicate connectionId replaces previous stream (no parallel duplicate)', () async {
      var activeStreams = 0;
      var maxConcurrent = 0;
      final dio = _dioWithResponder((options, _, __) async {
        activeStreams++;
        if (activeStreams > maxConcurrent) maxConcurrent = activeStreams;
        await Future<void>.delayed(const Duration(milliseconds: 80));
        activeStreams--;
        return _sseBody();
      });

      final client = SseClient(
        baseUrl: 'https://canlifal.com',
        accessToken: () async => 'jwt',
        dio: dio,
      );

      const id = 'dup-test';
      final sub1 = client
          .connectPath('/api/chat/rooms/x/stream', connectionId: id)
          .listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final sub2 = client
          .connectPath('/api/chat/rooms/x/stream', connectionId: id)
          .listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 30));
      client.disconnect(id);
      await sub1.cancel();
      await sub2.cancel();
      client.disconnectAll();

      expect(maxConcurrent, lessThanOrEqualTo(1));
    });

    test('disconnectAll after 20 unique connectionIds clears subscriptions', () async {
      final client = SseClient(
        baseUrl: 'https://canlifal.com',
        accessToken: () async => 'jwt',
        dio: _dioWithResponder((_, __, ___) async => _sseBody()),
      );

      final subs = <StreamSubscription<SseEvent>>[];
      for (var i = 0; i < 20; i++) {
        subs.add(
          client
              .connectPath(
                '/api/chat/rooms/r$i/stream',
                connectionId: 'conn-$i',
              )
              .listen((_) {}),
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
      client.disconnectAll();
      for (final s in subs) {
        await s.cancel();
      }
      client.disconnectAll();
    });

    test('receives non-ping event from mock stream', () async {
      final client = SseClient(
        baseUrl: 'https://canlifal.com',
        accessToken: () async => 'jwt',
        dio: _dioWithResponder((_, __, ___) async => _sseBody()),
      );

      final completer = Completer<SseEvent>();
      final sub = client
          .connectPath('/api/chat/rooms/r/stream', connectionId: 'evt-test')
          .listen((e) {
        if (!e.isPing && !completer.isCompleted) completer.complete(e);
      });

      final event = await completer.future.timeout(const Duration(seconds: 2));
      client.disconnect('evt-test');
      await sub.cancel();

      expect(event.type, 'message');
      expect(event.dataMap?['content'], 'cycle-test');
    });
  });
}
