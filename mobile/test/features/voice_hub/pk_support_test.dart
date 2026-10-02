import 'dart:convert';
import 'dart:typed_data';

import 'package:canlifal_social/features/voice_hub/data/datasources/chat_room_remote_datasource.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk_room/pk_wire_event.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  RequestOptions? last;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'battleId': 'b1',
        'score1': 12,
        'score2': 9,
        'addedAmount': 3,
        'addedSide': 'room1',
      }),
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
  test('Destekle: sunucu skorunu ve eklenen puanı okur; taraf istemciden seçilmez',
      () async {
    final adapter = _Adapter();
    final remote = ChatRoomRemoteDataSource(Dio()..httpClientAdapter = adapter);
    final res = await remote.supportPk(roomKey: 'r1', battleId: 'b1');
    expect(res.score1, 12);
    expect(res.score2, 9);
    expect(res.added, 3);
    expect(adapter.last!.path, '/api/chat/rooms/r1/pk/support');
    // Oda-vs-oda PK: gövdede `side` yok (sunucu bulunduğun odadan türetir).
    expect((adapter.last!.data as Map).containsKey('side'), isFalse);
    expect((adapter.last!.data as Map)['battleId'], 'b1');
  });

  test('Oda içi takım PK: desteklenen takım side ile gönderilir', () async {
    final adapter = _Adapter();
    final remote = ChatRoomRemoteDataSource(Dio()..httpClientAdapter = adapter);
    await remote.supportPk(roomKey: 'r1', battleId: 'b1', side: 2);
    expect((adapter.last!.data as Map)['side'], 2);
  });

  test('Destek skoru PK_SCORE yaması olarak sınıflanır (davet açmaz)', () {
    final e = PkWireEvent.parse({
      'type': 'pk',
      'eventType': 'PK_SCORE',
      'action': 'score_update',
      'battleId': 'b1',
      'score1': 12,
      'score2': 9,
      'source': 'support',
    });
    expect(e.kind, PkWireKind.score);
    expect(e.isInvite, isFalse);
  });
}
