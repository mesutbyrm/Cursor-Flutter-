import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/network/sse/sse_chunk_decoder.dart';

void main() {
  group('SseChunkDecoder', () {
    const text = 'data: {"type":"pk","challengerName":"Şükrü Işık 🎉"}\n\n';
    final bytes = utf8.encode(text);

    test('bölünen çok baytlı karakteri bozmadan birleştirir', () {
      // Her olası kesme noktasında iki parçaya ayır.
      for (var cut = 1; cut < bytes.length; cut++) {
        final d = SseChunkDecoder();
        final out = d.convert(bytes.sublist(0, cut)) +
            d.convert(bytes.sublist(cut));
        expect(out, text, reason: 'cut=$cut');
      }
    });

    test('bayt bayt beslemede de metin aynı kalır', () {
      final d = SseChunkDecoder();
      final sb = StringBuffer();
      for (final b in bytes) {
        sb.write(d.convert([b]));
      }
      expect(sb.toString(), text);
    });

    test('tek parça ASCII doğrudan çözülür', () {
      expect(SseChunkDecoder().convert(utf8.encode(': heartbeat\n\n')),
          ': heartbeat\n\n');
    });

    test('eski yöntem (parça başına decode) bozuyordu', () {
      final i = bytes.indexOf(0xC5); // 'Ş' ilk baytı
      final broken = utf8.decode(bytes.sublist(0, i + 1), allowMalformed: true) +
          utf8.decode(bytes.sublist(i + 1), allowMalformed: true);
      expect(broken, isNot(text));
    });
  });
}
