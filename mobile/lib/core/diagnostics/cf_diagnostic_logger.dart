import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cf_diag.dart';
import 'cf_resource_tracker.dart';

/// Anlık dosya log seviyeleri (CfDiag ile ayrı).
enum CfFileLogLevel {
  debug,
  info,
  warning,
  error,
  critical,
  freeze,
  leak,
  timeout,
  duplicate,
}

enum CfFileLogCategory {
  timer,
  polling,
  request,
  sse,
  trtc,
  session,
  screen,
  ui,
  network,
  resource,
  exception,
  system,
}

/// Gerçek cihazda kullanım sırasında dosyaya yazan tanılama logger.
abstract final class CfDiagnosticLogger {
  static const _prefsFileLog = 'cf_diag_file_logging';
  static const _flushEveryLines = 40;
  static const _flushInterval = Duration(seconds: 2);
  static const _actionBufferMax = 100;
  static const _recentEventsMax = 80;

  static final fileLoggingEnabled = ValueNotifier<bool>(false);
  static final ValueNotifier<int> revision = ValueNotifier(0);

  static String? sessionId;
  static Directory? _sessionDir;
  static File? _logFile;
  static final _buffer = <String>[];
  static Timer? _flushTimer;
  static var _lineCount = 0;

  static final _actions = <String>[];
  static final _errors = <Map<String, Object?>>[];
  static final _recentEvents = <Map<String, String>>[];
  static final _requestsInflight = <String, _ReqMeta>{};
  static final _requestDedupe = <String, List<DateTime>>{};
  static final _activePollByEndpoint = <String, List<String>>{};
  static final _activeTimerByPurpose = <String, List<String>>{};
  static var _reqSeq = 0;

  static bool get active =>
      fileLoggingEnabled.value ||
      const bool.fromEnvironment('CANLIFAL_DIAG_FILE', defaultValue: false);

