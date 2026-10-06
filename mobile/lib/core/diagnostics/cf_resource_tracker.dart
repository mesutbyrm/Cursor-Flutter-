import 'dart:async';

import 'package:flutter/foundation.dart';

import 'cf_diag.dart';

/// Kaynak türleri — merkezi tanılama envanteri.
enum CfResourceKind {
  timer,
  poller,
  sse,
  trtc,
  request,
  subscription,
}

enum CfResourcePhase { created, active, cancel, disposed }

class CfResourceRecord {
  CfResourceRecord({
    required this.id,
    required this.kind,
    required this.module,
    required this.label,
    required this.createdAt,
    this.traceId,
  }) : phase = CfResourcePhase.created;

  final String id;
  final CfResourceKind kind;
  final String module;
  final String label;
  final DateTime createdAt;
  final String? traceId;
  CfResourcePhase phase;
  DateTime? endedAt;

  bool get isActive =>
      phase == CfResourcePhase.created || phase == CfResourcePhase.active;
}

class CfResourceSnapshot {
  const CfResourceSnapshot({
    required this.activeByKind,
    required this.createdTotal,
    required this.disposedTotal,
    required this.activeRecords,
  });

  final Map<CfResourceKind, int> activeByKind;
  final int createdTotal;
  final int disposedTotal;
  final List<CfResourceRecord> activeRecords;

  int activeFor(CfResourceKind kind) => activeByKind[kind] ?? 0;

  int get activeTimers => activeFor(CfResourceKind.timer);
  int get activePollers => activeFor(CfResourceKind.poller);
  int get activeSse => activeFor(CfResourceKind.sse);
  int get activeTrtc => activeFor(CfResourceKind.trtc);
  int get activeRequests => activeFor(CfResourceKind.request);
  int get activeSubscriptions => activeFor(CfResourceKind.subscription);
}

/// CREATE → ACTIVE → CANCEL → DISPOSE yaşam döngüsü.
abstract final class CfResourceTracker {
  static var _seq = 0;
  static final _records = <String, CfResourceRecord>{};
  static int _created = 0;
  static int _disposed = 0;

  /// Dosya diagnostic logger (cf_diagnostic_logger_install).
  static void Function(
    String event,
    CfResourceKind kind,
    String id,
    String module,
    String label,
  )? onResourceEvent;

  static bool get enabled =>
      kDebugMode ||
      const bool.fromEnvironment('CANLIFAL_DIAGNOSTICS', defaultValue: false);

  static String create(
    CfResourceKind kind, {
    required String module,
    required String label,
    String? traceId,
  }) {
    _seq++;
    final id = '${kind.name}-$_seq';
    final rec = CfResourceRecord(
      id: id,
      kind: kind,
      module: module,
      label: label,
      createdAt: DateTime.now(),
      traceId: traceId,
    );
    rec.phase = CfResourcePhase.active;
    _records[id] = rec;
    _created++;
    if (enabled) {
      CfDiag.record(
        _categoryFor(kind),
        '[RESOURCE] ${kind.name} created id=$id module=$module label=$label',
        data: {'resourceId': id, 'module': module, 'label': label},
        traceId: traceId,
      );
    }
    onResourceEvent?.call('CREATE', kind, id, module, label);
    return id;
  }

  static void markCancel(String id, {String? reason}) {
    final rec = _records[id];
    if (rec == null || !rec.isActive) return;
    rec.phase = CfResourcePhase.cancel;
    if (enabled) {
      CfDiag.record(
        _categoryFor(rec.kind),
        '[RESOURCE] ${rec.kind.name} cancel id=$id'
        '${reason != null ? ' ($reason)' : ''}',
        data: {'resourceId': id, 'module': rec.module},
      );
    }
    onResourceEvent?.call('CANCEL', rec.kind, id, rec.module, rec.label);
  }

  static void markDisposed(String id, {String? reason}) {
    final rec = _records[id];
    if (rec == null) return;
    if (rec.phase == CfResourcePhase.disposed) return;
    rec.phase = CfResourcePhase.disposed;
    rec.endedAt = DateTime.now();
    _disposed++;
    if (enabled) {
      CfDiag.record(
        _categoryFor(rec.kind),
        '[RESOURCE] ${rec.kind.name} disposed id=$id'
        '${reason != null ? ' ($reason)' : ''}',
        data: {'resourceId': id, 'module': rec.module},
      );
    }
    onResourceEvent?.call('DISPOSE', rec.kind, id, rec.module, rec.label);
  }

  /// Periyodik zamanlayıcı — dispose/cancel ile eşleştirmek için id döner.
  static ({Timer timer, String resourceId}) periodic(
    Duration interval,
    void Function(Timer timer) onTick, {
    required String module,
    required String label,
    String? traceId,
  }) {
    final resourceId = create(
      CfResourceKind.timer,
      module: module,
      label: label,
      traceId: traceId,
    );
    final timer = Timer.periodic(interval, onTick);
    return (timer: timer, resourceId: resourceId);
  }

  static void cancelTimer(Timer? timer, String? resourceId) {
    timer?.cancel();
    if (resourceId != null) {
      markCancel(resourceId);
      markDisposed(resourceId);
    }
  }

  static CfResourceSnapshot snapshot({String? module}) {
    final active = _records.values
        .where((r) => r.isActive && (module == null || r.module == module))
        .toList(growable: false);
    final byKind = <CfResourceKind, int>{};
    for (final k in CfResourceKind.values) {
      byKind[k] = active.where((r) => r.kind == k).length;
    }
    return CfResourceSnapshot(
      activeByKind: byKind,
      createdTotal: _created,
      disposedTotal: _disposed,
      activeRecords: active,
    );
  }

  static List<CfResourceRecord> leaks({String? module}) =>
      snapshot(module: module).activeRecords;

  static bool hasLeaks({String? module}) => leaks(module: module).isNotEmpty;

  @visibleForTesting
  static void resetForTest() {
    _records.clear();
    _seq = 0;
    _created = 0;
    _disposed = 0;
  }

  static CfCategory _categoryFor(CfResourceKind kind) => switch (kind) {
        CfResourceKind.timer || CfResourceKind.poller => CfCategory.ui,
        CfResourceKind.sse => CfCategory.sse,
        CfResourceKind.trtc => CfCategory.trtc,
        CfResourceKind.request => CfCategory.network,
        CfResourceKind.subscription => CfCategory.unknown,
      };
}
