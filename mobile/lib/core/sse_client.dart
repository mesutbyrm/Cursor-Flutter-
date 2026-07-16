import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'config/env.dart';
import 'network/api_endpoints.dart';
import 'network/sse/sse_reconnect_policy.dart';

/// SSE olayı — `data: { "type": "...", "data": { ... } }`.
class SseEvent {
  const SseEvent({
    required this.type,
    this.data,
    this.raw,
    this.eventName,
  });

  final String type;
  final dynamic data;
  final Map<String, dynamic>? raw;
  final String? eventName;

  bool get isPing =>
      type == 'ping' || type == 'heartbeat' || type == 'connected';

  factory SseEvent.fromParsedMap(Map<String, dynamic> map, {String? eventName}) {
    final type = (map['type'] ?? eventName ?? 'message').toString();
    final payload = map.containsKey('data') ? map['data'] : map;
    return SseEvent(
      type: type,
      data: payload,
      raw: map,
      eventName: eventName,
    );
  }

  Map<String, dynamic>? get dataMap =>
      data is Map ? Map<String, dynamic>.from(data as Map) : null;
}

/// AI fal streaming parçası — `POST /api/fortunes/{type}` SSE.
class SseFortuneChunk {
  const SseFortuneChunk({
    required this.content,
    this.fortuneId,
    this.done = false,
  });

  final String content;
  final String? fortuneId;
  final bool done;
}

/// Kılavuz §5 — platform SSE uçları.
enum SseStreamKind {
  /// `GET /api/chat/rooms/{roomId}/stream`
  chatRoom,

  /// `GET /api/video-streams/{streamId}/stream`
  videoStream,

  /// `GET /api/room/{sessionId}/stream`
  fortuneSession,

  /// `GET /api/fortune-tellers/sessions/stream`
  fortuneTellerRequests,

  /// `GET /api/notifications/stream`
  notifications,
}

/// Dio [ResponseBody] ByteStream tabanlı SSE istemcisi (WebSocket değil).
///
/// - GET + `Accept: text/event-stream` + `Authorization: Bearer`
/// - Exponential backoff reconnect (max 20 deneme)
/// - 401 → token refresh → yeniden bağlan
/// - [pauseAll] / [resumeAll] — uygulama arka plan / ön plan
class SseClient {
  SseClient({
    String? baseUrl,
    required Future<String?> Function() accessToken,
    Future<bool> Function()? refreshTokens,
    Dio? dio,
  })  : _baseUrl = (baseUrl ?? Env.apiBaseUrl).replaceAll(RegExp(r'/+$'), ''),
        _accessToken = accessToken,
        _refreshTokens = refreshTokens,
        _dioFactory = dio;

  final String _baseUrl;
  final Future<String?> Function() _accessToken;
  final Future<bool> Function()? _refreshTokens;
  final Dio? _dioFactory;

  final Map<String, _SseConnection> _connections = {};
  var _paused = false;

  Stream<SseEvent> chatRoom(String roomId, {String? connectionId}) {
    final id = roomId.trim();
    return connectPath(
      ApiEndpoints.chatRoomStream(id),
      connectionId: connectionId ?? 'chat:$id',
    );
  }

  Stream<SseEvent> videoStream(String streamId, {String? connectionId}) {
    final id = streamId.trim();
    return connectPath(
      ApiEndpoints.videoStreamSse(id),
      connectionId: connectionId ?? 'video:$id',
    );
  }

  Stream<SseEvent> fortuneSession(String sessionId, {String? connectionId}) {
    final id = sessionId.trim();
    return connectPath(
      ApiEndpoints.liveFortuneRoomStream(id),
      connectionId: connectionId ?? 'fortune-session:$id',
    );
  }

  Stream<SseEvent> fortuneTellerRequests({String? connectionId}) {
    return connectPath(
      ApiEndpoints.fortuneTellerSessionsStream,
      connectionId: connectionId ?? 'fortune-teller-requests',
    );
  }

  Stream<SseEvent> notifications({String? connectionId}) {
    return connectPath(
      ApiEndpoints.notificationsStream,
      connectionId: connectionId ?? 'notifications',
    );
  }

  Stream<SseEvent> connectKind(
    SseStreamKind kind, {
    String? id,
    String? connectionId,
  }) {
    return switch (kind) {
      SseStreamKind.chatRoom => chatRoom(id ?? '', connectionId: connectionId),
      SseStreamKind.videoStream =>
        videoStream(id ?? '', connectionId: connectionId),
      SseStreamKind.fortuneSession =>
        fortuneSession(id ?? '', connectionId: connectionId),
      SseStreamKind.fortuneTellerRequests =>
        fortuneTellerRequests(connectionId: connectionId),
      SseStreamKind.notifications =>
        notifications(connectionId: connectionId),
    };
  }

