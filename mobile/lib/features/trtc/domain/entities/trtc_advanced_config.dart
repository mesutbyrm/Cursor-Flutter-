enum AudioEffectType {
  none,
  echo,
  reverb,
  voiceModulation,
}

enum RecordingMode {
  none,
  local,
  cloud,
  both,
}

enum QualityLevel {
  low,
  medium,
  high,
  ultra,
}

class AudioEffectConfig {
  final AudioEffectType effectType;
  final double intensity;
  final bool enabled;

  AudioEffectConfig({
    required this.effectType,
    required this.intensity,
    required this.enabled,
  });
}

class RecordingConfig {
  final RecordingMode mode;
  final String? filename;
  final bool audioOnly;
  final String? uploadUrl;
  final bool isRecording;

  RecordingConfig({
    required this.mode,
    this.filename,
    required this.audioOnly,
    this.uploadUrl,
    required this.isRecording,
  });
}

class QualityConfig {
  final QualityLevel level;
  final int bitrate;
  final int width;
  final int height;
  final int frameRate;
  final bool hardwareAcceleration;

  QualityConfig({
    required this.level,
    required this.bitrate,
    required this.width,
    required this.height,
    required this.frameRate,
    required this.hardwareAcceleration,
  });

  factory QualityConfig.low() => QualityConfig(
        level: QualityLevel.low,
        bitrate: 500,
        width: 320,
        height: 240,
        frameRate: 15,
        hardwareAcceleration: false,
      );

  factory QualityConfig.medium() => QualityConfig(
        level: QualityLevel.medium,
        bitrate: 1500,
        width: 640,
        height: 480,
        frameRate: 24,
        hardwareAcceleration: true,
      );

  factory QualityConfig.high() => QualityConfig(
        level: QualityLevel.high,
        bitrate: 2500,
        width: 1280,
        height: 720,
        frameRate: 30,
        hardwareAcceleration: true,
      );

  factory QualityConfig.ultra() => QualityConfig(
        level: QualityLevel.ultra,
        bitrate: 4000,
        width: 1920,
        height: 1080,
        frameRate: 60,
        hardwareAcceleration: true,
      );
}

class TRTCAdvancedConfig {
  final AudioEffectConfig audioEffect;
  final RecordingConfig recording;
  final QualityConfig quality;
  final bool echoCancellation;
  final bool noiseSuppression;
  final int audioVolume;
  final int microphoneVolume;

  TRTCAdvancedConfig({
    required this.audioEffect,
    required this.recording,
    required this.quality,
    required this.echoCancellation,
    required this.noiseSuppression,
    required this.audioVolume,
    required this.microphoneVolume,
  });

  factory TRTCAdvancedConfig.defaults() => TRTCAdvancedConfig(
        audioEffect: AudioEffectConfig(
          effectType: AudioEffectType.none,
          intensity: 0.5,
          enabled: false,
        ),
        recording: RecordingConfig(
          mode: RecordingMode.none,
          audioOnly: false,
          isRecording: false,
        ),
        quality: QualityConfig.medium(),
        echoCancellation: true,
        noiseSuppression: true,
        audioVolume: 100,
        microphoneVolume: 100,
      );
}
