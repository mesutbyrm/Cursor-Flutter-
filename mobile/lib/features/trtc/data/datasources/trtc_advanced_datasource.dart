import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/trtc_advanced_config.dart';

abstract class TRTCAdvancedDataSource {
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

class TRTCAdvancedDataSourceImpl implements TRTCAdvancedDataSource {
  final Dio _dio;

  TRTCAdvancedDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<void> applyAudioEffect(AudioEffectConfig effect) async {
    await _dio.safePost<dynamic>(
      '${ApiEndpoints.trtcToken}/audio-effect',
      data: {
        'effectType': effect.effectType.toString().split('.').last,
        'intensity': effect.intensity,
        'enabled': effect.enabled,
      },
    );
  }

  @override
  Future<void> startRecording(RecordingConfig config) async {
    await _dio.safePost<dynamic>(
      '${ApiEndpoints.trtcToken}/recording/start',
      data: {
        'mode': config.mode.toString().split('.').last,
        'filename': config.filename,
        'audioOnly': config.audioOnly,
        'uploadUrl': config.uploadUrl,
      },
    );
  }

  @override
  Future<void> stopRecording() async {
    await _dio.safePost<dynamic>(
      '${ApiEndpoints.trtcToken}/recording/stop',
    );
  }

  @override
  Future<String> getRecordingStatus() async {
    final res = await _dio.safeGet<dynamic>(
      '${ApiEndpoints.trtcToken}/recording/status',
    );
    final data = asJsonMap(res.data);
    return data['status']?.toString() ?? 'idle';
  }

  @override
  Future<void> setQuality(QualityConfig quality) async {
    await _dio.safePost<dynamic>(
      '${ApiEndpoints.trtcToken}/quality',
      data: {
        'level': quality.level.toString().split('.').last,
        'bitrate': quality.bitrate,
        'width': quality.width,
        'height': quality.height,
        'frameRate': quality.frameRate,
        'hardwareAcceleration': quality.hardwareAcceleration,
      },
    );
  }

  @override
  Future<QualityConfig> getQualityConfig() async {
    final res = await _dio.safeGet<dynamic>(
      '${ApiEndpoints.trtcToken}/quality',
    );
    final data = asJsonMap(res.data);

    final levelStr = data['level']?.toString() ?? 'medium';
    final level = QualityLevel.values.firstWhere(
      (e) => e.toString().split('.').last == levelStr,
      orElse: () => QualityLevel.medium,
    );

    return QualityConfig(
      level: level,
      bitrate: (data['bitrate'] as num?)?.toInt() ?? 1500,
      width: (data['width'] as num?)?.toInt() ?? 640,
      height: (data['height'] as num?)?.toInt() ?? 480,
      frameRate: (data['frameRate'] as num?)?.toInt() ?? 24,
      hardwareAcceleration: data['hardwareAcceleration'] == true,
    );
  }

  @override
  Future<void> setEchoCancellation(bool enabled) async {
    await _dio.safePost<dynamic>(
      '${ApiEndpoints.trtcToken}/audio/echo-cancellation',
      data: {'enabled': enabled},
    );
  }

  @override
  Future<void> setNoiseSuppression(bool enabled) async {
    await _dio.safePost<dynamic>(
      '${ApiEndpoints.trtcToken}/audio/noise-suppression',
      data: {'enabled': enabled},
    );
  }

  @override
  Future<void> setAudioVolume(int volume) async {
    await _dio.safePost<dynamic>(
      '${ApiEndpoints.trtcToken}/audio/volume',
      data: {'volume': volume.clamp(0, 100)},
    );
  }

  @override
  Future<void> setMicrophoneVolume(int volume) async {
    await _dio.safePost<dynamic>(
      '${ApiEndpoints.trtcToken}/microphone/volume',
      data: {'volume': volume.clamp(0, 100)},
    );
  }
}
