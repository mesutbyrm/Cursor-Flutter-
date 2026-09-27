import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Uygulamanın çalışma anındaki APK imza sertifikasının SHA-1 parmak izini okur.
///
/// Google girişi `ApiException 10 / DEVELOPER_ERROR` verdiğinde, cihazdaki
/// APK'nın imzası Firebase'e kayıtlı parmak izleriyle uyuşmuyor demektir.
/// Bu yardımcı, kullanıcının Firebase Console'a eklemesi gereken **gerçek**
/// SHA-1 değerini hata mesajında gösterebilmek için kullanılır.
class AppSignature {
  const AppSignature._();

  static const MethodChannel _channel = MethodChannel(
    'com.mesutbyrm.canlifal/app_signature',
  );

  static String? _cached;

  /// Android'de `AA:BB:...` biçiminde SHA-1 döndürür.
  /// Diğer platformlarda veya hata durumunda `null` döner.
  static Future<String?> sha1() async {
    if (_cached != null) return _cached;
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final value = await _channel.invokeMethod<String>('getSha1');
      if (value == null || value.isEmpty) return null;
      _cached = value;
      return value;
    } catch (e) {
      debugPrint('AppSignature.sha1 alınamadı: $e');
      return null;
    }
  }
}
