import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/live_stream_encoder_settings.dart';
import '../../domain/entities/live_stream_fps_mode.dart';
import '../../domain/entities/live_stream_quality_preset.dart';

class LiveStreamQualityNotifier extends Notifier<LiveStreamEncoderSettings> {
  @override
  LiveStreamEncoderSettings build() => const LiveStreamEncoderSettings();

  void setPreset(LiveStreamQualityPreset preset) {
    state = state.copyWith(preset: preset);
  }

  void setFpsMode(LiveStreamFpsMode fpsMode) {
    state = state.copyWith(fpsMode: fpsMode);
  }

  void applyNetworkQuality(int quality) {
    if (state.preset.isAuto) return;
    final down = state.preset.downgradeFromNetwork(quality);
    if (down != state.preset) {
      state = state.copyWith(preset: down);
    }
  }
}

final liveStreamQualityProvider =
    NotifierProvider<LiveStreamQualityNotifier, LiveStreamEncoderSettings>(
  LiveStreamQualityNotifier.new,
);
