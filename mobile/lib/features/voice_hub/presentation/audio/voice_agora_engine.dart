import '../../../agora/domain/entities/agora_credentials.dart';
import 'voice_agora_exception.dart';

/// Agora kaldırıldı — sesli oda yalnızca Tencent TRTC kullanır.
@Deprecated('VoiceTrtcEngine kullanın — Agora desteği kaldırıldı')
class VoiceAgoraEngine {
  VoiceAgoraEngine({Object? tokenSource});

  bool get inChannel => false;
  bool get micOn => false;
  bool get publishMic => false;
  AgoraCredentials? get lastCredentials => null;

  Future<void> join({
    required String roomId,
    required String userId,
    bool publish = false,
    AgoraCredentials? prefetchedCredentials,
  }) async {
    throw const VoiceAgoraException(
      'Agora kaldırıldı. Sesli oda Tencent TRTC ile bağlanır.',
    );
  }

  Future<void> leave() async {}

  Future<void> setMicEnabled(bool enabled) async {}

  Future<void> setPublishMic(bool publish) async {}

  Future<void> dispose() async {}
}
