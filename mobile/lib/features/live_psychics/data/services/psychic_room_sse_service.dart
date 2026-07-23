import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/sse/sse_reconnect_policy.dart';
import '../../domain/entities/psychic_room_entity.dart';
import '../../domain/entities/psychic_session_status.dart';
import '../models/psychic_model.dart';

/// Seans oda SSE — `GET /api/room/{sessionId}/stream`.
class PsychicRoomSseService {
  PsychicRoomSseService();

  Dio? _dio;
  CancelToken? _cancel;
  StreamSubscription<List<int>>? _bytesSub;
  Timer? _reconnectTimer;
  String? _sessionId;
  String? _myUserId;
  Future<String?> Function()? _accessToken;
  void Function()? _onConnected;
  void Function(PsychicChatMessage message)? _onMessage;
  void Function(PsychicRoomEntity room)? _onRoomUpdate;
  void Function(PsychicSessionStatus status)? _onSessionEnded;
  void Function(int amount, String? fromName)? _onTipReceived;
  var _stopped = false;
  var _reconnectAttempt = 0;

  Future<void> connect({
    required String sessionId,
    required Future<String?> Function() accessToken,
    String? myUserId,
    void Function()? onConnected,
    void Function(PsychicChatMessage message)? onMessage,
    void Function(PsychicRoomEntity room)? onRoomUpdate,
    void Function(PsychicSessionStatus status)? onSessionEnded,
    void Function(int amount, String? fromName)? onTipReceived,
  }) async {
    final id = sessionId.trim();
    if (id.isEmpty) return;
    _stopped = false;
    _sessionId = id;
    _myUserId = myUserId;
    _accessToken = accessToken;
    _onConnected = onConnected;
    _onMessage = onMessage;
    _onRoomUpdate = onRoomUpdate;
    _onSessionEnded = onSessionEnded;
    _onTipReceived = onTipReceived;
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
      _onConnected?.call();
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
      final type = (map['type'] ?? eventName ?? '').toString().toLowerCase();
      if (type == 'ended' ||
          type == 'session_ended' ||
          type == 'session_end' ||
          type == 'expired' ||
          type == 'session_expired' ||
          type == 'cancelled' ||
          type == 'session_cancelled' ||
          type == 'rejected') {
        _onSessionEnded?.call(
          type.contains('cancel') || type == 'rejected'
              ? PsychicSessionStatus.cancelled
              : type.contains('expir')
                  ? PsychicSessionStatus.expired
                  : PsychicSessionStatus.ended,
        );
        return;
      }
      if (type == 'tip' ||
          type == 'tip_received' ||
          type == 'bahsis' ||
          type == 'tip_sent' ||
          type == 'gift' ||
          type == 'gift_received' ||
          type == 'gift_sent' ||
          type == 'hediye' ||
          type.contains('gift') ||
          type.contains('hediye') ||
          (eventName?.toLowerCase().contains('gift') ?? false) ||
          (eventName?.toLowerCase().contains('tip') ?? false)) {
        final amount = _parseTipAmount(map);
        if (amount > 0) {
          final from = map['senderName']?.toString() ??
              map['clientName']?.toString() ??
              map['fromName']?.toString();
          _onTipReceived?.call(amount, from);
        }
        return;
      }
      if (type == 'timer_started' || type == 'time_extended') {
        final room = PsychicModel.roomFromJson(
          map['room'] is Map
              ? Map<String, dynamic>.from(map['room'] as Map)
              : map,
          fallbackId: _sessionId ?? '',
        );
        _onRoomUpdate?.call(room);
        return;
      }
      final msg = PsychicModel.chatFromJson(map, myUserId: _myUserId);
      if (msg.text.trim().isNotEmpty) {
        _onMessage?.call(msg);
        return;
      }
      final room = PsychicModel.roomFromJson(
        map['room'] is Map
            ? Map<String, dynamic>.from(map['room'] as Map)
            : map,
        fallbackId: _sessionId ?? '',
      );
      if (room.status == PsychicSessionStatus.cancelled ||
          room.status == PsychicSessionStatus.rejected ||
          room.status == PsychicSessionStatus.ended ||
          room.status == PsychicSessionStatus.expired) {
        _onSessionEnded?.call(room.status);
        return;
      }
      _onRoomUpdate?.call(room);
    } catch (_) {}
  }

  int _parseTipAmount(Map<String, dynamic> map) {
    final raw = map['amount'] ??
        map['jeton'] ??
        map['tipAmount'] ??
        map['giftValue'] ??
        map['coins'] ??
        map['coin'] ??
        map['price'] ??
        map['value'];
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  void _scheduleReconnect() {
    if (_stopped) return;
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
    _cancel?.cancel();
    await _bytesSub?.cancel();
    _dio?.close(force: true);
  }

  Future<void> disconnect() async {
    _stopped = true;
    await _closeStreamOnly();
  }
}
