import 'live_stream_fps_mode.dart';
import 'live_stream_quality_preset.dart';

/// Video yayın encoder ayarları — çözünürlük + bağımsız FPS.
class LiveStreamEncoderSettings {
  const LiveStreamEncoderSettings({
    this.preset = LiveStreamQualityPreset.auto,
    this.fpsMode = LiveStreamFpsMode.auto,
  });

  final LiveStreamQualityPreset preset;
  final LiveStreamFpsMode fpsMode;

  LiveStreamEncoderSettings copyWith({
    LiveStreamQualityPreset? preset,
    LiveStreamFpsMode? fpsMode,
  }) {
    return LiveStreamEncoderSettings(
      preset: preset ?? this.preset,
      fpsMode: fpsMode ?? this.fpsMode,
    );
  }

  /// Ağ kalitesine göre çözünürlük; FPS ayrı seçilmişse korunur.
  LiveStreamQualityPreset resolvePreset(int networkQuality) {
    return preset.downgradeFromNetwork(networkQuality);
  }

  int effectiveFps([LiveStreamQualityPreset? resolvedPreset]) {
    if (!fpsMode.isAuto) return fpsMode.fps;
    return (resolvedPreset ?? preset).fps;
  }

  String get detailLabel {
    final fpsText = fpsMode.isAuto
        ? '${preset.fps} FPS'
        : '${fpsMode.fps} FPS';
    if (preset.isAuto) {
      return 'Otomatik · $fpsText';
    }
    return '${preset.label} · $fpsText';
  }
}
