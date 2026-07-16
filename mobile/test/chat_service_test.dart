import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/api_response.dart';
import 'package:canlifal_social/services/models/chat_music_hit.dart';
import 'package:canlifal_social/services/models/chat_presence.dart';
import 'package:canlifal_social/services/models/chat_room_summary.dart';
import 'package:canlifal_social/services/models/chat_service_message.dart';

void main() {
  group('ChatRoomSummary', () {
    test('parses room card', () {
      final room = ChatRoomSummary.fromJson({
        'id': 'room-1',
        'name': 'Test Oda',
        'slug': 'test-oda',
        'type': 'voice',
        'memberCount': 12,
        'isLive': true,
      });
      expect(room.id, 'room-1');
      expect(room.name, 'Test Oda');
      expect(room.memberCount, 12);
      expect(room.isLive, isTrue);
    });
  });

  group('ChatServiceMessage', () {
    test('parses text message', () {
      final msg = ChatServiceMessage.fromJson({
        'id': 'm1',
        'content': 'Merhaba',
        'type': 'text',
        'createdAt': '2026-07-16T12:00:00.000Z',
        'user': {'id': 'u1', 'name': 'Ali'},
      });
      expect(msg.content, 'Merhaba');
      expect(msg.user?.name, 'Ali');
    });
  });

  group('ChatPresence', () {
    test('parses seat info', () {
      final p = ChatPresence.fromJson({
        'id': 'u2',
        'name': 'Ayşe',
        'seatIndex': 3,
        'isMuted': true,
      });
      expect(p.seatIndex, 3);
      expect(p.isMuted, isTrue);
    });
  });

  group('ChatMusicHit', () {
    test('parses search hit', () {
      final hit = ChatMusicHit.fromJson({
        'videoId': 'abc123',
        'title': 'Şarkı',
        'artist': 'Sanatçı',
      });
      expect(hit.videoId, 'abc123');
      expect(hit.title, 'Şarkı');
    });
  });

  group('getMessages parseResponse', () {
    test('unwraps success wrapper', () {
      final parsed = parseResponse<List<ChatServiceMessage>>(
        {
          'success': true,
          'data': {
            'messages': [
              {'id': '1', 'content': 'x', 'createdAt': '2026-01-01T00:00:00Z'},
            ],
          },
        },
        fromData: (data) {
          final list = data is Map
              ? (data['messages'] as List)
                  .map((e) => ChatServiceMessage.fromJson(
                        Map<String, dynamic>.from(e as Map),
                      ))
                  .toList()
              : <ChatServiceMessage>[];
          return list;
        },
      );
      expect(parsed.success, isTrue);
      expect(parsed.data, hasLength(1));
      expect(parsed.data!.first.content, 'x');
    });
  });
}
