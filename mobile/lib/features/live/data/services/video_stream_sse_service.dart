import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/live_debug_log.dart';
import '../../../../core/network/sse/sse_reconnect_policy.dart';
import '../../../gifts/presentation/sync/gift_sync_log.dart';
import '../../domain/entities/live_gift_event.dart';
import '../../domain/entities/live_stream_chat_message.dart';
import '../../../live_psychics/domain/entities/psychic_request_entity.dart';
import '../../../live_psychics/presentation/providers/psychic_live_event_bus.dart';
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
        headers: {
          'Accept': 'text/event-stream',
          'Connection': 'keep-alive',
        },
        persistentConnection: true,
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
  String? _lastEventId;

  void Function()? _onConnected;
  void Function(int viewerCount)? _onViewerCount;
  void Function(LiveStreamChatMessage message)? _onMessage;
  void Function(LiveGiftEvent event)? _onGift;
  VoidCallback? _onStreamEnded;
  void Function(Map<String, dynamic> battle)? _onPkBattle;

  void Function(int likeCount)? _onLike;
  void Function(Map<String, dynamic> user)? _onUserJoined;
  void Function(String userId)? _onUserLeft;
  void Function(String userId, bool isModerator)? _onModeratorUpdated;
  static const _fortuneEventTypes = {
    'fal_request',
    'live_fal_request',
    'fortune_request',
    'private_fal_request',
  };

  void Function(PsychicRequestEntity request)? _onFortuneRequest;
  void Function(Map<String, dynamic> request)? _onStreamFortuneRequest;

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
    void Function(PsychicRequestEntity request)? onFortuneRequest,
    void Function(Map<String, dynamic> request)? onStreamFortuneRequest,
    void Function(int likeCount)? onLike,
    void Function(Map<String, dynamic> user)? onUserJoined,
    void Function(String userId)? onUserLeft,
    void Function(String userId, bool isModerator)? onModeratorUpdated,
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
    _onStreamFortuneRequest = onStreamFortuneRequest;
    _onLike = onLike;
    _onUserJoined = onUserJoined;
    _onUserLeft = onUserLeft;
    _onModeratorUpdated = onModeratorUpdated;
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
      'Connection': 'keep-alive',
    };
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }
    final lastId = _lastEventId?.trim();
    if (lastId != null && lastId.isNotEmpty) {
      headers['Last-Event-ID'] = lastId;
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
    if (_reconnectAttempt >= SseReconnectPolicy.maxAttempts) return;
    _reconnectTimer?.cancel();
    _reconnectAttempt++;
    final delay = SseReconnectPolicy.delayForAttempt(_reconnectAttempt);
    GiftSyncLog.sseReconnect(_streamId!, _reconnectAttempt, delay.inMilliseconds);
    _reconnectTimer = Timer(delay, () {
      if (!_stopped) unawaited(_openStream());
    });
  }

  /// Anında yeniden bağlan.
  Future<void> reconnectNow() async {
    if (_stopped || _streamId == null) return;
    _reconnectTimer?.cancel();
    _reconnectAttempt = 0;
    await _openStream();
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
    final eventId = _parseEventId(block);
    if (eventId != null && eventId.isNotEmpty) {
      _lastEventId = eventId;
    }

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

  String? _parseEventId(String block) {
    for (final line in block.split('\n')) {
      if (line.startsWith('id:')) {
        return line.substring(3).trim();
      }
    }
    return null;
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
      case 'giftsent':
      case 'gift_sent':
        final giftRaw = map['gift'] ?? map['data'] ?? map;
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
      case 'pkbattle':
      case 'pk_battle':
        final data = map['data'] ?? map['battle'] ?? map['pk'] ?? map;
        if (data is Map) {
          _onPkBattle?.call(Map<String, dynamic>.from(data));
        }
        return;
      case 'like':
      case 'streamLike':
        final count = map['likeCount'] ?? map['count'] ?? map['total'];
        if (count is num) _onLike?.call(count.round());
        return;
      case 'userJoined':
      case 'viewerJoined':
        final user = map['user'] ?? map;
        if (user is Map) {
          _onUserJoined?.call(Map<String, dynamic>.from(user));
        }
        return;
      case 'userLeft':
      case 'viewerLeft':
        final userId = map['userId']?.toString() ?? map['id']?.toString() ?? '';
        if (userId.isNotEmpty) _onUserLeft?.call(userId);
        return;
      case 'moderatorAdded':
        final addedId = map['userId']?.toString() ?? '';
        if (addedId.isNotEmpty) _onModeratorUpdated?.call(addedId, true);
        return;
      case 'moderatorRemoved':
        final removedId = map['userId']?.toString() ?? '';
        if (removedId.isNotEmpty) _onModeratorUpdated?.call(removedId, false);
        return;
      default:
        final typeLower = type.toLowerCase();
        if (_fortuneEventTypes.contains(typeLower)) {
          _onStreamFortuneRequest?.call(map);
          final session = parsePsychicSsePayload(map);
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
    _onStreamFortuneRequest = null;
    _onLike = null;
    _onUserJoined = null;
    _onUserLeft = null;
    _onModeratorUpdated = null;
    await _closeStreamOnly();
    LiveDebugLog.log('stream.sse.disconnect');
  }

  Future<void> _closeStreamOnly() async {
    _reconnectTimer?.cancel();
    await _bytesSub?.cancel();
    _bytesSub = null;
    _cancel?.cancel('sse_close');
    _cancel = null;
    _dio?.close(force: true);
    _dio = null;
  }

  void dispose() {
    unawaited(disconnect());
  }
}
