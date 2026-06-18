import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/live_fortune_session_entity.dart';
import '../../presentation/providers/fortune_live_event_bus.dart';

/// Falcı — `GET /api/fortune-tellers/sessions/stream` (üretim SSE).
///
/// Yayın veya sesli oda açmadan gelen canlı fal isteklerini dinler.
class LiveFortuneTellerIncomingSseService {
  LiveFortuneTellerIncomingSseService();

  static const _fortuneEventTypes = {
    'fal_request',
    'live_fal_request',
    'fortune_request',
    'private_fal_request',
    'session_request',
    'live_session_request',
    'pending',
  };

  static Dio _sseDio() {
    return Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: Duration.zero,
        headers: {'Accept': 'text/event-stream'},
      ),
    );
  }

  Dio? _dio;
  CancelToken? _cancel;
  StreamSubscription<List<int>>? _bytesSub;
  Timer? _reconnectTimer;

  Future<String?> Function()? _accessToken;
  void Function(FortuneIncomingSession request)? _onRequest;
  var _stopped = false;
  var _connected = false;
  var _reconnectAttempt = 0;

  static String streamUrlFor() {
    final base = Env.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    return '$base${ApiEndpoints.fortuneTellerSessionsStream}';
  }

  Future<void> connect({
    required Future<String?> Function() accessToken,
    required void Function(FortuneIncomingSession request) onRequest,
  }) async {
    if (!_stopped && _connected && _bytesSub != null) return;
    _stopped = false;
    _accessToken = accessToken;
    _onRequest = onRequest;
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

    final headers = <String, dynamic>{
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Authorization': 'Bearer ${token.trim()}',
    };

    _dio = _sseDio();
    _cancel = CancelToken();
    try {
      final res = await _dio!.get<ResponseBody>(
        ApiEndpoints.fortuneTellerSessionsStream,
        options: Options(
          responseType: ResponseType.stream,
          headers: headers,
        ),
        cancelToken: _cancel,
      );
      final byteStream = res.data?.stream;
      if (byteStream == null) {
        _scheduleReconnect();
        return;
      }

      _reconnectAttempt = 0;
      _connected = true;
      final buffer = StringBuffer();
      _bytesSub = byteStream.listen(
        (chunk) {
          buffer.write(utf8.decode(chunk, allowMalformed: true));
          _drainSseBuffer(buffer);
        },
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
        cancelOnError: false,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Falcı incoming SSE bağlantı hatası: $e');
      }
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_stopped) return;
    _connected = false;
    _reconnectTimer?.cancel();
    _reconnectAttempt++;
    final delay = Duration(seconds: (_reconnectAttempt.clamp(1, 6) * 2));
    _reconnectTimer = Timer(delay, () {
      if (!_stopped) unawaited(_openStream());
    });
  }

  void _drainSseBuffer(StringBuffer buffer) {
    var raw = buffer.toString().replaceAll('\r\n', '\n');
    while (true) {
      final sep = raw.indexOf('\n\n');
      if (sep < 0) break;
      final block = raw.substring(0, sep);
      raw = raw.substring(sep + 2);
      _handleSseBlock(block);
    }
    buffer
      ..clear()
      ..write(raw);
  }

  void _handleSseBlock(String block) {
    String? eventName;
    final dataLines = <String>[];
    for (final line in block.split('\n')) {
      if (line.startsWith('event:')) {
        eventName = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
      }
    }
    if (dataLines.isEmpty) return;
    final payload = dataLines.join('\n').trim();
    if (payload.isEmpty || payload == '[DONE]') return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return;
      _dispatchFortuneEvent(Map<String, dynamic>.from(decoded), eventName);
    } catch (_) {}
  }

  void _dispatchFortuneEvent(Map<String, dynamic> map, String? sseEventName) {
    final typeRaw = (map['type'] ?? sseEventName ?? '').toString().toLowerCase();
    final looksLikeRequest = _fortuneEventTypes.contains(typeRaw) ||
        typeRaw.contains('session') ||
        typeRaw.contains('request') ||
        map.containsKey('sessionId');
    if (!looksLikeRequest) return;

    final session = parseFortuneSsePayload(map);
    if (session == null || session.sessionId.isEmpty) return;
    _onRequest?.call(session);
  }

  Future<void> _closeStreamOnly() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _cancel?.cancel('reconnect');
    _cancel = null;
    await _bytesSub?.cancel();
    _bytesSub = null;
    _dio?.close(force: true);
    _dio = null;
    _connected = false;
  }

  Future<void> disconnect() async {
    _stopped = true;
    _accessToken = null;
    _onRequest = null;
    await _closeStreamOnly();
  }
}
