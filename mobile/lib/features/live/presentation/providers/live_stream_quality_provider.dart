import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/live_stream_quality_preset.dart';

class LiveStreamQualityNotifier extends Notifier<LiveStreamQualityPreset> {
  @override
  LiveStreamQualityPreset build() => LiveStreamQualityPreset.auto;

  void setPreset(LiveStreamQualityPreset preset) => state = preset;

  void applyNetworkQuality(int quality) {
    if (state.isAuto) {
      // Auto mode resolves at apply time in AgoraRoomManager.
      return;
    }
    final down = state.downgradeFromNetwork(quality);
    if (down != state) state = down;
  }
}

final liveStreamQualityProvider =
    NotifierProvider<LiveStreamQualityNotifier, LiveStreamQualityPreset>(
  LiveStreamQualityNotifier.new,
);
