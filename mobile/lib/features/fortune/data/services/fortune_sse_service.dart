import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/util/json_util.dart';

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

/// İptal edilebilir fal SSE oturumu.
class FortuneSseSession {
  FortuneSseSession._({
    required this.stream,
    required CancelToken cancelToken,
    required Dio dio,
  })  : _cancelToken = cancelToken,
        _dio = dio;

  final Stream<FortuneStreamChunk> stream;
  final CancelToken _cancelToken;
  final Dio _dio;

  void cancel([String reason = 'user_cancelled']) {
    if (!_cancelToken.isCancelled) {
      _cancelToken.cancel(reason);
    }
    _dio.close(force: true);
  }
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
          'Connection': 'keep-alive',
        },
        persistentConnection: true,
      ),
    );
  }

  /// SSE akışı; [FortuneSseSession.cancel] ile iptal edilir.
  FortuneSseSession openReading({
    required String apiSlug,
    required Map<String, dynamic> body,
    required String accessToken,
  }) {
    final dio = _streamDio();
    final cancel = CancelToken();
    final controller = StreamController<FortuneStreamChunk>();

    unawaited(_pump(
      dio: dio,
      cancel: cancel,
      apiSlug: apiSlug,
      body: body,
      accessToken: accessToken,
      controller: controller,
    ));

    return FortuneSseSession._(
      stream: controller.stream,
      cancelToken: cancel,
      dio: dio,
    );
  }

  /// Geriye dönük uyumluluk.
  Stream<FortuneStreamChunk> streamReading({
    required String apiSlug,
    required Map<String, dynamic> body,
    required String accessToken,
  }) {
    return openReading(
      apiSlug: apiSlug,
      body: body,
      accessToken: accessToken,
    ).stream;
  }

  Future<void> _pump({
    required Dio dio,
    required CancelToken cancel,
    required String apiSlug,
    required Map<String, dynamic> body,
    required String accessToken,
    required StreamController<FortuneStreamChunk> controller,
  }) async {
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
        if (cancel.isCancelled) break;
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
                controller.add(
                  FortuneStreamChunk(
                    content: acc.toString(),
                    fortuneId: fortuneId,
                    done: true,
                  ),
                );
                await controller.close();
                return;
              }
              final piece = map['content']?.toString() ?? '';
              if (piece.isNotEmpty) {
                acc.write(piece);
                controller.add(FortuneStreamChunk(content: acc.toString()));
              }
            } catch (_) {
              acc.write(payload);
              controller.add(FortuneStreamChunk(content: acc.toString()));
            }
          }
        }
        buffer
          ..clear()
          ..write(raw);
      }

      if (acc.isNotEmpty) {
        controller.add(
          FortuneStreamChunk(
            content: acc.toString(),
            fortuneId: fortuneId,
            done: true,
          ),
        );
      } else {
        final tail = buffer.toString().trim();
        final fromJson = _parseJsonFortuneBody(tail);
        if (fromJson != null) {
          controller.add(
            FortuneStreamChunk(
              content: fromJson.text,
              fortuneId: fromJson.fortuneId,
              done: true,
            ),
          );
        } else if (!cancel.isCancelled) {
          controller.addError(StateError('empty_fortune_stream'));
        }
      }
    } catch (e, st) {
      if (!controller.isClosed && !cancel.isCancelled) {
        controller.addError(e, st);
      }
    } finally {
      if (!controller.isClosed) {
        await controller.close();
      }
      cancel.cancel('done');
      dio.close(force: true);
    }
  }

  ({String text, String? fortuneId})? _parseJsonFortuneBody(String raw) {
    if (raw.isEmpty || !raw.startsWith('{')) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      final nested = map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : map;
      final text = pick(nested, [
        'detail',
        'interpretation',
        'reading',
        'content',
        'text',
        'summary',
      ])?.toString();
      if (text == null || text.trim().isEmpty) return null;
      return (
        text: text,
        fortuneId: pick(nested, ['id', 'fortuneId', 'recordId'])?.toString(),
      );
    } catch (_) {
      return null;
    }
  }
}
