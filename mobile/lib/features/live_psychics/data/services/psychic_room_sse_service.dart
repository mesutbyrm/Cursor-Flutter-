import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/sse/base_sse_service.dart';
import '../../../../core/network/sse/sse_reconnect_policy.dart';
import '../../domain/entities/psychic_room_entity.dart';
import '../../domain/entities/psychic_session_status.dart';
import '../../domain/session_room_sse_event.dart';
import 'psychic_room_sse_parser.dart';

/// Seans oda SSE — `GET /api/room/{sessionId}/stream`.
class PsychicRoomSseService {
  PsychicRoomSseService();

  Dio? _dio;
  CancelToken? _cancel;
  StreamSubscription<List<int>>? _bytesSub;
  Timer? _reconnectTimer;
  Timer? _heartbeatWatchdog;
  DateTime? _lastEventAt;
  String? _sessionId;
  String? _myUserId;
  Future<String?> Function()? _accessToken;
  Future<bool> Function()? _refreshTokens;
  void Function()? _onConnected;
  void Function(PsychicChatMessage message)? _onMessage;
  void Function(PsychicRoomEntity room)? _onRoomUpdate;
  void Function(PsychicSessionStatus status)? _onSessionEnded;
  void Function(int amount, String? fromName)? _onTipReceived;
  void Function()? _onFailed;
  var _stopped = false;
  var _reconnectAttempt = 0;

  Future<void> connect({
    required String sessionId,
    required Future<String?> Function() accessToken,
    Future<bool> Function()? refreshTokens,
    String? myUserId,
    void Function()? onConnected,
    void Function(PsychicChatMessage message)? onMessage,
    void Function(PsychicRoomEntity room)? onRoomUpdate,
    void Function(PsychicSessionStatus status)? onSessionEnded,
    void Function(int amount, String? fromName)? onTipReceived,
    void Function()? onFailed,
  }) async {
    final id = sessionId.trim();
    if (id.isEmpty) return;
    _stopped = false;
    _sessionId = id;
    _myUserId = myUserId;
    _accessToken = accessToken;
    _refreshTokens = refreshTokens;
    _onConnected = onConnected;
    _onMessage = onMessage;
    _onRoomUpdate = onRoomUpdate;
    _onSessionEnded = onSessionEnded;
    _onTipReceived = onTipReceived;
    _onFailed = onFailed;
    await _openStream();
  }

  /// SSE yeniden bağlanmayı dene (kullanıcı «Yenile» veya give-up sonrası).
  Future<void> retryConnection() async {
    if (_stopped) return;
    _reconnectAttempt = 0;
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
    _dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: Duration.zero,
    ));
    _cancel = CancelToken();
    try {
      final res = await _dio!.get<ResponseBody>(
        ApiEndpoints.liveFortuneRoomStream(id),
        options: Options(responseType: ResponseType.stream, headers: headers),
        cancelToken: _cancel,
      );
      final stream = res.data?.stream;
      if (stream == null) {
        _scheduleReconnect();
        return;
      }
      _reconnectAttempt = 0;
      _lastEventAt = DateTime.now();
      _startHeartbeatWatchdog();
      _onConnected?.call();
      final buffer = StringBuffer();
      _bytesSub = stream.listen(
        (chunk) {
          _lastEventAt = DateTime.now();
          buffer.write(utf8.decode(chunk, allowMalformed: true));
          _drain(buffer);
        },
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
        cancelOnError: false,
      );
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('PsychicRoomSse: $e');
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
      if (kDebugMode) debugPrint('PsychicRoomSse: $e');
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
    if (isSessionRoomSseCommentBlock(block)) return;

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
      if (decoded is! Map) return;
      final map = Map<String, dynamic>.from(decoded);
      final event = parseSessionRoomSsePayload(
        map,
        eventName: eventName,
        sessionId: _sessionId ?? '',
        myUserId: _myUserId,
      );
      if (event == null) return;
      switch (event) {
        case PsychicRoomSseConnected(:final room):
        case PsychicRoomSseRoomUpdate(:final room):
          _onRoomUpdate?.call(room);
        case PsychicRoomSseSessionEnded(:final status):
          _onSessionEnded?.call(status);
        case PsychicRoomSseMessage(:final message):
          _onMessage?.call(message);
        case PsychicRoomSseTip(:final amount, :final fromName):
          _onTipReceived?.call(amount, fromName);
      }
    } catch (_) {}
  }

  void _startHeartbeatWatchdog() {
    _heartbeatWatchdog?.cancel();
    _heartbeatWatchdog = Timer.periodic(const Duration(seconds: 5), (_) {
      final last = _lastEventAt;
      if (last == null || _stopped) return;
      if (DateTime.now().difference(last) > BaseSseService.heartbeatTimeout) {
        if (kDebugMode) {
          debugPrint('PsychicRoomSse: heartbeat timeout — reconnecting');
        }
        unawaited(_openStream());
      }
    });
  }

  void _scheduleReconnect() {
    if (_stopped) return;
    if (SseReconnectPolicy.shouldGiveUp(_reconnectAttempt)) {
      if (kDebugMode) {
        debugPrint('PsychicRoomSse: max reconnect attempts reached');
      }
      _onFailed?.call();
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
    _reconnectTimer?.cancel();
    _heartbeatWatchdog?.cancel();
    _heartbeatWatchdog = null;
    _cancel?.cancel();
    await _bytesSub?.cancel();
    _dio?.close(force: true);
  }

  Future<void> disconnect() async {
    _stopped = true;
    _refreshTokens = null;
    await _closeStreamOnly();
  }
}
