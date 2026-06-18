import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/live_fortune_room_sse_event.dart';
import '../../domain/entities/live_fortune_session_entity.dart';
import 'live_fortune_room_sse_mapper.dart';

/// Canlı fal seans odası — `GET /api/room/{sessionId}/stream` (SSE).
///
/// Üretim prompt §9–11: mesaj, timer, durum güncellemeleri; poll yedek kalır.
class LiveFortuneRoomSseService {
  LiveFortuneRoomSseService();

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

  String? _sessionId;
  String? _myUserId;
  Future<String?> Function()? _accessToken;
  void Function()? _onConnected;
  void Function(TellerChatMessage message)? _onMessage;
  void Function(LiveFortuneRoomInfo room)? _onRoomUpdate;
  void Function(FortuneSessionStatusResult status)? _onSessionUpdate;
  void Function({String? endedBy})? _onSessionEnded;
  var _stopped = false;
  var _reconnectAttempt = 0;

  static String streamUrlFor(String sessionId) {
    final base = Env.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    return '$base${ApiEndpoints.liveFortuneRoomStream(sessionId.trim())}';
  }

  Future<void> connect({
    required String sessionId,
    required Future<String?> Function() accessToken,
    String? myUserId,
    void Function()? onConnected,
    void Function(TellerChatMessage message)? onMessage,
    void Function(LiveFortuneRoomInfo room)? onRoomUpdate,
    void Function(FortuneSessionStatusResult status)? onSessionUpdate,
    void Function({String? endedBy})? onSessionEnded,
  }) async {
    final id = sessionId.trim();
    if (id.isEmpty) return;
    final sameSession = !_stopped && _sessionId == id && _bytesSub != null;
    _stopped = false;
    _sessionId = id;
    _myUserId = myUserId;
    _accessToken = accessToken;
    _onConnected = onConnected;
    _onMessage = onMessage;
    _onRoomUpdate = onRoomUpdate;
    _onSessionUpdate = onSessionUpdate;
    _onSessionEnded = onSessionEnded;
    if (sameSession) return;
    await _openStream();
  }

  Future<void> _openStream() async {
    await _closeStreamOnly();
    final id = _sessionId;
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
        ApiEndpoints.liveFortuneRoomStream(id),
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
      if (kDebugMode) debugPrint('Live fortune room SSE: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_stopped || _sessionId == null) return;
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
      _dispatchEvent(Map<String, dynamic>.from(decoded), eventName);
    } catch (_) {}
  }

  void _dispatchEvent(Map<String, dynamic> map, String? sseEventName) {
    final kind = liveFortuneRoomSseKindFrom(
      map['type']?.toString() ?? sseEventName,
    );
    final sessionId = _sessionId ?? '';

    switch (kind) {
      case LiveFortuneRoomSseKind.connected:
        _onConnected?.call();
        return;
      case LiveFortuneRoomSseKind.message:
        final msg = LiveFortuneRoomSseMapper.parseMessage(
          map,
          myUserId: _myUserId,
        );
        if (msg != null) _onMessage?.call(msg);
        return;
      case LiveFortuneRoomSseKind.messages:
        for (final msg in LiveFortuneRoomSseMapper.parseMessages(
          map,
          myUserId: _myUserId,
        )) {
          _onMessage?.call(msg);
        }
        return;
      case LiveFortuneRoomSseKind.timerStarted:
      case LiveFortuneRoomSseKind.roomUpdate:
        final room = LiveFortuneRoomSseMapper.parseRoomInfo(
          map,
          fallbackSessionId: sessionId,
        );
        if (room != null) _onRoomUpdate?.call(room);
        return;
      case LiveFortuneRoomSseKind.sessionUpdate:
        final status = LiveFortuneRoomSseMapper.parseSessionStatus(
          map,
          fallbackSessionId: sessionId,
        );
        if (status != null) _onSessionUpdate?.call(status);
        final room = LiveFortuneRoomSseMapper.parseRoomInfo(
          map,
          fallbackSessionId: sessionId,
        );
        if (room != null) _onRoomUpdate?.call(room);
        return;
      case LiveFortuneRoomSseKind.sessionEnded:
        final endedBy = map['endedBy']?.toString();
        _onSessionEnded?.call(endedBy: endedBy);
        return;
      case LiveFortuneRoomSseKind.unknown:
        if (map.containsKey('message') || map.containsKey('content')) {
          final msg = LiveFortuneRoomSseMapper.parseMessage(
            map,
            myUserId: _myUserId,
          );
          if (msg != null) {
            _onMessage?.call(msg);
            return;
          }
        }
        if (map.containsKey('timerStarted') ||
            map.containsKey('timerStartedAt') ||
            map.containsKey('maxMinutes')) {
          final room = LiveFortuneRoomSseMapper.parseRoomInfo(
            map,
            fallbackSessionId: sessionId,
          );
          if (room != null) {
            _onRoomUpdate?.call(room);
            return;
          }
        }
        if (map.containsKey('status') || map.containsKey('tellerResponse')) {
          final status = LiveFortuneRoomSseMapper.parseSessionStatus(
            map,
            fallbackSessionId: sessionId,
          );
          if (status != null) _onSessionUpdate?.call(status);
        }
    }
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
    _sessionId = null;
    _myUserId = null;
    _accessToken = null;
    _onConnected = null;
    _onMessage = null;
    _onRoomUpdate = null;
    _onSessionUpdate = null;
    _onSessionEnded = null;
    await _closeStreamOnly();
  }
}
