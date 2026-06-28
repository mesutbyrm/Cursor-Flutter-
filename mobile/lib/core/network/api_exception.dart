class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// Snackbar / dialog metni; `ApiException(null): ...` gibi ham `toString` kullanmayın.
  static String userMessage(Object error) {
    if (error is ApiException) return error.message;
    // VoiceAgoraException — döngüsel import olmaması için tip adı ile kontrol.
    if (error.runtimeType.toString() == 'VoiceAgoraException') {
      return error.toString();
    }
    final raw = error.toString();
    if (raw.startsWith('Bad state: Agora:')) {
      return 'Agora ses bağlantısı kurulamadı. Mikrofon iznini ve interneti kontrol edin.';
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
