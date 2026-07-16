import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/sse_client.dart';

void main() {
  group('SseClient.parseSseJsonBlock', () {
    test('parses type and data envelope', () {
      final map = SseClient.parseSseJsonBlock(
        'data: {"type":"message","data":{"id":"m1","content":"Merhaba"}}\n',
      );
      expect(map?['type'], 'message');
      expect(map?['data'], isA<Map>());
      final event = SseEvent.fromParsedMap(map!);
      expect(event.type, 'message');
      expect(event.dataMap?['content'], 'Merhaba');
    });

    test('uses event: line when type missing', () {
      final map = SseClient.parseSseJsonBlock(
        'event: gift\ndata: {"giftId":"g1","amount":500}\n',
      );
      expect(map?['type'], 'gift');
    });

    test('parses legacy string data payload', () {
      final map = SseClient.parseSseJsonBlock(
        'data: plain-text-chunk\n',
      );
      expect(map?['type'], 'message');
      expect(map?['data'], 'plain-text-chunk');
    });
  });

  group('SseClient.parseBlock', () {
    test('skips ping types via isPing', () {
      final ping = SseClient.parseBlock(
        'data: {"type":"connected"}\n',
      );
      expect(ping?.isPing, isTrue);

      final message = SseClient.parseBlock(
        'data: {"type":"streamMessage","data":{"text":"hi"}}\n',
      );
      expect(message?.isPing, isFalse);
      expect(message?.type, 'streamMessage');
    });
  });

  group('SseClient.drainBuffer', () {
    test('splits multiple SSE blocks', () {
      final buffer = StringBuffer()
        ..write(
          'data: {"type":"a"}\n\n'
          'data: {"type":"b"}\n\n',
        );
      final types = <String>[];
      SseClient.drainBuffer(buffer, (block) {
        final ev = SseClient.parseBlock(block);
        if (ev != null) types.add(ev.type);
      });
      expect(types, ['a', 'b']);
      expect(buffer.toString(), isEmpty);
    });
  });
}
