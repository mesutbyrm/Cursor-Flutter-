import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hata/olay kategorileri.
enum CfCategory {
  auth,
  network,
  fortune,
  live,
  voice,
  trtc,
  sse,
  pk,
  gift,
  profile,
  databaseApi,
  ui,
  unknown;

  String get label => switch (this) {
        CfCategory.databaseApi => 'DATABASE_API',
        _ => name.toUpperCase(),
      };
}

enum CfLevel { info, warn, error }

class CfDiagEntry {
  CfDiagEntry({
    required this.category,
    required this.level,
    required this.message,
    this.data = const {},
    this.traceId,
    DateTime? at,
  }) : at = at ?? DateTime.now();

  final CfCategory category;
  final CfLevel level;
  final String message;
  final Map<String, Object?> data;
  final String? traceId;
  final DateTime at;
}

/// Canlifal Performance & Diagnostics — merkezi, hafif, bellek içi kayıt.
///
/// Üretimde: yalnızca sınırlı halka tampon (diske yazmaz, konsola basmaz,
/// kare başına işlem yapmaz). Kare/donma izleyicileri yalnızca [verbose]
/// açıkken (debug veya tanılama ekranından açılınca) çalışır.
abstract final class CfDiag {
  static const _prefsKey = 'cf_diag_verbose';
  static const maxEntries = 300;

  static final _entries = ListQueue<CfDiagEntry>();
  static final _listeners = <VoidCallback>[];
  static final _pending = <String, DateTime>{};

  /// Tanılama izleyicileri (kare + donma) çalışsın mı.
  static final ValueNotifier<bool> verbose = ValueNotifier<bool>(kDebugMode);

  /// Son kullanıcı eylemi (ör. SEND_FORTUNE_REQUEST) ve aktif ekran adı.
  static String? lastAction;
  static String? screen;

  /// Seans oda SSE'sinden son gelen olay (heartbeat dahil) — kendi kendine
  /// tanıda «Heartbeat» kontrolü için. Seans yokken null.
  static DateTime? lastRoomSseEventAt;

  static const _secretKeyParts = [
    'token',
    'jwt',
    'password',
    'authorization',
    'usersig',
    'secret',
    'cookie',
    'apikey',
    'api_key',
    'email',
    'phone',
  ];

