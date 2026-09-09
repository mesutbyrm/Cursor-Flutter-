import 'package:canlifal_social/features/live/domain/entities/live_stream_encoder_settings.dart';
import 'package:canlifal_social/features/live/domain/entities/live_stream_fps_mode.dart';
import 'package:canlifal_social/features/live/domain/entities/live_stream_quality_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveStreamEncoderSettings', () {
    test('detailLabel combines preset and manual FPS', () {
      const settings = LiveStreamEncoderSettings(
        preset: LiveStreamQualityPreset.q720,
        fpsMode: LiveStreamFpsMode.fps24,
      );
      expect(settings.detailLabel, '720p HD · 24 FPS');
    });

    test('effectiveFps uses preset default when auto', () {
      const settings = LiveStreamEncoderSettings(
        preset: LiveStreamQualityPreset.q360,
      );
      expect(settings.effectiveFps(), 24);
    });

    test('effectiveFps uses manual override', () {
      const settings = LiveStreamEncoderSettings(
        preset: LiveStreamQualityPreset.q1080,
        fpsMode: LiveStreamFpsMode.fps15,
      );
      expect(settings.effectiveFps(), 15);
    });
  });

  group('LiveStreamQualityPreset', () {
    test('detailLabel for 720p includes FPS', () {
      expect(
        LiveStreamQualityPreset.q720.detailLabel,
        '720p HD · 30 FPS',
      );
    });

    test('downgradeFromNetwork for auto on poor network', () {
      expect(
        LiveStreamQualityPreset.auto.downgradeFromNetwork(0),
        LiveStreamQualityPreset.q360,
      );
    });
  });
}
