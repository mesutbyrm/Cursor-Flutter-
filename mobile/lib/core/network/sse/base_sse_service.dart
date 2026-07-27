import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../config/env.dart';
import 'sse_reconnect_policy.dart';

/// Ortak SSE altyapısı — auth, reconnect, heartbeat, ağ kurtarma, yaşam döngüsü.
abstract class BaseSseService {
  BaseSseService({SseStatusController? statusController})
      : status = statusController ?? SseStatusController();

  final SseStatusController status;

  Dio? _dio;
  CancelToken? _cancel;
  StreamSubscription<List<int>>? _bytesSub;
  Timer? _reconnectTimer;
  Timer? _heartbeatWatchdog;

  Future<String?> Function()? _accessToken;
  Future<bool> Function()? _refreshTokens;
  var _stopped = true;
  var _reconnectAttempt = 0;
  String? _lastEventId;
  DateTime? _lastEventAt;

  /// Son SSE `id:` — reconnect'te Last-Event-ID olarak gönderilir.
  String? get lastEventId => _lastEventId;

  static const heartbeatTimeout = Duration(seconds: 20);

  static Dio createSseDio() {
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

  /// Alt sınıflar farklı origin kullanabilir (ör. PK → games backend).
  Dio connectionDio() => createSseDio();

  /// Alt sınıf SSE path'ini döner (ör. `/api/chat/rooms/{id}/stream`).
  String streamPath();

  /// İsteğe bağlı — auth zorunlu mu?
  bool get requiresAuth => true;

  /// Alt sınıf her SSE bloğunu işler.
  void onSseBlock(String block);

  /// Bağlantı kurulduğunda (HTTP 200 + stream açıldı).
  void onStreamOpened() {}

  /// Yeniden bağlanmadan önce.
  void onReconnecting(int attempt) {}

  /// Alt sınıflar token ile bağlantı açar.
  ///
  /// [refreshTokens]: 401 alındığında JWT yenilemek için (kılavuz §6).
  Future<void> openConnection({
    required Future<String?> Function() accessToken,
    Future<bool> Function()? refreshTokens,
  }) async {
    _stopped = false;
    _accessToken = accessToken;
    _refreshTokens = refreshTokens;
    await _openStream();
  }

  Future<void> disconnect() async {
    _stopped = true;
    _accessToken = null;
    _refreshTokens = null;
    await _closeStreamOnly();
    status.emit(
      const SseConnectionStatus(phase: SseConnectionPhase.idle),
    );
  }

  /// Ağ geri geldiğinde veya manuel yenileme — backoff sıfırlanır.
  Future<void> reconnectNow() async {
    if (_stopped || _accessToken == null) return;
    _reconnectAttempt = 0;
    await _openStream();
  }

  void dispose() {
    unawaited(disconnect());
    status.dispose();
  }

  Future<void> _openStream() async {
    await _closeStreamOnly();
    if (_stopped) return;

    status.emit(
      SseConnectionStatus(
        phase: _reconnectAttempt > 0
            ? SseConnectionPhase.reconnecting
            : SseConnectionPhase.connecting,
        attempt: _reconnectAttempt,
      ),
    );

    final token = _accessToken != null ? await _accessToken!() : null;
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
    final lastId = _lastEventId?.trim();
    if (lastId != null && lastId.isNotEmpty) {
      headers['Last-Event-ID'] = lastId;
    }

    _dio = connectionDio();
    _cancel = CancelToken();
    try {
      final res = await _dio!.get<ResponseBody>(
        streamPath(),
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
      onStreamOpened();
      status.emit(
        const SseConnectionStatus(phase: SseConnectionPhase.connected),
      );

      final buffer = StringBuffer();
      _bytesSub = byteStream.listen(
        (chunk) {
          _lastEventAt = DateTime.now();
          buffer.write(utf8.decode(chunk, allowMalformed: true));
          drainSseBuffer(buffer, (block) {
            final eventId = parseSseEventId(block);
            if (eventId != null && eventId.isNotEmpty) {
              _lastEventId = eventId;
            }
            onSseBlock(block);
          });
        },
        onError: (Object e) {
          status.emit(
            SseConnectionStatus(
              phase: SseConnectionPhase.reconnecting,
              attempt: _reconnectAttempt,
              lastError: e,
            ),
          );
          _scheduleReconnect();
        },
        onDone: () => _scheduleReconnect(),
        cancelOnError: false,
      );
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('$runtimeType SSE: $e');
      // Kılavuz §6: 401 → refresh sonra yeniden bağlan.
      if (e.response?.statusCode == 401 && _refreshTokens != null) {
        final ok = await _refreshTokens!.call();
        if (!ok) {
          status.emit(
            SseConnectionStatus(
              phase: SseConnectionPhase.failed,
              attempt: _reconnectAttempt,
              lastError: e,
            ),
          );
          return;
        }
      }
      status.emit(
        SseConnectionStatus(
          phase: SseConnectionPhase.reconnecting,
          attempt: _reconnectAttempt,
          lastError: e,
        ),
      );
      _scheduleReconnect();
    } catch (e) {
      if (kDebugMode) debugPrint('$runtimeType SSE: $e');
      status.emit(
        SseConnectionStatus(
          phase: SseConnectionPhase.reconnecting,
          attempt: _reconnectAttempt,
          lastError: e,
        ),
      );
      _scheduleReconnect();
    }
  }

  void _startHeartbeatWatchdog() {
    _heartbeatWatchdog?.cancel();
    _heartbeatWatchdog = Timer.periodic(const Duration(seconds: 5), (_) {
      final last = _lastEventAt;
      if (last == null || _stopped) return;
      if (DateTime.now().difference(last) > heartbeatTimeout) {
        if (kDebugMode) {
          debugPrint('$runtimeType: heartbeat timeout — reconnecting');
        }
        unawaited(_openStream());
      }
    });
  }

  void _scheduleReconnect() {
    if (_stopped) return;
    _reconnectTimer?.cancel();
    _reconnectAttempt++;
    if (SseReconnectPolicy.shouldGiveUp(_reconnectAttempt)) {
      status.emit(
        SseConnectionStatus(
          phase: SseConnectionPhase.failed,
          attempt: _reconnectAttempt,
        ),
      );
      return;
    }
    final delay = SseReconnectPolicy.delayForAttempt(_reconnectAttempt);
    onReconnecting(_reconnectAttempt);
    status.emit(
      SseConnectionStatus(
        phase: SseConnectionPhase.reconnecting,
        attempt: _reconnectAttempt,
      ),
    );
    _reconnectTimer = Timer(delay, () {
      if (!_stopped) unawaited(_openStream());
    });
  }

  Future<void> _closeStreamOnly() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _heartbeatWatchdog?.cancel();
    _heartbeatWatchdog = null;
    _cancel?.cancel('reconnect');
    _cancel = null;
    await _bytesSub?.cancel();
    _bytesSub = null;
    _dio?.close(force: true);
    _dio = null;
  }

  /// SSE buffer ayrıştırma — alt sınıflar da kullanabilir.
  static void drainSseBuffer(
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

  /// SSE bloğundaki `id:` satırı.
  static String? parseSseEventId(String block) {
    for (final line in block.split('\n')) {
      if (line.startsWith('id:')) {
        return line.substring(3).trim();
      }
    }
    return null;
  }

  /// `data:` satırlarından JSON map çıkarır.
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
      return {'content': payload, 'type': ?eventName};
    }
  }
}
