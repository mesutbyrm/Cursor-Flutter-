import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/live_debug_log.dart';
import '../../domain/entities/live_gift_event.dart';
import '../../domain/entities/live_stream_chat_message.dart';
import '../../../home/domain/entities/live_fortune_session_entity.dart';
import '../../../home/presentation/providers/fortune_live_event_bus.dart';
import '../datasources/live_gifts_remote_datasource.dart';

/// Video yayın SSE — `GET /api/video-streams/{streamId}/stream`.
class VideoStreamSseService {
  VideoStreamSseService(this._giftsRemote);

  final LiveGiftsRemoteDataSource _giftsRemote;

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

  String? _streamId;
  Future<String?> Function()? _accessToken;
  var _stopped = false;
  var _reconnectAttempt = 0;

  void Function()? _onConnected;
  void Function(int viewerCount)? _onViewerCount;
  void Function(LiveStreamChatMessage message)? _onMessage;
  void Function(LiveGiftEvent event)? _onGift;
  VoidCallback? _onStreamEnded;
  static const _fortuneEventTypes = {
    'fal_request',
    'live_fal_request',
    'fortune_request',
    'private_fal_request',
  };

  void Function(FortuneIncomingSession request)? _onFortuneRequest;

  static String streamUrlFor(String streamId) {
    final base = Env.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    return '$base${ApiEndpoints.videoStreamSse(streamId.trim())}';
  }

  Future<void> connect({
    required String streamId,
    required Future<String?> Function() accessToken,
    void Function()? onConnected,
    void Function(int viewerCount)? onViewerCount,
    void Function(LiveStreamChatMessage message)? onMessage,
    void Function(LiveGiftEvent event)? onGift,
    VoidCallback? onStreamEnded,
    void Function(Map<String, dynamic> battle)? onPkBattle,
    void Function(FortuneIncomingSession request)? onFortuneRequest,
  }) async {
    final id = streamId.trim();
    final same = !_stopped && _streamId == id && _bytesSub != null;
    _stopped = false;
    _streamId = id;
    _accessToken = accessToken;
    _onConnected = onConnected;
    _onViewerCount = onViewerCount;
    _onMessage = onMessage;
    _onGift = onGift;
    _onStreamEnded = onStreamEnded;
    _onPkBattle = onPkBattle;
    _onFortuneRequest = onFortuneRequest;
    if (same) return;
    LiveDebugLog.log('stream.sse.connect', {'streamId': id});
    await _openStream();
  }

  Future<void> _openStream() async {
    await _closeStreamOnly();
    final id = _streamId;
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
        ApiEndpoints.videoStreamSse(id),
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
          _drainBuffer(buffer);
        },
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
        cancelOnError: false,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Video stream SSE: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_stopped || _streamId == null) return;
    _reconnectTimer?.cancel();
    _reconnectAttempt++;
    final delay = Duration(seconds: (_reconnectAttempt.clamp(1, 6) * 2));
    _reconnectTimer = Timer(delay, () {
      if (!_stopped) unawaited(_openStream());
    });
  }

  void _drainBuffer(StringBuffer buffer) {
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
    if (block.trim() == ': heartbeat' || block.contains('heartbeat')) return;

    final dataLines = <String>[];
    for (final line in block.split('\n')) {
      if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
      }
    }
    if (dataLines.isEmpty) return;
    final payload = dataLines.join('\n').trim();
    if (payload.isEmpty) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return;
      _dispatch(Map<String, dynamic>.from(decoded));
    } catch (_) {}
  }

  void _dispatch(Map<String, dynamic> map) {
    final type = map['type']?.toString() ?? '';
    switch (type) {
      case 'connected':
        LiveDebugLog.log('stream.sse.connected', {
          'streamId': map['streamId']?.toString() ?? '',
        });
        _onConnected?.call();
        return;
      case 'viewerCount':
        final count = map['viewerCount'] ?? map['viewers'] ?? map['watching'];
        if (count is num) _onViewerCount?.call(count.round());
        return;
      case 'streamMessage':
        final raw = map['message'];
        if (raw is Map) {
          final msg = LiveStreamChatMessage.fromJson(
            Map<String, dynamic>.from(raw),
          );
          if (msg.content.isNotEmpty) _onMessage?.call(msg);
        }
        return;
      case 'gift':
        final giftRaw = map['gift'];
        if (giftRaw is Map && _streamId != null) {
          final ev = _giftsRemote.parseGiftEvent(
            Map<String, dynamic>.from(giftRaw),
            streamId: _streamId!,
          );
          if (ev != null) _onGift?.call(ev);
        }
        return;
      case 'streamEnded':
        _onStreamEnded?.call();
        return;
      case 'pk':
        final data = map['data'];
        if (data is Map) {
          _onPkBattle?.call(Map<String, dynamic>.from(data));
        }
        return;
      default:
        final typeLower = type.toLowerCase();
        if (_fortuneEventTypes.contains(typeLower)) {
          final session = parseFortuneSsePayload(map);
          if (session != null && session.sessionId.isNotEmpty) {
            _onFortuneRequest?.call(session);
          }
          return;
        }
        if (map['event']?.toString() == 'STREAM_ENDED') {
          _onStreamEnded?.call();
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
    _streamId = null;
    _accessToken = null;
    _onConnected = null;
    _onViewerCount = null;
    _onMessage = null;
    _onGift = null;
    _onStreamEnded = null;
    _onPkBattle = null;
    _onFortuneRequest = null;
    await _closeStreamOnly();
    LiveDebugLog.log('stream.sse.disconnect');
  }
}
