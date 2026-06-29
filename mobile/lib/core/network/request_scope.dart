import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ekran/provider yaşam döngüsüne bağlı HTTP iptali.
class HttpRequestScope {
  HttpRequestScope() {
    _token = CancelToken();
  }

  late final CancelToken _token;
  var _disposed = false;

  CancelToken get token {
    if (_disposed) {
      throw StateError('HttpRequestScope disposed');
    }
    return _token;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (!_token.isCancelled) {
      _token.cancel('scope_disposed');
    }
  }
}

/// Riverpod `ref.onDispose` ile otomatik iptal.
HttpRequestScope bindHttpRequestScope(Ref ref) {
  final scope = HttpRequestScope();
  ref.onDispose(scope.dispose);
  return scope;
}