  Stream<SseEvent> connectPath(
    String path, {
    String? connectionId,
    bool requiresAuth = true,
  }) {
    final connId = connectionId ?? path;
    _connections[connId]?.close();

    final controller = StreamController<SseEvent>.broadcast();
    final connection = _SseConnection(
      baseUrl: _baseUrl,
      path: path,
      requiresAuth: requiresAuth,
      accessToken: _accessToken,
      refreshTokens: _refreshTokens,
      dioFactory: _dioFactory,
      controller: controller,
      onClosed: () => _connections.remove(connId),
    );
    _connections[connId] = connection;
    if (!_paused) {
      unawaited(connection.start());
    }
    return controller.stream;
  }

  void disconnect(String connectionId) {
    _connections.remove(connectionId)?.close();
  }

  void disconnectAll() {
    for (final c in _connections.values.toList()) {
      c.close();
    }
    _connections.clear();
  }

  void pauseAll() {
    _paused = true;
    for (final c in _connections.values) {
      c.close(keepSlot: true);
    }
  }

  void resumeAll() {
    _paused = false;
    for (final c in _connections.values) {
      unawaited(c.start());
    }
  }

  /// `POST /api/fortunes/{type}` — `Content-Type: text/event-stream` ise parça parça parse.
  Stream<SseFortuneChunk> fortuneReadingStream({
    required String fortuneType,
    required Map<String, dynamic> body,
    String? accessToken,
  }) {
    final controller = StreamController<SseFortuneChunk>();
    final cancel = CancelToken();
    final dio = _dioFactory ?? _createStreamDio();

    unawaited(
      _pumpFortunePost(
        dio: dio,
        cancel: cancel,
        path: ApiEndpoints.fortuneReading(fortuneType),
        body: body,
        accessToken: accessToken,
        tokenResolver: _accessToken,
        controller: controller,
      ),
    );

    controller.onCancel = () {
      if (!cancel.isCancelled) cancel.cancel('listener_cancelled');
      dio.close(force: true);
    };

    return controller.stream;
  }

  static SseEvent? parseBlock(String block) {
    final map = parseSseJsonBlock(block);
    if (map == null) return null;
    return SseEvent.fromParsedMap(map);
  }

  static Map<String, dynamic>? parseSseJsonBlock(String block) {
    String? eventName;
    final dataLines = <String>[];
    for (final line in block.split('\n')) {
      if (line.startsWith('event:')) {
        eventName = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
      }
    }
    if (dataLines.isEmpty) return null;
    final payload = dataLines.join('\n').trim();
    if (payload.isEmpty || payload == '[DONE]') return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      if (eventName != null && map['type'] == null) {
        map['type'] = eventName;
      }
      return map;
    } catch (_) {
      return {
        'type': eventName ?? 'message',
        'data': payload,
      };
    }
  }

  static void drainBuffer(
    StringBuffer buffer,
    void Function(String block) onBlock,
  ) {
    var raw = buffer.toString().replaceAll('\r\n', '\n');
    while (true) {
      final sep = raw.indexOf('\n\n');
      if (sep < 0) break;
      final block = raw.substring(0, sep);
      raw = raw.substring(sep + 2);
      onBlock(block);
    }
    buffer
      ..clear()
      ..write(raw);
  }

  static Dio _createStreamDio() {
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

  static Future<void> _pumpFortunePost({
    required Dio dio,
    required CancelToken cancel,
    required String path,
    required Map<String, dynamic> body,
    required StreamController<SseFortuneChunk> controller,
    String? accessToken,
    Future<String?> Function()? tokenResolver,
  }) async {
    try {
      var token = accessToken?.trim();
      token ??= tokenResolver != null ? await tokenResolver() : null;
      final headers = <String, dynamic>{
        'Accept': 'text/event-stream',
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final res = await dio.post<ResponseBody>(
        path,
        data: body,
        options: Options(
          responseType: ResponseType.stream,
          headers: headers,
        ),
        cancelToken: cancel,
      );

      final contentType =
          res.headers.value('content-type')?.toLowerCase() ?? '';
      final byteStream = res.data?.stream;
      if (byteStream == null) {
        throw StateError('Boş fal stream yanıtı');
      }

      if (contentType.contains('text/event-stream')) {
        await _parseFortuneSseBytes(byteStream, controller, cancel);
        return;
      }

      final bytes = await byteStream.fold<List<int>>(
        <int>[],
        (prev, chunk) => prev..addAll(chunk),
      );
      if (cancel.isCancelled) return;
      final text = utf8.decode(bytes, allowMalformed: true);
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        final nested = map['data'] is Map
            ? Map<String, dynamic>.from(map['data'] as Map)
            : map;
        final content = (nested['detail'] ??
                nested['interpretation'] ??
                nested['content'] ??
                nested['text'])
            ?.toString();
        if (content != null && content.isNotEmpty) {
          controller.add(
            SseFortuneChunk(
              content: content,
              fortuneId: nested['id']?.toString(),
              done: true,
            ),
          );
        }
      }
    } catch (e, st) {
      if (!controller.isClosed && !cancel.isCancelled) {
        controller.addError(e, st);
      }
    } finally {
      if (!controller.isClosed) await controller.close();
      dio.close(force: true);
    }
  }

  static Future<void> _parseFortuneSseBytes(
    Stream<List<int>> byteStream,
    StreamController<SseFortuneChunk> controller,
    CancelToken cancel,
  ) async {
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
        final map = parseSseJsonBlock(block);
        if (map == null) continue;
        final type = map['type']?.toString() ?? '';
        if (type == 'done') {
          fortuneId = map['fortuneId']?.toString();
          controller.add(
            SseFortuneChunk(
              content: acc.toString(),
              fortuneId: fortuneId,
              done: true,
            ),
          );
          return;
        }
        final nested = map['data'];
        final piece = (nested is Map
                ? nested['content'] ?? nested['text']
                : map['content'])
            ?.toString() ??
            '';
        if (piece.isNotEmpty) {
          acc.write(piece);
          controller.add(SseFortuneChunk(content: acc.toString()));
        }
      }
      buffer
        ..clear()
        ..write(raw);
    }

    if (acc.isNotEmpty && !controller.isClosed) {
      controller.add(
        SseFortuneChunk(
          content: acc.toString(),
          fortuneId: fortuneId,
          done: true,
        ),
      );
    }
  }
}

