import 'dart:collection';

import 'package:flutter/foundation.dart';

/// Uygulama geneli süre ölçümü — DevTools yerine debug/release log.
abstract final class AppPerfMetrics {
  static final _spans = <String, _Span>{};
  static final _completed = ListQueue<_CompletedSpan>();
  static const _maxCompleted = 200;

  static void mark(String name, {String? group}) {
    _spans[name] = _Span(name: name, group: group, started: DateTime.now());
  }

  static void end(String name, {int? statusCode}) {
    final span = _spans.remove(name);
    if (span == null) return;
    final ms = DateTime.now().difference(span.started).inMilliseconds;
    _record(_CompletedSpan(
      name: span.name,
      group: span.group,
      durationMs: ms,
      statusCode: statusCode,
    ));
    if (kDebugMode && ms > 100) {
      debugPrint('[Perf] $name ${ms}ms');
    }
  }

  static void recordApi(String path, int durationMs, {int? statusCode}) {
    _record(_CompletedSpan(
      name: path,
      group: 'api',
      durationMs: durationMs,
      statusCode: statusCode,
    ));
  }

  static void recordRoute(String from, String to, int durationMs) {
    _record(_CompletedSpan(
      name: '$from → $to',
      group: 'route',
      durationMs: durationMs,
    ));
  }

  static void _record(_CompletedSpan entry) {
    _completed.addLast(entry);
    while (_completed.length > _maxCompleted) {
      _completed.removeFirst();
    }
  }

  /// En yavaş N işlem (API + route + custom).
  static List<PerfMetricEntry> apiReport({int limit = 30}) {
    return slowest(limit: limit, group: 'api');
  }

  static String formatApiReport({int limit = 30}) {
    final items = apiReport(limit: limit);
    if (items.isEmpty) return 'Henüz API ölçümü yok.';
    final buf = StringBuffer('API yükleme süreleri (ms):\n');
    for (final e in items) {
      buf.writeln(
        '- ${e.name}: ${e.durationMs}ms'
        '${e.statusCode != null ? ' (HTTP ${e.statusCode})' : ''}',
      );
    }
    return buf.toString();
  }

  static List<PerfMetricEntry> slowest({int limit = 20, String? group}) {
    final items = group == null
        ? _completed.toList()
        : _completed.where((e) => e.group == group).toList();
    items.sort((a, b) => b.durationMs.compareTo(a.durationMs));
    return items
        .take(limit)
        .map(
          (e) => PerfMetricEntry(
            name: e.name,
            group: e.group ?? 'general',
            durationMs: e.durationMs,
            statusCode: e.statusCode,
          ),
        )
        .toList();
  }

  static void clear() => _completed.clear();
}

class PerfMetricEntry {
  const PerfMetricEntry({
    required this.name,
    required this.group,
    required this.durationMs,
    this.statusCode,
  });

  final String name;
  final String group;
  final int durationMs;
  final int? statusCode;
}

class _Span {
  _Span({required this.name, this.group, required this.started});

  final String name;
  final String? group;
  final DateTime started;
}

class _CompletedSpan {
  _CompletedSpan({
    required this.name,
    this.group,
    required this.durationMs,
    this.statusCode,
  });

  final String name;
  final String? group;
  final int durationMs;
  final int? statusCode;
}
