import '../../../core/network/api_exception.dart';

/// PK API hata kodları — `PK_ENTEGRASYON.md` §3–5.
class PkException extends ApiException {
  const PkException(
    super.message, {
    super.statusCode,
    String? code,
  }) : super(errorCode: code);

  static PkException fromResponse({
    required int? statusCode,
    required dynamic body,
    String fallback = 'PK işlemi başarısız',
  }) {
    String? code;
    String message = fallback;
    if (body is Map) {
      final err = body['error'];
      if (err is Map) {
        code = err['code']?.toString();
        message = err['message']?.toString() ?? message;
      } else if (err != null) {
        message = err.toString();
      }
      final msg = body['message']?.toString();
      if (msg != null && msg.isNotEmpty) message = msg;
    } else if (body is String && body.isNotEmpty) {
      message = body;
    }
    return PkException(userMessageForCode(code, message), statusCode: statusCode, code: code);
  }

  static String userMessageForCode(String? code, String serverMessage) {
    switch (code?.toUpperCase()) {
      case 'NOT_OWNER':
      case 'NOT_STREAM_OWNER':
        return 'PK başlatma yetkiniz yok';
      case 'ROOM_INACTIVE':
      case 'STREAM_NOT_LIVE':
        return 'Yayınınız kapanmış, tekrar başlatın';
      case 'ROOM_NOT_FOUND':
      case 'STREAM_NOT_FOUND':
        return 'Oturum bulunamadı, sayfayı yenileyin';
      case 'TARGET_NOT_FOUND':
      case 'TARGET_INACTIVE':
      case 'TARGET_NOT_LIVE':
        return 'Rakip artık yayında değil';
      case 'PK_EXISTS':
        return 'Zaten aktif bir PK var';
      case 'SELF_PK':
        return 'Kendinizle PK yapamazsınız';
      case 'PK_EXPIRED':
        return 'Davet zaman aşımına uğradı';
      case 'PK_NOT_PENDING':
        return 'Bu davet zaten yanıtlanmış';
      case 'RATE_LIMITED':
        return 'Çok hızlı denediniz, biraz bekleyin';
      case 'PK_NOT_FOUND':
        return 'PK bulunamadı';
      case 'NOT_AUTHORIZED':
      case 'FORBIDDEN':
        return 'Bu işlem için yetkiniz yok';
      default:
        if (serverMessage.contains('PK durumu değişti')) {
          return 'PK durumu değişti, tekrar deneyin';
        }
        return serverMessage;
    }
  }
}
