import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/live_fortune_session_entity.dart';
import '../../presentation/providers/fortune_live_event_bus.dart';

/// Falcı — `GET /api/chat/rooms/{roomId}/stream` üzerinden canlı fal SSE.
class LiveFortuneRequestSseService {
  LiveFortuneRequestSseService();

  static const _fortuneEventTypes = {
    'fal_request',
    'live_fal_request',
    'fortune_request',
    'private_fal_request',
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

  String? _roomId;
  Future<String?> Function()? _accessToken;
  void Function(FortuneIncomingSession request)? _onRequest;
  var _stopped = false;
  var _reconnectAttempt = 0;

  static String streamUrlFor(String roomId) {
    final base = Env.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    return '$base${ApiEndpoints.chatRoomStream(roomId.trim())}';
  }

  Future<void> connect({
    required String roomId,
    required Future<String?> Function() accessToken,
    required void Function(FortuneIncomingSession request) onRequest,
  }) async {
    final id = roomId.trim();
    if (id.isEmpty) return;
    final sameRoom = !_stopped && _roomId == id && _bytesSub != null;
    _stopped = false;
    _roomId = id;
    _accessToken = accessToken;
    _onRequest = onRequest;
    if (sameRoom) return;
    await _openStream();
  }

  Future<void> _openStream() async {
    await _closeStreamOnly();
    final id = _roomId;
    if (id == null || id.isEmpty || _stopped) return;

    final token = _accessToken != null ? await _accessToken!() : null;
    final headers = <String, dynamic>{
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
    };
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    _dio = _sseDio();
    _cancel = CancelToken();
    try {
      final res = await _dio!.get<ResponseBody>(
        ApiEndpoints.chatRoomStream(id),
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
      if (kDebugMode) debugPrint('Live fal SSE bağlantı hatası: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_stopped || _roomId == null) return;
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

    debugPrint('SSE EVENT: $payload');

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return;
      final map = Map<String, dynamic>.from(decoded);
      _dispatchFortuneEvent(map, eventName);
    } catch (_) {}
  }

  void _dispatchFortuneEvent(Map<String, dynamic> map, String? sseEventName) {
    final typeRaw = (map['type'] ?? sseEventName ?? '').toString().toLowerCase();
    if (!_fortuneEventTypes.contains(typeRaw)) return;

    final session = _mapSseFortuneRequest(map);
    if (session.sessionId.isEmpty) return;
    _onRequest?.call(session);
  }

  FortuneIncomingSession _mapSseFortuneRequest(Map<String, dynamic> map) {
    return parseFortuneSsePayload(map) ??
        const FortuneIncomingSession(
          sessionId: '',
          clientId: '',
          clientName: '',
          tellerId: '',
          durationMinutes: 0,
          totalJeton: 0,
          category: '',
        );
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
  }

  Future<void> disconnect() async {
    _stopped = true;
    _roomId = null;
    _accessToken = null;
    _onRequest = null;
    await _closeStreamOnly();
  }
}
