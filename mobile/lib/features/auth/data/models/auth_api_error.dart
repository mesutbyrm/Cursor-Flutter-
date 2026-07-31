/// Sunucu hata kodları — yeni `{ success, error: { code, message } }` formatı.
enum AuthApiErrorCode {
  unauthorized,
  forbidden,
  tokenExpired,
  invalidToken,
  validationError,
  missingField,
  notFound,
  alreadyExists,
  insufficientCredits,
  insufficientJetons,
  rateLimited,
  internalError,
  unknown;

  static AuthApiErrorCode? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final key = raw.trim().toUpperCase().replaceAll('-', '_');
    return switch (key) {
      'UNAUTHORIZED' => AuthApiErrorCode.unauthorized,
      'FORBIDDEN' => AuthApiErrorCode.forbidden,
      'TOKEN_EXPIRED' => AuthApiErrorCode.tokenExpired,
      'INVALID_TOKEN' => AuthApiErrorCode.invalidToken,
      'VALIDATION_ERROR' => AuthApiErrorCode.validationError,
      'MISSING_FIELD' => AuthApiErrorCode.missingField,
      'NOT_FOUND' => AuthApiErrorCode.notFound,
      'ALREADY_EXISTS' => AuthApiErrorCode.alreadyExists,
      'INSUFFICIENT_CREDITS' => AuthApiErrorCode.insufficientCredits,
      'INSUFFICIENT_JETONS' => AuthApiErrorCode.insufficientJetons,
      'RATE_LIMITED' => AuthApiErrorCode.rateLimited,
      'INTERNAL_ERROR' => AuthApiErrorCode.internalError,
      _ => null,
    };
  }
}

class AuthApiError {
  const AuthApiError({
    required this.message,
    this.code,
    this.statusCode,
  });

  final String message;
  final AuthApiErrorCode? code;
  final int? statusCode;

  /// Yeni: `{ success: false, error: { code, message } }`
  /// Eski: `{ error: "mesaj" }` veya `{ message: "..." }`
  static AuthApiError? fromResponseBody(dynamic body, {int? statusCode}) {
    if (body == null) return null;
    if (body is String && body.trim().isNotEmpty) {
      return AuthApiError(message: body.trim(), statusCode: statusCode);
    }
    if (body is! Map) return null;
    final map = Map<String, dynamic>.from(body);

    final nested = map['error'];
    if (nested is Map) {
      final err = Map<String, dynamic>.from(nested);
      final message = (err['message'] ?? err['detail'] ?? err['title'])
          ?.toString()
          .trim();
      final code = AuthApiErrorCode.tryParse(err['code']?.toString());
      if (message != null && message.isNotEmpty) {
        return AuthApiError(message: message, code: code, statusCode: statusCode);
      }
    }

    final flat = map['error'] ?? map['message'] ?? map['detail'];
    if (flat is String && flat.trim().isNotEmpty) {
      return AuthApiError(
        message: flat.trim(),
        code: AuthApiErrorCode.tryParse(flat),
        statusCode: statusCode,
      );
    }

    return null;
  }
}
