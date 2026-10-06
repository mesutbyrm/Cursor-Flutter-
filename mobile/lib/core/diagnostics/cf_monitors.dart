import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'cf_diag.dart';

/// Kare istatistiği — saf mantık (test edilebilir).
class CfFrameStats {
  int frames = 0;
  int janky = 0;
  int worstMs = 0;
  int lastBuildMs = 0;
  int lastRasterMs = 0;

  /// 60 Hz için 16,7 ms; bunun 3 katını aşan kare «jank» sayılır.
  static const jankThresholdMs = 50;

  /// Bir kareyi işler; eşik aşıldıysa kare süresini (ms) döndürür.
  int? add({required int buildMs, required int rasterMs}) {
    frames++;
    lastBuildMs = buildMs;
    lastRasterMs = rasterMs;
    final total = buildMs > rasterMs ? buildMs : rasterMs;
    if (total > worstMs) worstMs = total;
    if (total >= jankThresholdMs) {
      janky++;
      return total;
    }
    return null;
  }

  void reset() {
    frames = 0;
    janky = 0;
    worstMs = 0;
  }
}

/// Flutter kare süresi izleyicisi — yalnızca [CfDiag.verbose] açıkken.
abstract final class CfFrameMonitor {
  static final stats = CfFrameStats();
  static var _attached = false;
  static DateTime? _lastLog;

  static void start() {
    if (_attached) return;
    _attached = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  static void stop() {
    if (!_attached) return;
    _attached = false;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
  }

  static void _onTimings(List<FrameTiming> timings) {
    if (!CfDiag.verbose.value) return;
    for (final t in timings) {
      final jank = stats.add(
        buildMs: t.buildDuration.inMilliseconds,
        rasterMs: t.rasterDuration.inMilliseconds,
      );
      if (jank == null) continue;
      final now = DateTime.now();
      // En fazla saniyede bir uyarı — log baskısı yaratmaz.
      if (_lastLog != null &&
          now.difference(_lastLog!).inMilliseconds < 1000) {
        continue;
      }
      _lastLog = now;
      CfDiag.record(
        CfCategory.ui,
        'PERFORMANCE WARNING frame=${jank}ms (build ${t.buildDuration.inMilliseconds}'
        ' / raster ${t.rasterDuration.inMilliseconds}) expected<16.7ms',
        level: CfLevel.warn,
        data: {
          'screen': CfDiag.screen ?? '-',
          'action': CfDiag.lastAction ?? '-',
        },
      );
    }
  }
}

/// Donma tespiti — saf mantık: zamanlayıcı beklenenden çok geç gelirse ana
/// isolate/event loop tıkanmıştır.
class CfFreezeDetector {
  CfFreezeDetector({
    this.tick = const Duration(milliseconds: 250),
    this.threshold = const Duration(milliseconds: 1000),
  });

  final Duration tick;
  final Duration threshold;
  DateTime? _last;

  /// Zamanlayıcı her tetiklendiğinde çağrılır; donma süresi varsa döndürür.
  Duration? onTick(DateTime now) {
    final last = _last;
    _last = now;
    if (last == null) return null;
    final late = now.difference(last) - tick;
    return late >= threshold ? late : null;
  }

  /// Uygulama arka plandayken zamanlayıcı durur; geri dönüşte yanlış alarm
  /// vermemek için referansı sıfırla.
  void reset() => _last = null;
}

abstract final class CfFreezeWatchdog {
  static final detector = CfFreezeDetector();
  static Timer? _timer;
  static _LifecycleHook? _hook;
  static int freezeCount = 0;
  static int worstFreezeMs = 0;

  static bool get running => _timer != null;

  static void start() {
    if (_timer != null) return;
    _hook ??= _LifecycleHook(detector.reset);
    WidgetsBinding.instance.addObserver(_hook!);
    detector.reset();
    _timer = Timer.periodic(detector.tick, (_) {
      if (!CfDiag.verbose.value) return;
      final f = detector.onTick(DateTime.now());
      if (f == null) return;
      freezeCount++;
      if (f.inMilliseconds > worstFreezeMs) worstFreezeMs = f.inMilliseconds;
      CfDiag.record(
        CfCategory.ui,
        'UI FREEZE DETECTED duration=${f.inMilliseconds}ms',
        level: CfLevel.error,
        data: {
          'screen': CfDiag.screen ?? '-',
          'lastAction': CfDiag.lastAction ?? '-',
          'pending': CfDiag.pendingOps.join(', '),
        },
      );
    });
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
    if (_hook != null) WidgetsBinding.instance.removeObserver(_hook!);
  }
}

class _LifecycleHook with WidgetsBindingObserver {
  _LifecycleHook(this._onChange);
  final VoidCallback _onChange;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _onChange();
}

/// Verbose durumuna göre izleyicileri başlatır/durdurur.
abstract final class CfMonitors {
  static var _wired = false;

  static void init() {
    if (_wired) return;
    _wired = true;
    CfDiag.verbose.addListener(_sync);
    _sync();
  }

  static void _sync() {
    if (CfDiag.verbose.value) {
      CfFrameMonitor.start();
      CfFreezeWatchdog.start();
    } else {
      CfFrameMonitor.stop();
      CfFreezeWatchdog.stop();
    }
  }
}