  static Future<void> loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_prefsKey) == true) verbose.value = true;
    } catch (_) {}
  }

  static Future<void> setVerbose(bool value) async {
    verbose.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (_) {}
  }

  static List<CfDiagEntry> get entries => List.unmodifiable(_entries);

  static List<CfDiagEntry> byCategories(Set<CfCategory> cats) =>
      _entries.where((e) => cats.contains(e.category)).toList(growable: false);

  static void addListener(VoidCallback l) => _listeners.add(l);
  static void removeListener(VoidCallback l) => _listeners.remove(l);

  static void record(
    CfCategory category,
    String message, {
    CfLevel level = CfLevel.info,
    Map<String, Object?>? data,
    String? traceId,
  }) {
    final entry = CfDiagEntry(
      category: category,
      level: level,
      message: sanitizeText(message),
      data: sanitize(data),
      traceId: traceId,
    );
    _entries.addLast(entry);
    while (_entries.length > maxEntries) {
      _entries.removeFirst();
    }
    if (kDebugMode) {
      final extra = entry.data.isEmpty
          ? ''
          : ' ${entry.data.entries.map((e) => '${e.key}=${e.value}').join(' ')}';
      debugPrint(
        '[CF ${category.label}] ${traceId != null ? '$traceId ' : ''}'
        '${entry.message}$extra',
      );
    }
    for (final l in List.of(_listeners)) {
      l();
    }
  }

  /// Hata kaydı + kategori tespiti. Asla fırlatmaz.
  static void recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    CfCategory? category,
    String? traceId,
  }) {
    try {
      final cat = category ?? categorize(error, stack);
      record(
        cat,
        '${fatal ? 'FATAL ' : ''}${error.runtimeType}: '
        '${_short(error.toString())}',
        level: CfLevel.error,
        traceId: traceId,
        data: {if (stack != null) 'at': _firstAppFrame(stack)},
      );
    } catch (_) {}
  }

  /// Çalışan işlem kaydı — donma raporunda «Pending API» olarak görünür.
  static void beginPending(String name) => _pending[name] = DateTime.now();
  static void endPending(String name) => _pending.remove(name);
  static List<String> get pendingOps => _pending.entries
      .map((e) =>
          '${e.key} (${DateTime.now().difference(e.value).inMilliseconds} ms)')
      .toList(growable: false);

  @visibleForTesting
  static void resetForTest() {
    _entries.clear();
    _pending.clear();
    _listeners.clear();
    lastAction = null;
    screen = null;
  }

  // ---- Kategori tespiti ----------------------------------------------------

  static CfCategory categorize(Object error, [StackTrace? stack]) {
    if (error is DioException) {
      final p = error.requestOptions.path.toLowerCase();
      final byPath = _byText(p);
      if (error.response?.statusCode == 401) return CfCategory.auth;
      if (byPath != CfCategory.unknown) return byPath;
      return switch (error.type) {
        DioExceptionType.badResponse => CfCategory.databaseApi,
        _ => CfCategory.network,
      };
    }
    if (error is TimeoutException) {
      final t = _byText('${error.message ?? ''} ${stack ?? ''}');
      return t == CfCategory.unknown ? CfCategory.network : t;
    }
    if (error is FormatException) return CfCategory.databaseApi;
    final text = '${error.toString()} ${stack ?? ''}';
    final byText = _byText(text);
    if (byText != CfCategory.unknown) return byText;
    if (error is FlutterError) return CfCategory.ui;
    if (error is TypeError) return CfCategory.databaseApi;
    return CfCategory.unknown;
  }

  static CfCategory _byText(String raw) {
    final t = raw.toLowerCase();
    if (t.contains('trtc')) return CfCategory.trtc;
    if (RegExp(r'\bsse\b|eventsource|text/event-stream|_sse|sse_')
        .hasMatch(t)) {
      return CfCategory.sse;
    }
    if (t.contains('psychic') ||
        t.contains('fortune') ||
        t.contains('canli-falcilar') ||
        t.contains('/falci')) {
      return CfCategory.fortune;
    }
    if (t.contains('voice') || t.contains('chat/rooms')) return CfCategory.voice;
    if (RegExp(r'\bpk\b|pk_|/pk').hasMatch(t)) return CfCategory.pk;
    if (t.contains('gift') || t.contains('hediye')) return CfCategory.gift;
    if (t.contains('/live') || t.contains('livestream')) return CfCategory.live;
    if (t.contains('profile') || t.contains('/api/me')) return CfCategory.profile;
    if (t.contains('jwt') ||
        t.contains('unauthorized') ||
        t.contains('/auth/') ||
        t.contains('mobile-login') ||
        t.contains('mobile-refresh')) {
      return CfCategory.auth;
    }
    return CfCategory.unknown;
  }

  // ---- Gizlilik ------------------------------------------------------------

  /// Gizli anahtarları atar; JWT benzeri/uzun dizeleri maskeler.
  static Map<String, Object?> sanitize(Map<String, Object?>? data) {
    if (data == null || data.isEmpty) return const {};
    final out = <String, Object?>{};
    for (final e in data.entries) {
      final k = e.key.toLowerCase();
      if (_secretKeyParts.any(k.contains)) continue;
      final v = e.value;
      out[e.key] = v is String ? sanitizeText(v) : v;
    }
    return out;
  }

  static final _jwtLike = RegExp(r'eyJ[A-Za-z0-9_-]{6,}\.[A-Za-z0-9_-]{6,}');
  static final _bearer = RegExp(r'bearer\s+\S+', caseSensitive: false);

  static String sanitizeText(String s) {
    var out = s.replaceAll(_jwtLike, '[jwt]').replaceAll(_bearer, 'Bearer [x]');
    if (out.length > 300) out = '${out.substring(0, 300)}…';
    return out;
  }

  static String _short(String s) =>
      s.length > 220 ? '${s.substring(0, 220)}…' : s;

  static String _firstAppFrame(StackTrace stack) {
    for (final line in stack.toString().split('\n')) {
      if (line.contains('package:canlifal_social')) {
        return line.trim().replaceAll('package:canlifal_social/', '');
      }
    }
    return '';
  }
}
