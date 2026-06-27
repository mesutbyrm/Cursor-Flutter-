import 'package:flutter_test/flutter_test.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_dj_state.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_sse_event.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/moderation_result.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/music_queue_item.dart';

void main() {
  group('MusicQueueItem requestType', () {
    test('parses audio requestType', () {
      final item = MusicQueueItem.fromJson({
        'id': 'a1',
        'title': 'Test',
        'youtubeUrl': 'https://www.youtube.com/watch?v=abc',
        'createdAt': '2026-01-01T00:00:00Z',
        'requestType': 'audio',
      });
      expect(item.requestType, 'audio');
      expect(item.withVideo, isFalse);
      expect(item.isAudioRequest, isTrue);
    });

    test('parses video requestType', () {
      final item = MusicQueueItem.fromJson({
        'id': 'v1',
        'title': 'Clip',
        'youtubeUrl': 'https://www.youtube.com/watch?v=xyz',
        'createdAt': '2026-01-01T00:00:00Z',
        'requestType': 'video',
      });
      expect(item.requestType, 'video');
      expect(item.withVideo, isTrue);
      expect(item.isVideoRequest, isTrue);
    });

    test('legacy withVideo still works', () {
      final item = MusicQueueItem.fromJson({
        'id': 'l1',
        'title': 'Legacy',
        'youtubeUrl': 'https://www.youtube.com/watch?v=legacy',
        'createdAt': '2026-01-01T00:00:00Z',
        'withVideo': true,
      });
      expect(item.requestType, isNull);
      expect(item.withVideo, isTrue);
    });
  });

  group('ChatRoomDjState requestCosts', () {
    test('parses requestCosts map from GET /music', () {
      final dj = ChatRoomDjState.fromJson({
        'requestCosts': {'audio': 10, 'video': 20},
      });
      expect(dj.musicRequestCost, 10);
      expect(dj.videoRequestCost, 20);
    });
  });

  group('SSE system events', () {
    test('maps type system', () {
      expect(chatRoomSseEventTypeFrom('system'), ChatRoomSseEventType.system);
    });
  });

  group('ModerationKickResult', () {
    test('parses kickCount and autoBanned', () {
      final result = ModerationKickResult.fromJson({
        'kickCount': 3,
        'autoBanned': true,
      });
      expect(result.kickCount, 3);
      expect(result.autoBanned, isTrue);
      expect(result.feedbackMessage, contains('banlandı'));
    });
  });

  group('MusicClearResult', () {
    test('parses autoAdvanced', () {
      final result = MusicClearResult.fromJson({'autoAdvanced': true});
      expect(result.autoAdvanced, isTrue);
    });
  });
}
