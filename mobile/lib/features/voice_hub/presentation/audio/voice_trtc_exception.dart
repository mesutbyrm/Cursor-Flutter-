/// Sesli oda TRTC hataları — UI'da `Bad state:` yerine okunabilir metin.
class VoiceTrtcException implements Exception {
  const VoiceTrtcException(
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

@Deprecated('VoiceAgoraException → VoiceTrtcException')
typedef VoiceAgoraException = VoiceTrtcException;
