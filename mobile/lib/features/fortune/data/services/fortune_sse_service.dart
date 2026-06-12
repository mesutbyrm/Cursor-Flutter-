import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';

/// Fal LLM yanıtı — `POST /api/fortunes/*` SSE (`text/event-stream`).
class FortuneStreamChunk {
  const FortuneStreamChunk({
    required this.content,
    this.fortuneId,
    this.done = false,
  });

  final String content;
  final String? fortuneId;
  final bool done;
}

class FortuneSseService {
  FortuneSseService();

  static Dio _streamDio() {
    return Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: Duration.zero,
        headers: {
          'Accept': 'text/event-stream',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  /// SSE akışı; hata veya JSON yanıtında `onFallback` çağrılabilir.
  Stream<FortuneStreamChunk> streamReading({
    required String apiSlug,
    required Map<String, dynamic> body,
    required String accessToken,
  }) async* {
    final dio = _streamDio();
    final cancel = CancelToken();
  try {
      final res = await dio.post<ResponseBody>(
        ApiEndpoints.fortuneReading(apiSlug),
        data: body,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Authorization': 'Bearer ${accessToken.trim()}',
            'Accept': 'text/event-stream',
          },
        ),
        cancelToken: cancel,
      );

      final byteStream = res.data?.stream;
      if (byteStream == null) {
        throw StateError('empty_fortune_stream');
      }

      final buffer = StringBuffer();
      final acc = StringBuffer();
      String? fortuneId;

      await for (final chunk in byteStream) {
        buffer.write(utf8.decode(chunk, allowMalformed: true));
        var raw = buffer.toString().replaceAll('\r\n', '\n');
        while (true) {
          final sep = raw.indexOf('\n\n');
          if (sep < 0) break;
          final block = raw.substring(0, sep);
          raw = raw.substring(sep + 2);
          for (final line in block.split('\n')) {
            if (!line.startsWith('data:')) continue;
            final payload = line.substring(5).trimLeft();
            if (payload.isEmpty || payload == '[DONE]') continue;
            try {
              final decoded = jsonDecode(payload);
              if (decoded is! Map) continue;
              final map = Map<String, dynamic>.from(decoded);
              final type = map['type']?.toString() ?? '';
              if (type == 'done') {
                fortuneId = map['fortuneId']?.toString();
                yield FortuneStreamChunk(
                  content: acc.toString(),
                  fortuneId: fortuneId,
                  done: true,
                );
                return;
              }
              final piece = map['content']?.toString() ?? '';
              if (piece.isNotEmpty) {
                acc.write(piece);
                yield FortuneStreamChunk(content: acc.toString());
              }
            } catch (_) {
              // Tek satır düz metin SSE
              acc.write(payload);
              yield FortuneStreamChunk(content: acc.toString());
            }
          }
        }
        buffer
          ..clear()
          ..write(raw);
      }

      if (acc.isNotEmpty) {
        yield FortuneStreamChunk(
          content: acc.toString(),
          fortuneId: fortuneId,
          done: true,
        );
      }
    } finally {
      cancel.cancel('done');
      dio.close(force: true);
    }
  }
}
