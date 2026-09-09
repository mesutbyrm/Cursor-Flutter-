import 'package:canlifal_social/features/live/domain/entities/live_stream_quality_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveStreamQualityPreset', () {
    test('detailLabel for 720p includes FPS', () {
      expect(
        LiveStreamQualityPreset.q720.detailLabel,
        '720p HD · 30 FPS',
      );
    });

    test('detailLabel for auto mentions network', () {
      expect(
        LiveStreamQualityPreset.auto.detailLabel,
        contains('Otomatik'),
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
