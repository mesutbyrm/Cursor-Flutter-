import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/domain/entities/room_music_history_entry.dart';

void main() {
  test('parses /api/music/history response', () {
    final items = RoomMusicHistoryEntry.listFromResponse({
      'history': [
        {
          'id': 'm1',
          'videoId': 'abc',
          'title': 'Şarkı',
          'duration': '3:21',
          'requestType': 'video',
          'isPaid': true,
          'playedAt': '2026-10-07T10:00:00.000Z',
          'requestedBy': {'id': 'u1', 'name': 'Ayşe', 'image': null},
        },
        {'id': 'm2', 'videoId': '', 'title': ''},
      ],
      'count': 2,
    });
    expect(items, hasLength(1));
    final e = items.single;
    expect(e.title, 'Şarkı');
    expect(e.isVideo, isTrue);
    expect(e.isPaid, isTrue);
    expect(e.requestedByName, 'Ayşe');
    expect(e.playedAt, isNotNull);
  });

  test('empty / malformed body → empty list', () {
    expect(RoomMusicHistoryEntry.listFromResponse(null), isEmpty);
    expect(RoomMusicHistoryEntry.listFromResponse({'error': 'x'}), isEmpty);
  });
}
