import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/music/presentation/bloc/room_song_bloc.dart';
import 'package:canlifal_social/features/voice_hub/music/presentation/bloc/room_song_event.dart';
import 'package:canlifal_social/features/voice_hub/music/data/dto/room_song_dto.dart';

void main() {
  group('RoomSongBloc.eventFromSse', () {
    test('parses song_started', () {
      final ev = RoomSongBloc.eventFromSse({
        'type': 'song_started',
        'currentSong': {
          'videoId': 'abc123',
          'title': 'Test',
          'elapsedMs': 0,
          'paused': false,
          'serverTime': 1_700_000_000_000,
        },
        'elapsed': 0,
      });
      expect(ev, isA<RoomSongStarted>());
      final started = ev! as RoomSongStarted;
      expect(started.song.videoId, 'abc123');
    });

    test('parses queue_updated', () {
      final ev = RoomSongBloc.eventFromSse({
        'type': 'queue_updated',
        'queue': [
          {'queueId': 'q1', 'videoId': 'v1', 'title': 'A'},
        ],
      });
      expect(ev, isA<RoomSongQueueUpdated>());
    });

    test('returns null for unknown type', () {
      expect(RoomSongBloc.eventFromSse({'type': 'dj'}), isNull);
    });
  });

  group('RoomSongDto', () {
    test('resolvedElapsedSeconds when playing', () {
      final now = DateTime.fromMillisecondsSinceEpoch(10_000);
      final dto = RoomSongDto(
        videoId: 'x',
        startedAtMs: 5_000,
        elapsedMs: 1000,
        paused: false,
      );
      expect(dto.resolvedElapsedSeconds(now: now), 6.0);
    });

    test('resolvedElapsedSeconds when paused', () {
      final dto = RoomSongDto(
        videoId: 'x',
        elapsedMs: 4500,
        paused: true,
      );
      expect(dto.resolvedElapsedSeconds(), 4.5);
    });
  });
}
