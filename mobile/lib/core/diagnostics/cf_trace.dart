import 'dart:async';

import 'package:flutter/foundation.dart';

import 'cf_diag.dart';

class CfTraceStep {
  const CfTraceStep(this.name, this.ms, {this.failed = false});
  final String name;
  final int ms;
  final bool failed;
}

/// Kritik işlem izi — aynı [traceId] altında API / seans / TRTC / SSE / UI
/// adımları ve süreleri toplanır.
///
/// ```
/// final t = CfTrace.start('FORTUNE_REQUEST', CfCategory.fortune);
/// await t.timed('API createSession', () => repo.createSession(...));
/// t.finish();
/// ```
class CfTrace {
  CfTrace._(this.action, this.category, this.traceId)
      : _startedAt = DateTime.now(),
        _lastMark = DateTime.now();

  static const maxKept = 40;
  static var _seq = 0;
  static final _recent = <CfTrace>[];

  static List<CfTrace> get recent => List.unmodifiable(_recent.reversed);

  final String action;
  final CfCategory category;
  final String traceId;
  final DateTime _startedAt;
  DateTime _lastMark;
  final steps = <CfTraceStep>[];
  String? outcome;
  int? totalMs;

  bool get finished => totalMs != null;

  static CfTrace start(String action, CfCategory category) {
    _seq++;
    final id = 'CF-TRACE-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}'
        '${_seq.toRadixString(36)}';
    final t = CfTrace._(action, category, id);
    CfDiag.lastAction = action;
    _recent.add(t);
    while (_recent.length > maxKept) {
      _recent.removeAt(0);
    }
    CfDiag.record(category, '$action start', traceId: id);
    return t;
  }

  /// Önceki adımdan bu yana geçen süreyi adıma yazar.
  void step(String name, {bool failed = false}) {
    final now = DateTime.now();
    steps.add(CfTraceStep(
      name,
      now.difference(_lastMark).inMilliseconds,
      failed: failed,
    ));
    _lastMark = now;
  }

  /// Asenkron bir adımı ölçer; hata olsa da süre kaydedilir.
  Future<T> timed<T>(String name, Future<T> Function() body) async {
    final opName = '$action/$name';
    CfDiag.beginPending(opName);
    final sw = Stopwatch()..start();
    try {
      final r = await body();
      steps.add(CfTraceStep(name, sw.elapsedMilliseconds));
      _lastMark = DateTime.now();
      return r;
    } catch (_) {
      steps.add(CfTraceStep(name, sw.elapsedMilliseconds, failed: true));
      _lastMark = DateTime.now();
      rethrow;
    } finally {
      CfDiag.endPending(opName);
    }
  }

  void finish({String? outcome}) {
    if (finished) return;
    this.outcome = outcome;
    totalMs = DateTime.now().difference(_startedAt).inMilliseconds;
    final summary = format();
    CfDiag.record(
      category,
      '$action done ${totalMs}ms${outcome != null ? ' ($outcome)' : ''}',
      level: totalMs! > 3000 ? CfLevel.warn : CfLevel.info,
      traceId: traceId,
    );
    if (kDebugMode) debugPrint(summary);
  }

  String format() {
    final b = StringBuffer('$action  $traceId\n');
    for (final s in steps) {
      b.writeln('  ${s.name}: ${s.ms} ms${s.failed ? '  ✗' : ''}');
    }
    b.write('  TOTAL: ${totalMs ?? DateTime.now().difference(_startedAt).inMilliseconds} ms');
    if (outcome != null) b.write('  [$outcome]');
    return b.toString();
  }

  @visibleForTesting
  static void resetForTest() {
    _recent.clear();
    _seq = 0;
  }
}

/// Aynı anda tek çalışan asenkron iş (çift tıklama / çift istek koruması).
/// Çalışırken gelen çağrı yeni iş başlatmaz; mevcut işin sonucunu paylaşır.
class CfSingleFlight<T> {
  Future<T>? _inFlight;

  bool get running => _inFlight != null;

  Future<T> run(Future<T> Function() body) {
    final current = _inFlight;
    if (current != null) return current;
    final f = body().whenComplete(() => _inFlight = null);
    _inFlight = f;
    return f;
  }
}
