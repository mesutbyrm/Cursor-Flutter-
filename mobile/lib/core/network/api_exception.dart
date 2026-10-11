import 'package:dio/dio.dart';

import 'models/api_error_code.dart';

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.errorCode,
    this.apiErrorCode,
  });

  final String message;
  final int? statusCode;
  final String? errorCode;
  final ApiErrorCode? apiErrorCode;

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
            : 'Bu işlem için yetkiniz yok. Admin veya kurucu (yonetici) hesabıyla giriş yaptığınızdan emin olun.',
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
    if (code == 429) {
      return ApiException(
        ApiErrorCode.rateLimited.defaultMessage(),
        statusCode: 429,
        errorCode: ApiErrorCode.rateLimited.wireName,
        apiErrorCode: ApiErrorCode.rateLimited,
      );
    }

    if (code == 409 && body is Map) {
      final parsed409 = _parsePriceMismatch(
        Map<String, dynamic>.from(body),
        statusCode: code,
      );
      if (parsed409 != null) return parsed409;
    }

    if (body is Map) {
      final modBlocked = _parseModerationBlocked(
        Map<String, dynamic>.from(body),
        statusCode: code,
      );
      if (modBlocked != null) return modBlocked;
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
      final parsed = _parseStructuredError(
        Map<String, dynamic>.from(body),
        statusCode: code,
      );
      if (parsed != null) return parsed;
      final m = body.cast<String, dynamic>();
      final errField = m['error'];
      if (errField is String) {
        msg = errField;
      } else if (errField is List && errField.isNotEmpty) {
        msg = errField.map((e) => e.toString()).join('; ');
      } else {
        final messageField = m['message'];
        if (messageField is List && messageField.isNotEmpty) {
          msg = messageField.map((e) => e.toString()).join('; ');
        } else {
          msg = (messageField ?? m['detail'] ?? msg).toString();
        }
      }
    } else if (body is String && body.isNotEmpty) {
      if (body.startsWith('<!DOCTYPE') || body.startsWith('<html')) {
        msg = 'Sunucu HTML döndürdü (muhtemelen yanlış uç veya oturum yok).';
      } else {
        msg = body;
      }
    }
    return ApiException(msg, statusCode: code);
  }

  /// GirLive Bot — `422` + `MODERATION_BLOCKED` (kılavuz §9.3.2).
  static ApiException? _parseModerationBlocked(
    Map<String, dynamic> body, {
    int? statusCode,
  }) {
    final topCode = body['code']?.toString();
    final mod = body['moderation'];
    if (topCode != 'MODERATION_BLOCKED' && mod is! Map) return null;

    final moderation = mod is Map ? Map<String, dynamic>.from(mod) : null;
    final severity =
        moderation?['severity']?.toString().toUpperCase() ?? 'LOW';
    final verdict = moderation?['verdict']?.toString();
    final serverMsg = body['message']?.toString().trim();
    final word = moderation?['word']?.toString().trim();

    String msg = serverMsg ?? '';
    if (msg.isEmpty) {
      msg = switch (severity) {
        'LOW' => word != null && word.isNotEmpty
            ? 'GirLive Bot: «$word» yasaklı kelime uyarısı — lütfen kurallara uyun.'
            : 'GirLive Bot: mesajınız kurallara aykırı (uyarı).',
        'MEDIUM' =>
          'GirLive Bot: geçici susturma — yasaklı veya uygunsuz ifade.',
        'HIGH' => 'GirLive Bot: odadan çıkarıldınız (ciddi ihlal).',
        'CRITICAL' => 'GirLive Bot: odadan yasaklandınız.',
        _ => 'GirLive Bot: mesaj moderasyon nedeniyle işlenemedi.',
      };
    }
    if (verdict != null && verdict.isNotEmpty && !msg.contains(verdict)) {
      msg = '$msg ($verdict)';
    }
    return ApiException(
      msg,
      statusCode: statusCode ?? 422,
      errorCode: 'MODERATION_BLOCKED',
    );
  }

  static ApiException? _parsePriceMismatch(
    Map<String, dynamic> body, {
    int? statusCode,
  }) {
    final topCode = body['code']?.toString();
    if (topCode == 'PRICE_MISMATCH') {
      final msg = body['message']?.toString().trim();
      return ApiException(
        msg != null && msg.isNotEmpty
            ? msg
            : 'Fiyat güncellendi, lütfen tekrar deneyin.',
        statusCode: statusCode,
        errorCode: 'PRICE_MISMATCH',
      );
    }
    final nested = body['error'];
    if (nested is Map) {
      final err = Map<String, dynamic>.from(nested);
      if (err['code']?.toString() == 'PRICE_MISMATCH') {
        final msg = (err['message'] ?? err['detail'])?.toString().trim();
        return ApiException(
          msg != null && msg.isNotEmpty
              ? msg
              : 'Fiyat güncellendi, lütfen tekrar deneyin.',
          statusCode: statusCode,
          errorCode: 'PRICE_MISMATCH',
        );
      }
    }
    return null;
  }

  /// Yeni `{ success: false, error: { code, message } }` ve eski `{ error: "..." }`.
  static ApiException? _parseStructuredError(
    Map<String, dynamic> body, {
    int? statusCode,
  }) {
    final nested = body['error'];
    if (nested is Map) {
      final err = Map<String, dynamic>.from(nested);
      final message = (err['message'] ?? err['detail'])?.toString().trim();
      final code = err['code']?.toString();
      if (message != null && message.isNotEmpty) {
        return ApiException(message, statusCode: statusCode, errorCode: code);
      }
    }
    final flat = body['error'];
    if (flat is String && flat.trim().isNotEmpty) {
      final code = flat.trim().toLowerCase();
      if (code == 'insufficient_jeton' || code == 'insufficient_jetons') {
        return ApiException(
          'Yetersiz jeton bakiyesi.',
          statusCode: statusCode,
          errorCode: ApiErrorCode.insufficientJetons.wireName,
          apiErrorCode: ApiErrorCode.insufficientJetons,
        );
      }
      return ApiException(flat.trim(), statusCode: statusCode);
    }
    if (body['success'] == false) {
      final message = body['message']?.toString();
      if (message != null && message.isNotEmpty) {
        return ApiException(message, statusCode: statusCode);
      }
    }
    return null;
  }

  /// Snackbar / dialog metni; ham DioException veya `toString` göstermez.
  static String userMessage(Object error) {
    if (error is ApiException) {
      final lower = error.message.toLowerCase();
      if (lower.contains('invalid type') || lower.contains('geçersiz alan')) {
        return 'Sunucu isteği reddetti (geçersiz alan). Odaya tekrar girin veya uygulamayı güncelleyin.';
      }
      return error.message;
    }
    if (error is DioException) return fromDio(error).message;
    // VoiceAgoraException — döngüsel import olmaması için tip adı ile kontrol.
    if (error.runtimeType.toString() == 'VoiceTrtcException' ||
        error.runtimeType.toString() == 'VoiceAgoraException') {
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
    final lower = raw.toLowerCase();
    if (lower.contains('invalid type')) {
      return 'Sunucu isteği reddetti (geçersiz alan). Odaya tekrar girin veya uygulamayı güncelleyin.';
    }
    return raw.replaceFirst('Bad state: ', '');
  }

  @override
  String toString() {
    if (statusCode != null) return 'ApiException($statusCode): $message';
    return 'ApiException: $message';
  }
}