  static Future<void> loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final on = prefs.getBool(_prefsFileLog) ?? false;
      fileLoggingEnabled.value = on;
      if (on) await startSession();
    } catch (_) {}
  }

  static Future<void> setFileLogging(bool on) async {
    fileLoggingEnabled.value = on;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsFileLog, on);
    } catch (_) {}
    if (on) {
      await startSession();
    } else {
      await flush(force: true);
    }
    revision.value++;
  }

  static Future<void> startSession() async {
    if (kIsWeb) return;
    await flush(force: true);
    final now = DateTime.now();
    final rand = Random().nextInt(0xFFFF).toRadixString(16).toUpperCase();
    sessionId =
        'DIAG-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}-'
        '$rand';
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/diagnostics/session_${_dirStamp(now)}');
    await dir.create(recursive: true);
    _sessionDir = dir;
    _logFile = File('${dir.path}/canlifal_diagnostic.log');
    _buffer.clear();
    _lineCount = 0;
    _errors.clear();
    _actions.clear();
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) => unawaited(flush()));
    log(
      level: CfFileLogLevel.info,
      category: CfFileLogCategory.system,
      message: 'Diagnostic session started',
      metadata: {'sessionId': sessionId, 'platform': Platform.operatingSystem},
    );
    revision.value++;
  }

  static String _dirStamp(DateTime t) =>
      '${t.year}${t.month.toString().padLeft(2, '0')}${t.day.toString().padLeft(2, '0')}_'
      '${t.hour.toString().padLeft(2, '0')}${t.minute.toString().padLeft(2, '0')}${t.second.toString().padLeft(2, '0')}';

  static String newTraceId() {
    final n = Random().nextInt(0xFFFFFF).toRadixString(16).toUpperCase();
    return 'CF-$n';
  }

  static void log({
    required CfFileLogLevel level,
    required CfFileLogCategory category,
    required String message,
    String? action,
    String? traceId,
    Map<String, Object?> metadata = const {},
  }) {
    if (!active && level.index < CfFileLogLevel.warning.index) return;
    if (!active && level == CfFileLogLevel.debug) return;

    final line = _formatLine(
      level: level,
      category: category,
      message: message,
      action: action ?? CfDiag.lastAction,
      traceId: traceId,
      metadata: metadata,
    );
    _buffer.add(line);
    _lineCount++;
    _pushAction('${category.name.toUpperCase()} ${action ?? ''} $message'.trim());
    _recentEvents.add({
      'at': DateTime.now().toIso8601String(),
      'level': level.name,
      'category': category.name,
      'message': message.length > 160 ? '${message.substring(0, 160)}…' : message,
    });
    while (_recentEvents.length > _recentEventsMax) {
      _recentEvents.removeAt(0);
    }

    if (level.index >= CfFileLogLevel.error.index) {
      _errors.add({
        'at': DateTime.now().toIso8601String(),
        'level': level.name,
        'category': category.name,
        'screen': CfDiag.screen,
        'action': action ?? CfDiag.lastAction,
        'traceId': traceId,
        'message': message,
        'metadata': metadata,
      });
    }

    if (_isCritical(level)) {
      unawaited(_writeCriticalSnapshot(level, message, traceId));
      unawaited(flush(force: true));
    } else if (_buffer.length >= _flushEveryLines) {
      unawaited(flush());
    }
    revision.value++;
  }

  static bool _isCritical(CfFileLogLevel level) =>
      level == CfFileLogLevel.critical ||
      level == CfFileLogLevel.freeze ||
      level == CfFileLogLevel.leak ||
      level == CfFileLogLevel.duplicate ||
      level == CfFileLogLevel.timeout;

  static String _formatLine({
    required CfFileLogLevel level,
    required CfFileLogCategory category,
    required String message,
    String? action,
    String? traceId,
    Map<String, Object?> metadata = const {},
  }) {
    final ts = DateTime.now().toIso8601String();
    final screen = CfDiag.screen ?? '-';
    final meta = metadata.isEmpty
        ? ''
        : '\n${metadata.entries.map((e) => '${e.key}=${_sanitizeMeta(e.value)}').join('\n')}';
    return '[$ts]\n'
        '[${level.name.toUpperCase()}]\n'
        '[${category.name.toUpperCase()}]\n'
        '[$screen]\n'
        '[${action ?? CfDiag.lastAction ?? '-'}]\n'
        '[${traceId ?? '-'}]\n'
        '$message$meta\n';
  }

  static Object? _sanitizeMeta(Object? v) {
    if (v is String) return CfDiag.sanitizeText(v);
    return v;
  }

  static void _pushAction(String line) {
    _actions.add('${DateTime.now().toIso8601String()} $line');
    while (_actions.length > _actionBufferMax) {
      _actions.removeAt(0);
    }
  }

  static Map<String, Object?> resourceSnapshot() {
    final s = CfResourceTracker.snapshot();
    return {
      'timers': s.activeTimers,
      'pollers': s.activePollers,
      'sse': s.activeSse,
      'trtc': s.activeTrtc,
      'requests': s.activeRequests,
      'subscriptions': s.activeSubscriptions,
      'pendingOps': CfDiag.pendingOps,
    };
  }

  static Future<void> _writeCriticalSnapshot(
    CfFileLogLevel level,
    String message,
    String? traceId,
  ) async {
    final snap = resourceSnapshot();
    log(
      level: CfFileLogLevel.info,
      category: CfFileLogCategory.resource,
      message: 'CRITICAL_SNAPSHOT',
      traceId: traceId,
      metadata: {
        ...snap,
        'triggerLevel': level.name,
        'triggerMessage': message,
        'lastActions': _actions.take(30).join(' | '),
      },
    );
  }

  static void screenLifecycle(String phase, {String? route}) {
    final name = route ?? CfDiag.screen ?? '-';
    log(
      level: CfFileLogLevel.info,
      category: CfFileLogCategory.screen,
      message: 'SCREEN_$phase',
      action: phase,
      metadata: {'route': name},
    );
    if (phase == 'EXIT' || phase == 'DISPOSE') {
      final snap = resourceSnapshot();
      final suspicious = (snap['timers'] as int? ?? 0) > 2 ||
          (snap['pollers'] as int? ?? 0) > 1 ||
          (snap['sse'] as int? ?? 0) > 1;
      if (suspicious) {
        log(
          level: CfFileLogLevel.leak,
          category: CfFileLogCategory.resource,
          message: 'LEAK_SUSPECTED after screen $phase',
          metadata: snap,
        );
      }
    }
  }

  static void onResourceEvent(
    String event,
    CfResourceKind kind,
    String id,
    String module,
    String label,
  ) {
    final cat = switch (kind) {
      CfResourceKind.timer => CfFileLogCategory.timer,
      CfResourceKind.poller => CfFileLogCategory.polling,
      CfResourceKind.sse => CfFileLogCategory.sse,
      CfResourceKind.trtc => CfFileLogCategory.trtc,
      CfResourceKind.request => CfFileLogCategory.request,
      CfResourceKind.subscription => CfFileLogCategory.resource,
    };
    log(
      level: CfFileLogLevel.debug,
      category: cat,
      message: '${kind.name.toUpperCase()}_$event id=$id module=$module label=$label',
      metadata: {'resourceId': id, 'module': module, 'label': label},
    );
    if (event == 'CREATE' && kind == CfResourceKind.timer) {
      final key = '$module::$label';
      final list = _activeTimerByPurpose.putIfAbsent(key, () => []);
      if (list.isNotEmpty) {
        log(
          level: CfFileLogLevel.duplicate,
          category: CfFileLogCategory.timer,
          message: 'DUPLICATE_TIMER purpose=$label',
          metadata: {'existing': list.join(','), 'new': id},
        );
      }
      list.add(id);
    }
    if ((event == 'DISPOSE' || event == 'CANCEL') && kind == CfResourceKind.timer) {
      final key = '$module::$label';
      _activeTimerByPurpose[key]?.remove(id);
    }
    if (event == 'CREATE' && kind == CfResourceKind.poller) {
      final ep = label;
      final list = _activePollByEndpoint.putIfAbsent(ep, () => []);
      if (list.isNotEmpty) {
        log(
          level: CfFileLogLevel.critical,
          category: CfFileLogCategory.polling,
          message: 'POLLING_DUPLICATE endpoint=$ep',
          metadata: {'active': list.join(','), 'new': id},
        );
      }
      list.add(id);
    }
    if ((event == 'DISPOSE' || event == 'CANCEL') && kind == CfResourceKind.poller) {
      for (final list in _activePollByEndpoint.values) {
        list.remove(id);
      }
    }
    if (event == 'CREATE' &&
        (kind == CfResourceKind.sse || kind == CfResourceKind.trtc)) {
      final snap = CfResourceTracker.snapshot(module: module);
      final count =
          kind == CfResourceKind.sse ? snap.activeSse : snap.activeTrtc;
      if (count > 1) {
        log(
          level: CfFileLogLevel.critical,
          category: kind == CfResourceKind.sse
              ? CfFileLogCategory.sse
              : CfFileLogCategory.trtc,
          message: kind == CfResourceKind.sse
              ? 'DUPLICATE_SSE'
              : 'DUPLICATE_TRTC',
          metadata: {
            'module': module,
            'activeCount': count,
            'newId': id,
            'label': label,
          },
        );
      }
    }
    if (event == 'CREATE' && kind == CfResourceKind.timer) {
      final active = CfResourceTracker.snapshot(module: module).activeTimers;
      if (active > 4 && module == 'live_fortune') {
        log(
          level: CfFileLogLevel.leak,
          category: CfFileLogCategory.timer,
          message: 'TIMER_COUNT_HIGH module=$module count=$active',
          metadata: {'label': label, 'id': id},
        );
      }
    }
  }

  static String requestStart({
    required String method,
    required String endpoint,
    String? traceId,
  }) {
    _reqSeq++;
    final id = 'REQ-$_reqSeq';
    final trackerId = CfResourceTracker.create(
      CfResourceKind.request,
      module: 'http',
      label: '$method $endpoint',
      traceId: traceId,
    );
    _requestsInflight[id] = _ReqMeta(
      id: id,
      trackerId: trackerId,
      method: method,
      endpoint: endpoint,
      started: DateTime.now(),
      traceId: traceId,
    );
    log(
      level: CfFileLogLevel.info,
      category: CfFileLogCategory.request,
      message: 'REQUEST_START',
      traceId: traceId,
      metadata: {
        'requestId': id,
        'method': method,
        'endpoint': _safePath(endpoint),
      },
    );
    _trackDuplicateRequest(endpoint, id);
    return id;
  }

  static void requestEnd(
    String requestId, {
    int? statusCode,
    bool success = true,
    bool timeout = false,
    bool cancelled = false,
    Object? error,
  }) {
    final meta = _requestsInflight.remove(requestId);
    if (meta == null) return;
    final ms = DateTime.now().difference(meta.started).inMilliseconds;
    CfResourceTracker.markDisposed(meta.trackerId, reason: 'http_end');
    log(
      level: timeout
          ? CfFileLogLevel.timeout
          : (success ? CfFileLogLevel.info : CfFileLogLevel.error),
      category: CfFileLogCategory.request,
      message: 'REQUEST_END',
      traceId: meta.traceId,
      metadata: {
        'requestId': requestId,
        'durationMs': ms,
        'status': statusCode,
        'success': success,
        'timeout': timeout,
        'cancelled': cancelled,
        if (error != null) 'error': CfDiag.sanitizeText('$error'),
      },
    );
  }

  static void _trackDuplicateRequest(String endpoint, String requestId) {
    final key = '${CfDiag.lastAction ?? '-'}::$endpoint';
    final now = DateTime.now();
    final list = _requestDedupe.putIfAbsent(key, () => []);
    list.removeWhere((t) => now.difference(t).inMilliseconds > 800);
    list.add(now);
    if (list.length > 1 && (CfDiag.lastAction?.isNotEmpty ?? false)) {
      log(
        level: CfFileLogLevel.critical,
        category: CfFileLogCategory.request,
        message: 'DUPLICATE_REQUEST',
        metadata: {
          'requestCount': list.length,
          'expected': 1,
          'endpoint': _safePath(endpoint),
          'userAction': CfDiag.lastAction,
          'requestId': requestId,
        },
      );
    }
  }

  static String _safePath(String path) {
    var p = path.split('?').first;
    if (p.length > 120) p = '${p.substring(0, 120)}…';
    return CfDiag.sanitizeText(p);
  }

  static void sseEvent(String event, {Map<String, Object?> metadata = const {}}) {
    log(
      level: event.contains('ERROR')
          ? CfFileLogLevel.error
          : CfFileLogLevel.info,
      category: CfFileLogCategory.sse,
      message: 'SSE_$event',
      metadata: metadata,
    );
  }

  static void trtcEvent(String event, {Map<String, Object?> metadata = const {}}) {
    final safe = Map<String, Object?>.from(metadata)
      ..remove('userSig')
      ..remove('token')
      ..remove('accessToken');
    log(
      level: event.contains('error') || event.contains('ERROR')
          ? CfFileLogLevel.error
          : CfFileLogLevel.info,
      category: CfFileLogCategory.trtc,
      message: 'TRTC_${event.toUpperCase()}',
      metadata: safe,
    );
  }

  static void sessionEvent({
    required String type,
    required String sessionKey,
    required String state,
    Map<String, Object?> metadata = const {},
  }) {
    log(
      level: CfFileLogLevel.info,
      category: CfFileLogCategory.session,
      message: 'SESSION type=$type state=$state sessionId=$sessionKey',
      metadata: metadata,
    );
  }

  static void freezeDetected(Duration duration) {
    log(
      level: CfFileLogLevel.freeze,
      category: CfFileLogCategory.ui,
      message: 'UI FREEZE duration=${duration.inMilliseconds}ms',
      metadata: {
        ...resourceSnapshot(),
        'jankFrames': CfFrameMonitorRef.janky,
        'worstFrameMs': CfFrameMonitorRef.worstMs,
      },
    );
  }

  static void exception(Object error, StackTrace stack, {String? traceId}) {
    log(
      level: CfFileLogLevel.error,
      category: CfFileLogCategory.exception,
      message: 'type=${error.runtimeType} message=${CfDiag.sanitizeText('$error')}',
      traceId: traceId,
      metadata: {
        'stackTrace': stack.toString(),
        'screen': CfDiag.screen,
      },
    );
    unawaited(flush(force: true));
  }

  static Future<void> flush({bool force = false}) async {
    if (kIsWeb || _logFile == null) return;
    if (_buffer.isEmpty && !force) return;
    try {
      final chunk = List<String>.from(_buffer);
      _buffer.clear();
      await _logFile!.writeAsString(chunk.join(), mode: FileMode.append);
      if (force || _errors.isNotEmpty) {
        await _writeSidecars();
      }
    } catch (_) {}
  }

  static Future<void> _writeSidecars() async {
    final dir = _sessionDir;
    if (dir == null) return;
    final summary = {
      'sessionId': sessionId,
      'updatedAt': DateTime.now().toIso8601String(),
      'resources': resourceSnapshot(),
      'errors': _errors.length,
      'actions': _actions.length,
    };
    await File('${dir.path}/summary.json')
        .writeAsString(const JsonEncoder.withIndent('  ').convert(summary));
    await File('${dir.path}/errors.json')
        .writeAsString(const JsonEncoder.withIndent('  ').convert(_errors));
  }

  static Directory? get sessionDirectory => _sessionDir;
  static File? get logFile => _logFile;
  static List<String> get lastActions => List.unmodifiable(_actions);
  static List<Map<String, Object?>> get errors => List.unmodifiable(_errors);
  static List<Map<String, String>> get recentEvents =>
      List.unmodifiable(_recentEvents);

  @visibleForTesting
  static void resetForTest() {
    _buffer.clear();
    _errors.clear();
    _actions.clear();
    _requestsInflight.clear();
    sessionId = null;
    _sessionDir = null;
    _logFile = null;
  }
}

class _ReqMeta {
  _ReqMeta({
    required this.id,
    required this.trackerId,
    required this.method,
    required this.endpoint,
    required this.started,
    this.traceId,
  });
  final String id;
  final String trackerId;
  final String method;
  final String endpoint;
  final DateTime started;
  final String? traceId;
}

/// cf_monitors döngüsünden jank sayıları (import döngüsü önleme).
abstract final class CfFrameMonitorRef {
  static int janky = 0;
  static int worstMs = 0;
}