class _SseConnection {
  _SseConnection({
    required this.baseUrl,
    required this.path,
    required this.requiresAuth,
    required this.accessToken,
    required this.refreshTokens,
    required this.controller,
    required this.onClosed,
    this.dioFactory,
  });

  final String baseUrl;
  final String path;
  final bool requiresAuth;
  final Future<String?> Function() accessToken;
  final Future<bool> Function()? refreshTokens;
  final StreamController<SseEvent> controller;
  final VoidCallback onClosed;
  final Dio? dioFactory;

  Dio? _dio;
  CancelToken? _cancel;
  StreamSubscription<List<int>>? _bytesSub;
  Timer? _reconnectTimer;
  var _active = true;
  var _keepSlot = false;
  var _attempt = 0;

  Future<void> start() async {
    _active = true;
    _keepSlot = false;
    _attempt = 0;
    await _connect();
  }

  void close({bool keepSlot = false}) {
    _keepSlot = keepSlot;
    _active = false;
    _reconnectTimer?.cancel();
    _cancel?.cancel('close');
    _bytesSub?.cancel();
    _dio?.close(force: true);
    if (!keepSlot) {
      if (!controller.isClosed) controller.close();
      onClosed();
    }
  }

  Future<void> _connect() async {
    if (!_active) return;
    await _bytesSub?.cancel();
    _cancel?.cancel('reconnect');
    _dio?.close(force: true);

    final token = await accessToken();
    if (requiresAuth && (token == null || token.trim().isEmpty)) {
      _scheduleReconnect();
      return;
    }

    final headers = <String, dynamic>{
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
    };
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    _dio = dioFactory ?? SseClient._createStreamDio();
    _dio!.options.baseUrl = baseUrl;
    _cancel = CancelToken();

    try {
      final res = await _dio!.get<ResponseBody>(
        path,
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

      _attempt = 0;
      final buffer = StringBuffer();
      _bytesSub = byteStream.listen(
        (chunk) {
          buffer.write(utf8.decode(chunk, allowMalformed: true));
          SseClient.drainBuffer(buffer, _onBlock);
        },
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: false,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && refreshTokens != null) {
        final ok = await refreshTokens!();
        if (ok) {
          await _connect();
          return;
        }
      }
      _scheduleReconnect();
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onBlock(String block) {
    final event = SseClient.parseBlock(block);
    if (event == null || event.isPing) return;
    if (!controller.isClosed) controller.add(event);
  }

  void _scheduleReconnect() {
    if (!_active || _keepSlot) return;
    _reconnectTimer?.cancel();
    _attempt++;
    if (SseReconnectPolicy.shouldGiveUp(_attempt)) {
      if (!controller.isClosed) {
        controller.addError(StateError('SSE max reconnect attempts'));
        controller.close();
      }
      onClosed();
      return;
    }
    final delay = SseReconnectPolicy.delayForAttempt(_attempt);
    _reconnectTimer = Timer(delay, () {
      if (_active) unawaited(_connect());
    });
  }
}

/// `WidgetsBindingObserver` — arka planda SSE kapat, ön planda yeniden aç.
class SseClientLifecycleBinding with WidgetsBindingObserver {
  SseClientLifecycleBinding(this.client);

  final SseClient client;
  var _attached = false;

  void attach() {
    if (_attached) return;
    WidgetsBinding.instance.addObserver(this);
    _attached = true;
  }

  void dispose() {
    if (_attached) {
      WidgetsBinding.instance.removeObserver(this);
      _attached = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        client.pauseAll();
      case AppLifecycleState.resumed:
        client.resumeAll();
    }
  }
}
