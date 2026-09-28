import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/trtc_advanced_datasource.dart';
import '../../data/repositories/trtc_advanced_repository_impl.dart';
import '../../domain/entities/trtc_advanced_config.dart';
import '../../domain/repositories/trtc_advanced_repository.dart';
import '../../../../core/network/dio_provider.dart';

final trtcAdvancedDataSourceProvider = Provider<TRTCAdvancedDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return TRTCAdvancedDataSourceImpl(dio: dio);
});

final trtcAdvancedRepositoryProvider = Provider<TRTCAdvancedRepository>((ref) {
  final dataSource = ref.watch(trtcAdvancedDataSourceProvider);
  return TRTCAdvancedRepositoryImpl(dataSource: dataSource);
});

final trtcAdvancedConfigProvider =
    StateProvider<TRTCAdvancedConfig>((ref) => TRTCAdvancedConfig.defaults());

final audioEffectProvider = StateProvider<AudioEffectConfig>((ref) {
  final config = ref.watch(trtcAdvancedConfigProvider);
  return config.audioEffect;
});

final recordingConfigProvider = StateProvider<RecordingConfig>((ref) {
  final config = ref.watch(trtcAdvancedConfigProvider);
  return config.recording;
});

final qualityConfigProvider = StateProvider<QualityConfig>((ref) {
  final config = ref.watch(trtcAdvancedConfigProvider);
  return config.quality;
});

final recordingStatusProvider = FutureProvider<String>((ref) async {
  final repository = ref.watch(trtcAdvancedRepositoryProvider);
  return repository.getRecordingStatus();
});

final qualitySettingProvider = FutureProvider<QualityConfig>((ref) async {
  final repository = ref.watch(trtcAdvancedRepositoryProvider);
  return repository.getQualityConfig();
});

final echoCancellationProvider =
    StateProvider<bool>((ref) => true);

final noiseSuppressionProvider =
    StateProvider<bool>((ref) => true);

final audioVolumeProvider = StateProvider<int>((ref) => 100);

final microphoneVolumeProvider = StateProvider<int>((ref) => 100);
