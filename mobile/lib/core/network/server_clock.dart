import 'dart:io' show HttpDate;

import 'package:dio/dio.dart';

/// Sunucu saati ile cihaz saati arasındaki fark (HTTP `Date` başlığından).
///
/// Bazı telefonların saati ileri/geri olduğunda sunucu zaman damgalı olaylar
/// (ör. sesli oda hediyeleri) yanlışlıkla «odaya girmeden önce» sayılıp
/// gösterilmiyordu. Karşılaştırmalar [nowMs] ile sunucu saatine göre yapılır.
abstract final class ServerClock {
  static int _offsetMs = 0;
  static bool _known = false;

  /// sunucu − cihaz (ms). Bilinmiyorsa 0.
  static int get offsetMs => _offsetMs;
  static bool get isKnown => _known;

  /// Sunucu saatine göre şimdiki zaman (ms).
  static int nowMs() => DateTime.now().millisecondsSinceEpoch + _offsetMs;

  /// Cihaz zamanını sunucu zamanına çevirir.
  static int toServerMs(int deviceMs) => deviceMs + _offsetMs;

  static void observeDateHeader(String? raw) {
    if (raw == null || raw.isEmpty) return;
    try {
      final server = HttpDate.parse(raw).millisecondsSinceEpoch;
      final offset = server - DateTime.now().millisecondsSinceEpoch;
      // `Date` saniye hassasiyetinde; küçük oynamaları yumuşat.
      _offsetMs = _known ? ((_offsetMs * 3 + offset) ~/ 4) : offset;
      _known = true;
    } catch (_) {}
  }

  static void resetForTest() {
    _offsetMs = 0;
    _known = false;
  }
}

class ServerClockInterceptor extends Interceptor {
  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    ServerClock.observeDateHeader(response.headers.value('date'));
    handler.next(response);
  }
}
