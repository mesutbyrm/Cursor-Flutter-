import 'dart:convert';
import 'dart:typed_data';

import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:canlifal_social/features/live/data/datasources/live_api_remote_datasource.dart';
import 'package:canlifal_social/features/live/data/datasources/live_stream_extras_datasource.dart';
import 'package:canlifal_social/features/live/data/repositories/live_guest_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  test('postCoBroadcastCompat posts to /api/live/guest with UI body', () async {
    RequestOptions? captured;
    final dio = Dio()
      ..httpClientAdapter = _FakeAdapter((options, _, cancelFuture) async {
        captured = options;
        await cancelFuture;
        return ResponseBody.fromString(
          '{"ok":true}',
          200,
          headers: {Headers.contentTypeHeader: ['application/json']},
        );
      });

    final repo = LiveGuestRepositoryImpl(
      LiveApiRemoteDataSource(dio),
      LiveStreamExtrasDataSource(dio),
    );

    await repo.postCoBroadcastCompat(
      streamId: 'stream-1',
      action: 'request',
    );

    expect(captured?.path, ApiEndpoints.liveGuest);
    expect(captured?.method, 'POST');
    final data = captured?.data;
    expect(data, isA<Map>());
    expect((data as Map)['action'], 'request');
    expect((data as Map)['streamId'], 'stream-1');
  });

  test('fetchGuestList uses /api/live/guest/list not session path', () async {
    RequestOptions? captured;
    final dio = Dio()
      ..httpClientAdapter = _FakeAdapter((options, _, cancelFuture) async {
        captured = options;
        await cancelFuture;
        return ResponseBody.fromString(
          jsonEncode({'guests': [], 'count': 0}),
          200,
          headers: {Headers.contentTypeHeader: ['application/json']},
        );
      });

    final repo = LiveGuestRepositoryImpl(
      LiveApiRemoteDataSource(dio),
      LiveStreamExtrasDataSource(dio),
    );

    await repo.fetchGuestList(streamId: 's9');

    expect(captured?.path, ApiEndpoints.liveGuestList);
    expect(captured?.path, isNot(ApiEndpoints.liveGuest));
    expect(captured?.queryParameters['streamId'], 's9');
  });
}
