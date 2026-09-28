import '../entities/trtc_advanced_config.dart';

abstract class TRTCAdvancedRepository {
  Future<void> applyAudioEffect(AudioEffectConfig effect);
  Future<void> startRecording(RecordingConfig config);
  Future<void> stopRecording();
  Future<String> getRecordingStatus();
  Future<void> setQuality(QualityConfig quality);
  Future<QualityConfig> getQualityConfig();
  Future<void> setEchoCancellation(bool enabled);
  Future<void> setNoiseSuppression(bool enabled);
  Future<void> setAudioVolume(int volume);
  Future<void> setMicrophoneVolume(int volume);
}
