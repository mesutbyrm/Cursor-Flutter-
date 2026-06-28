/// Sesli oda Agora hataları — UI'da `Bad state:` yerine okunabilir metin.
class VoiceAgoraException implements Exception {
  const VoiceAgoraException(
    this.message, {
    this.cause,
    this.stackTrace,
    this.phase,
  });

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;
  final String? phase;

  @override
  String toString() => message;
}
