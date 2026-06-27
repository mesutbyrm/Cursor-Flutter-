import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/data/services/voice_room_music_pipeline_log.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/music_queue_item.dart';

void main() {
  group('VoiceRoomMusicPipelineLog.videoIdFromUrl', () {
    test('extracts from watch URL', () {
      expect(
        VoiceRoomMusicPipelineLog.videoIdFromUrl(
          'https://www.youtube.com/watch?v=-CxauCeQ_SQ',
        ),
        '-CxauCeQ_SQ',
      );
    });

    test('extracts from queue item', () {
      final item = MusicQueueItem(
        id: 'x',
        title: 'Test',
        youtubeUrl: 'https://youtu.be/abc123XYZ',
        createdAt: DateTime(2026),
      );
      expect(
        VoiceRoomMusicPipelineLog.videoIdFromItem(item),
        'abc123XYZ',
      );
    });
  });
}
