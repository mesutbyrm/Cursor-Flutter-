import '../../domain/entities/trtc_advanced_config.dart';
import '../../domain/repositories/trtc_advanced_repository.dart';
import '../datasources/trtc_advanced_datasource.dart';

class TRTCAdvancedRepositoryImpl implements TRTCAdvancedRepository {
  final TRTCAdvancedDataSource _dataSource;

  TRTCAdvancedRepositoryImpl({required TRTCAdvancedDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<void> applyAudioEffect(AudioEffectConfig effect) async {
    await _dataSource.applyAudioEffect(effect);
  }

  @override
  Future<void> startRecording(RecordingConfig config) async {
    await _dataSource.startRecording(config);
  }

  @override
  Future<void> stopRecording() async {
    await _dataSource.stopRecording();
  }

  @override
  Future<String> getRecordingStatus() async {
    return await _dataSource.getRecordingStatus();
  }

  @override
  Future<void> setQuality(QualityConfig quality) async {
    await _dataSource.setQuality(quality);
  }

  @override
  Future<QualityConfig> getQualityConfig() async {
    return await _dataSource.getQualityConfig();
  }

  @override
  Future<void> setEchoCancellation(bool enabled) async {
    await _dataSource.setEchoCancellation(enabled);
  }

  @override
  Future<void> setNoiseSuppression(bool enabled) async {
    await _dataSource.setNoiseSuppression(enabled);
  }

  @override
  Future<void> setAudioVolume(int volume) async {
    await _dataSource.setAudioVolume(volume);
  }

  @override
  Future<void> setMicrophoneVolume(int volume) async {
    await _dataSource.setMicrophoneVolume(volume);
  }
}
