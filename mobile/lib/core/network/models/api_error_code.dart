/// Backend `ErrorCodes` tablosu — `FLUTTER_BACKEND_ENTEGRASYON_PROMPT.md`.
enum ApiErrorCode {
  unauthorized,
  forbidden,
  tokenExpired,
  invalidToken,
  validationError,
  missingField,
  notFound,
  alreadyExists,
  conflict,
  insufficientCredits,
  insufficientJetons,
  rateLimited,
  sessionExpired,
  featureDisabled,
  internalError,
  serviceUnavailable,
  externalServiceError,
  unknown;

  static ApiErrorCode? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final key = raw.trim().toUpperCase().replaceAll('-', '_');
    return switch (key) {
      'UNAUTHORIZED' => ApiErrorCode.unauthorized,
      'FORBIDDEN' => ApiErrorCode.forbidden,
      'TOKEN_EXPIRED' => ApiErrorCode.tokenExpired,
      'INVALID_TOKEN' => ApiErrorCode.invalidToken,
      'VALIDATION_ERROR' => ApiErrorCode.validationError,
      'MISSING_FIELD' => ApiErrorCode.missingField,
      'NOT_FOUND' => ApiErrorCode.notFound,
      'ALREADY_EXISTS' => ApiErrorCode.alreadyExists,
      'CONFLICT' => ApiErrorCode.conflict,
      'INSUFFICIENT_CREDITS' => ApiErrorCode.insufficientCredits,
      'INSUFFICIENT_COINS' => ApiErrorCode.insufficientJetons,
      'INSUFFICIENT_BALANCE' => ApiErrorCode.insufficientJetons,
      'INSUFFICIENT_JETON' => ApiErrorCode.insufficientJetons,
      'INSUFFICIENT_JETONS' => ApiErrorCode.insufficientJetons,
      'RATE_LIMITED' => ApiErrorCode.rateLimited,
      'SESSION_EXPIRED' => ApiErrorCode.sessionExpired,
      'FEATURE_DISABLED' => ApiErrorCode.featureDisabled,
      'INTERNAL_ERROR' => ApiErrorCode.internalError,
      'SERVICE_UNAVAILABLE' => ApiErrorCode.serviceUnavailable,
      'EXTERNAL_SERVICE_ERROR' => ApiErrorCode.externalServiceError,
      _ => null,
    };
  }

  String get wireName => switch (this) {
        ApiErrorCode.unauthorized => 'UNAUTHORIZED',
        ApiErrorCode.forbidden => 'FORBIDDEN',
        ApiErrorCode.tokenExpired => 'TOKEN_EXPIRED',
        ApiErrorCode.invalidToken => 'INVALID_TOKEN',
        ApiErrorCode.validationError => 'VALIDATION_ERROR',
        ApiErrorCode.missingField => 'MISSING_FIELD',
        ApiErrorCode.notFound => 'NOT_FOUND',
        ApiErrorCode.alreadyExists => 'ALREADY_EXISTS',
        ApiErrorCode.conflict => 'CONFLICT',
        ApiErrorCode.insufficientCredits => 'INSUFFICIENT_CREDITS',
        ApiErrorCode.insufficientJetons => 'INSUFFICIENT_JETONS',
        ApiErrorCode.rateLimited => 'RATE_LIMITED',
        ApiErrorCode.sessionExpired => 'SESSION_EXPIRED',
        ApiErrorCode.featureDisabled => 'FEATURE_DISABLED',
        ApiErrorCode.internalError => 'INTERNAL_ERROR',
        ApiErrorCode.serviceUnavailable => 'SERVICE_UNAVAILABLE',
        ApiErrorCode.externalServiceError => 'EXTERNAL_SERVICE_ERROR',
        ApiErrorCode.unknown => 'UNKNOWN',
      };

  /// UI / snackbar için önerilen Türkçe mesaj.
  String defaultMessage() => switch (this) {
        ApiErrorCode.unauthorized ||
        ApiErrorCode.tokenExpired ||
        ApiErrorCode.invalidToken =>
          'Oturum süresi doldu. Tekrar giriş yapın.',
        ApiErrorCode.forbidden => 'Bu işlem için yetkiniz yok.',
        ApiErrorCode.validationError => 'Girdi doğrulama hatası.',
        ApiErrorCode.missingField => 'Zorunlu alan eksik.',
        ApiErrorCode.notFound => 'Kayıt bulunamadı.',
        ApiErrorCode.alreadyExists || ApiErrorCode.conflict =>
          'Bu kayıt zaten mevcut.',
        ApiErrorCode.insufficientCredits => 'Yetersiz kredi.',
        ApiErrorCode.insufficientJetons => 'Yetersiz jeton.',
        ApiErrorCode.rateLimited =>
          'Çok fazla istek gönderildi. Lütfen biraz bekleyin.',
        ApiErrorCode.sessionExpired => 'Oturum süresi bitti.',
        ApiErrorCode.featureDisabled => 'Bu özellik şu an kapalı.',
        ApiErrorCode.internalError => 'Sunucu hatası. Daha sonra deneyin.',
        ApiErrorCode.serviceUnavailable =>
          'Servis geçici olarak kullanılamıyor.',
        ApiErrorCode.externalServiceError => 'Harici servis hatası.',
        ApiErrorCode.unknown => 'Bir hata oluştu.',
      };

  bool get isAuthFailure => switch (this) {
        ApiErrorCode.unauthorized ||
        ApiErrorCode.tokenExpired ||
        ApiErrorCode.invalidToken ||
        ApiErrorCode.sessionExpired =>
          true,
        _ => false,
      };

  bool get isRetryable => switch (this) {
        ApiErrorCode.rateLimited ||
        ApiErrorCode.internalError ||
        ApiErrorCode.serviceUnavailable ||
        ApiErrorCode.externalServiceError =>
          true,
        _ => false,
      };
}
