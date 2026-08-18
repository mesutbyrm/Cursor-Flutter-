import 'dart:convert';
import 'dart:typed_data';

import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:canlifal_social/features/voice_hub/data/datasources/chat_room_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatRoomRemoteDataSource music query', () {
    test('skipMusicRequestByQueryEndpoint true for default canlifal.com', () {
      expect(ChatRoomRemoteDataSource.skipMusicRequestByQueryEndpoint, isTrue);
    });

    test('disableClientYoutubeSearch true on production host', () {
      expect(ChatRoomRemoteDataSource.disableClientYoutubeSearch, isTrue);
    });

    test('production skips music-request-by-query and posts song-request', () async {
      final paths = <String>[];
      final methods = <String>[];

      final dio = Dio(BaseOptions(baseUrl: 'https://canlifal.com'))
        ..httpClientAdapter = _FakeAdapter((options, _, cancelFuture) async {
          paths.add(options.path);
          methods.add(options.method);

          if (options.path == ApiEndpoints.youtubeSearch &&
              options.method == 'GET') {
            await cancelFuture;
            return ResponseBody.fromString(
              jsonEncode([
                {
                  'videoId': 'dQw4w9WgXcQ',
                  'title': 'Test Song',
                  'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
                },
              ]),
              200,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            );
          }

          if (options.path.contains('/song-request') &&
              options.method == 'POST') {
            await cancelFuture;
            return ResponseBody.fromString(
              jsonEncode({
                'playing': true,
                'musicUrl': '/api/chat/youtube-stream?videoId=dQw4w9WgXcQ',
                'queue': [
                  {
                    'title': 'Test Song',
                    'videoId': 'dQw4w9WgXcQ',
                  },
                ],
                'item': {
                  'title': 'Test Song',
                  'videoId': 'dQw4w9WgXcQ',
                },
              }),
              200,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            );
          }

          await cancelFuture;
          return ResponseBody.fromString('not found', 404);
        });

      final ds = ChatRoomRemoteDataSource(dio);
      final result = await ds.requestMusicByQuery(
        roomKey: 'cmoohrbr',
        query: 'Artist - Song',
      );

      expect(
        paths.any((p) => p.contains('music-request-by-query')),
        isFalse,
        reason: 'production must not call dead music-request-by-query',
      );
      expect(paths, contains(ApiEndpoints.youtubeSearch));
      expect(
        paths.any((p) => p.contains('/song-request')),
        isTrue,
      );
      expect(result.playing, isTrue);
      expect(result.musicUrl, isNotNull);
    });
  });
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
