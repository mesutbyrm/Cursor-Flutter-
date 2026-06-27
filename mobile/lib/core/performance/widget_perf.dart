import 'dart:async';

import 'package:flutter/material.dart';

/// Görev 17 — gereksiz rebuild/setState azaltma, iptal edilebilir gecikmeler.
abstract final class WidgetPerf {
  /// Gecikmeli tek seferlik callback — `dispose()` içinde [CancellableDelay.cancel].
  static CancellableDelay delay(Duration duration, VoidCallback callback) {
    return CancellableDelay(duration, callback);
  }
}

/// İptal edilebilir zamanlayıcı — widget dispose sonrası setState / callback engeli.
class CancellableDelay {
  CancellableDelay(Duration duration, VoidCallback callback) {
    _timer = Timer(duration, () {
      if (!_cancelled) callback();
    });
  }

  Timer? _timer;
  var _cancelled = false;

  void cancel() {
    _cancelled = true;
    _timer?.cancel();
    _timer = null;
  }
}

/// FutureBuilder yerine — tek seferlik async yükleme, yalnızca veri değişince rebuild.
mixin AsyncLoadState<T> on State {
  T? _data;
  Object? _error;
  var _loading = false;

  bool get asyncLoading => _loading;
  T? get asyncData => _data;
  Object? get asyncError => _error;

  Future<void> runAsyncLoad(Future<T> Function() loader) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await loader();
      if (!mounted) return;
      setState(() {
        _data = result;
        _loading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
      assert(() {
        FlutterError.reportError(
          FlutterErrorDetails(exception: e, stack: st, library: 'AsyncLoadState'),
        );
        return true;
      }());
    }
  }

  void resetAsyncLoad() {
    _data = null;
    _error = null;
    _loading = false;
  }
}
