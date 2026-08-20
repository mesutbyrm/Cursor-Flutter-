import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/sse/sse_reconnect_policy.dart';
import '../../domain/entities/psychic_request_entity.dart';
import 'psychic_incoming_sse_parser.dart';

/// Falcı gelen istek SSE — `GET /api/fortune-tellers/sessions/stream`.
class PsychicIncomingSseService {
  PsychicIncomingSseService();

  Dio? _dio;
  CancelToken? _cancel;
  StreamSubscription<List<int>>? _bytesSub;
  Timer? _reconnectTimer;
  Future<String?> Function()? _accessToken;
  Future<bool> Function()? _refreshTokens;
  void Function(PsychicRequestEntity request)? _onRequest;
  void Function(String sessionId)? _onSessionCancelled;
  void Function()? _onPresenceTick;
  var _stopped = false;
  var _streamActive = false;
  var _reconnectAttempt = 0;

  bool get isStreamActive => _streamActive && !_stopped;

  Future<void> connect({
    required Future<String?> Function() accessToken,
    required void Function(PsychicRequestEntity request) onRequest,
    Future<bool> Function()? refreshTokens,
    void Function(String sessionId)? onSessionCancelled,
    void Function()? onPresenceTick,
  }) async {
    _stopped = false;
    _accessToken = accessToken;
    _refreshTokens = refreshTokens;
    _onRequest = onRequest;
    _onSessionCancelled = onSessionCancelled;
    _onPresenceTick = onPresenceTick;
    await _openStream();
  }

  Future<void> _openStream() async {
    await _closeStreamOnly();
    if (_stopped) return;
    final token = _accessToken != null ? await _accessToken!() : null;
    if (token == null || token.trim().isEmpty) {
      _scheduleReconnect();
      return;
    }
    _dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: Duration.zero,
      headers: {'Accept': 'text/event-stream'},
    ));
    _cancel = CancelToken();
    try {
      final res = await _dio!.get<ResponseBody>(
        ApiEndpoints.fortuneTellerSessionsStream,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Accept': 'text/event-stream',
            'Authorization': 'Bearer ${token.trim()}',
          },
        ),
        cancelToken: _cancel,
      );
      final stream = res.data?.stream;
      if (stream == null) {
        _scheduleReconnect();
        return;
      }
      _reconnectAttempt = 0;
      _streamActive = true;
      final buffer = StringBuffer();
      _bytesSub = stream.listen(
        (chunk) {
          buffer.write(utf8.decode(chunk, allowMalformed: true));
          _drain(buffer);
        },
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
        cancelOnError: false,
      );
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('PsychicIncomingSse: $e');
      if (e.response?.statusCode == 401 && _refreshTokens != null) {
        final ok = await _refreshTokens!();
        if (ok && !_stopped) {
          await _openStream();
          return;
        }
        return;
      }
      _scheduleReconnect();
    } catch (e) {
      if (kDebugMode) debugPrint('PsychicIncomingSse: $e');
      _scheduleReconnect();
    }
  }

  void _drain(StringBuffer buffer) {
    var raw = buffer.toString().replaceAll('\r\n', '\n');
    while (true) {
      final sep = raw.indexOf('\n\n');
      if (sep < 0) break;
      final block = raw.substring(0, sep);
      raw = raw.substring(sep + 2);
      _handleBlock(block);
    }
    buffer
      ..clear()
      ..write(raw);
  }

  void _handleBlock(String block) {
    String? eventName;
    final dataLines = <String>[];
    for (final line in block.split('\n')) {
      if (line.startsWith('event:')) eventName = line.substring(6).trim();
      if (line.startsWith('data:')) dataLines.add(line.substring(5).trimLeft());
    }
    if (dataLines.isEmpty) return;
    final payload = dataLines.join('\n').trim();
    if (payload.isEmpty || payload == '[DONE]') return;
    try {
      final decoded = jsonDecode(payload);
      final events = parsePsychicIncomingSsePayload(
        decoded,
        eventName: eventName,
      );
      for (final event in events) {
        switch (event) {
          case PsychicIncomingPresenceTick():
            _onPresenceTick?.call();
          case PsychicIncomingSessionRequests(:final requests):
            for (final req in requests) {
              _onRequest?.call(req);
            }
          case PsychicIncomingSessionCancelled(:final sessionId):
            _onSessionCancelled?.call(sessionId);
        }
      }
    } catch (_) {}
  }

  void _scheduleReconnect() {
    if (_stopped) return;
    if (SseReconnectPolicy.shouldGiveUp(_reconnectAttempt)) {
      if (kDebugMode) {
        debugPrint('PsychicIncomingSse: max reconnect attempts reached');
      }
      return;
    }
    _reconnectTimer?.cancel();
    _reconnectAttempt++;
    _reconnectTimer = Timer(
      SseReconnectPolicy.delayForAttempt(_reconnectAttempt),
      () {
        if (!_stopped) unawaited(_openStream());
      },
    );
  }

  Future<void> _closeStreamOnly() async {
    _streamActive = false;
    _reconnectTimer?.cancel();
    _cancel?.cancel('reconnect');
    await _bytesSub?.cancel();
    _dio?.close(force: true);
    _cancel = null;
    _bytesSub = null;
    _dio = null;
  }

  Future<void> disconnect() async {
    _stopped = true;
    _onRequest = null;
    _onSessionCancelled = null;
    _onPresenceTick = null;
    _refreshTokens = null;
    await _closeStreamOnly();
  }
}
