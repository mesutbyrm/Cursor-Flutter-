import 'dart:convert';
import 'dart:typed_data';

import 'package:canlifal_social/features/messages/data/datasources/messages_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  final queries = <Map<String, dynamic>>[];

  Map<String, dynamic> _msg(int i) => {
        'id': 'm$i',
        'senderId': i.isEven ? 'me' : 'peer',
        'receiverId': i.isEven ? 'peer' : 'me',
        'content': 'mesaj $i',
        'createdAt': DateTime.utc(2026, 1, 1).add(Duration(minutes: i)).toIso8601String(),
      };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    queries.add(Map.of(options.queryParameters));
    final cursor = options.queryParameters['paginate'] == 'cursor';
    final body = cursor
        // en yeni 50 (desc): 250..201
        ? {'success': true, 'data': [for (var i = 250; i > 200; i--) _msg(i)], 'meta': {}}
        // düz GET: en eski 100 (asc): 1..100
        : {'user': {'id': 'peer'}, 'messages': [for (var i = 1; i <= 100; i++) _msg(i)]};
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('100 mesaja ulaşıldıysa en yeni sayfa da eklenir (yeni mesajlar uzun sohbette görünür)', () async {
    final adapter = _Adapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://x.test'))..httpClientAdapter = adapter;
    final ds = MessagesRemoteDataSource(dio);
    final list = await ds.messages('peer', currentUserId: 'me', forceRefresh: true);

    expect(adapter.queries.length, 2);
    expect(adapter.queries.last['paginate'], 'cursor');
    final ids = list.map((m) => m.id).toSet();
    expect(ids.contains('m1'), isTrue);
    expect(ids.contains('m100'), isTrue);
    expect(ids.contains('m250'), isTrue, reason: 'en yeni mesaj listede olmalı');
    expect(list.length, 150);
    // artan zaman sırası
    for (var i = 1; i < list.length; i++) {
      expect(list[i].createdAt!.isBefore(list[i - 1].createdAt!), isFalse);
    }
  });
}
