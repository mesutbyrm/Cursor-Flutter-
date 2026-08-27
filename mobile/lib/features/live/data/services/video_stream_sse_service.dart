import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/live_debug_log.dart';
import '../../../../core/network/sse/sse_reconnect_policy.dart';
import '../../../gifts/presentation/sync/gift_sync_log.dart';
import '../../../gifts/domain/gift_payload_util.dart';
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
  Timer? _heartbeatWatchdog;
  DateTime? _lastEventAt;

  String? _streamId;
  Future<String?> Function()? _accessToken;
  var _stopped = false;
  var _paused = false;
  var _reconnectAttempt = 0;
  String? _lastEventId;

  void Function()? _onConnected;
  void Function(int viewerCount)? _onViewerCount;
  void Function(LiveStreamChatMessage message)? _onMessage;
  void Function(Map<String, dynamic> payload)? _onGift;
  VoidCallback? _onStreamEnded;
  void Function(Map<String, dynamic> battle)? _onPkBattle;

  void Function(int likeCount)? _onLike;
  void Function(Map<String, dynamic> user)? _onUserJoined;
  void Function(String userId)? _onUserLeft;
  void Function(String userId, bool isModerator)? _onModeratorUpdated;
  void Function(Map<String, dynamic> payload)? _onGuest;
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
    void Function(Map<String, dynamic> payload)? onGift,
    VoidCallback? onStreamEnded,
    void Function(Map<String, dynamic> battle)? onPkBattle,
    void Function(PsychicRequestEntity request)? onFortuneRequest,
    void Function(Map<String, dynamic> request)? onStreamFortuneRequest,
    void Function(int likeCount)? onLike,
    void Function(Map<String, dynamic> user)? onUserJoined,
    void Function(String userId)? onUserLeft,
    void Function(String userId, bool isModerator)? onModeratorUpdated,
    void Function(Map<String, dynamic> payload)? onGuest,
  }) async {
    final id = streamId.trim();
    final same = !_stopped && !_paused && _streamId == id && _bytesSub != null;
    _stopped = false;
    _paused = false;
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
    _onGuest = onGuest;
    if (same) return;
    LiveDebugLog.log('stream.sse.connect', {'streamId': id});
    await _openStream();
  }

  Future<void> _openStream() async {
    await _closeStreamOnly();
    final id = _streamId;
    if (id == null || id.isEmpty || _stopped || _paused) return;

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
      _lastEventAt = DateTime.now();
      _startHeartbeatWatchdog();
      final buffer = StringBuffer();
      _bytesSub = byteStream.listen(
        (chunk) {
          _lastEventAt = DateTime.now();
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
    if (_stopped || _paused || _streamId == null) return;
    if (_reconnectAttempt >= SseReconnectPolicy.maxAttempts) return;
    _reconnectTimer?.cancel();
    _reconnectAttempt++;
    final delay = SseReconnectPolicy.delayForAttempt(_reconnectAttempt);
    GiftSyncLog.sseReconnect(_streamId!, _reconnectAttempt, delay.inMilliseconds);
    _reconnectTimer = Timer(delay, () {
      if (!_stopped && !_paused) unawaited(_openStream());
    });
  }

  /// Anında yeniden bağlan.
  Future<void> reconnectNow() async {
    if (_stopped || _paused || _streamId == null) return;
    _reconnectTimer?.cancel();
    _reconnectAttempt = 0;
    await _openStream();
  }

  Future<void> pauseForBackground() async {
    if (_stopped || _streamId == null) return;
    _paused = true;
    await _closeStreamOnly();
  }

  Future<void> resumeFromBackground() async {
    if (!_paused) return;
    _paused = false;
    if (_stopped || _streamId == null) return;
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
      case 'gift_received':
      case 'gift_queue_updated':
      case 'gift_finished':
      case 'giftsentevent':
        _onGift?.call(GiftPayloadUtil.unwrap(map));
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
      case 'guest':
      case 'guest_joined':
      case 'guestJoined':
      case 'GUEST_JOINED':
      case 'guest_left':
      case 'guestLeft':
      case 'GUEST_LEFT':
      case 'guest_update':
        _onGuest?.call(map);
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
          return;
        }
        if (GiftPayloadUtil.looksLikeGift(map)) {
          _onGift?.call(GiftPayloadUtil.unwrap(map));
        }
    }
  }

  Future<void> disconnect() async {
    _stopped = true;
    _paused = false;
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
    _onGuest = null;
    await _closeStreamOnly();
    LiveDebugLog.log('stream.sse.disconnect');
  }

  void _startHeartbeatWatchdog() {
    _heartbeatWatchdog?.cancel();
    _heartbeatWatchdog = Timer.periodic(const Duration(seconds: 5), (_) {
      final last = _lastEventAt;
      if (last == null || _stopped || _paused) return;
      if (DateTime.now().difference(last) >
          const Duration(seconds: 45)) {
        if (kDebugMode) {
          debugPrint('VideoStreamSseService: heartbeat timeout — reconnecting');
        }
        unawaited(_openStream());
      }
    });
  }

  Future<void> _closeStreamOnly() async {
    _reconnectTimer?.cancel();
    _heartbeatWatchdog?.cancel();
    _heartbeatWatchdog = null;
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
