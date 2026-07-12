import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// Dio hatalarını kullanıcıya gösterilebilir metne çevirir.
  static ApiException fromDio(DioException e) {
    final code = e.response?.statusCode;
    final body = e.response?.data;

    if (e.type == DioExceptionType.connectionError) {
      final raw = (e.message ?? '').toLowerCase();
      if (raw.contains('failed host lookup') ||
          raw.contains('socketexception')) {
        return ApiException(
          'Sunucu adresi çözülemedi veya ağ yok. Wi-Fi/mobil veriyi kontrol edin.',
          statusCode: code,
        );
      }
      return ApiException(
        'Bağlantı kurulamadı. İnternet bağlantınızı kontrol edip tekrar deneyin.',
        statusCode: code,
      );
    }

    if (code == 401) {
      return const ApiException(
        'Oturum süresi doldu. Çıkış yapıp tekrar giriş yapın.',
        statusCode: 401,
      );
    }

    if (code == 403) {
      final serverMessage = body is Map
          ? (body['message'] ?? body['error'] ?? body['detail'])?.toString()
          : null;
      return ApiException(
        serverMessage != null && serverMessage.trim().isNotEmpty
            ? serverMessage
            : 'Bu işlem için yetkiniz yok. Site admin hesabıyla giriş yaptığınızdan emin olun.',
        statusCode: 403,
      );
    }
    if (code == 405) {
      return ApiException(
        'Bu işlem sunucuda desteklenmiyor (405). Uygulamayı güncelleyin veya web sürümünü deneyin.',
        statusCode: code,
      );
    }
    if (code == 404) {
      return ApiException('İstenen kaynak bulunamadı (404).', statusCode: code);
    }

    if (e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionTimeout) {
      return ApiException(
        'Sunucu yanıt vermedi (zaman aşımı). Bağlantınızı kontrol edip tekrar deneyin.',
        statusCode: code,
      );
    }

    if (e.type == DioExceptionType.cancel) {
      return ApiException(
        'İstek iptal edildi veya zaman aşımına uğradı.',
        statusCode: code,
      );
    }

    String msg = e.message ?? 'Ağ hatası';
    if (body is Map) {
      final m = body.cast<String, dynamic>();
      msg = (m['message'] ?? m['error'] ?? m['detail'] ?? msg).toString();
    } else if (body is String && body.isNotEmpty) {
      if (body.startsWith('<!DOCTYPE') || body.startsWith('<html')) {
        msg = 'Sunucu HTML döndürdü (muhtemelen yanlış uç veya oturum yok).';
      } else {
        msg = body;
      }
    }
    return ApiException(msg, statusCode: code);
  }

  /// Snackbar / dialog metni; ham DioException veya `toString` göstermez.
  static String userMessage(Object error) {
    if (error is ApiException) return error.message;
    if (error is DioException) return fromDio(error).message;
    // VoiceAgoraException — döngüsel import olmaması için tip adı ile kontrol.
    if (error.runtimeType.toString() == 'VoiceAgoraException') {
      return error.toString();
    }
    final raw = error.toString();
    if (raw.startsWith('Bad state: Agora:')) {
      return 'Agora ses bağlantısı kurulamadı. Mikrofon iznini ve interneti kontrol edin.';
    }
    if (raw.contains('DioException')) {
      return 'Sunucu isteği tamamlanamadı. İnternet bağlantınızı kontrol edip tekrar deneyin.';
    }
    if (raw.contains('TimeoutException') || raw.contains('timeout')) {
      return 'İstek zaman aşımına uğradı. Bağlantınızı kontrol edip tekrar deneyin.';
    }
    return raw.replaceFirst('Bad state: ', '');
  }

  @override
  String toString() {
    if (statusCode != null) return 'ApiException($statusCode): $message';
    return 'ApiException: $message';
  }
}
