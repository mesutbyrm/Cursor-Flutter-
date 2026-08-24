import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/music/domain/song_playback_fields.dart';
import 'package:canlifal_social/features/voice_hub/music/presentation/bloc/room_song_bloc.dart';
import 'package:canlifal_social/features/voice_hub/music/presentation/bloc/room_song_event.dart';
import 'package:canlifal_social/features/voice_hub/music/data/dto/room_song_dto.dart';

void main() {
  group('SongPlaybackFields', () {
    test('resolves musicUrl first', () {
      final fields = SongPlaybackFields.fromJson({
        'musicUrl': 'https://canlifal.com/api/chat/youtube-audio?v=abc',
        'videoId': 'ignored_if_musicUrl',
      });
      expect(fields.resolvedStreamUrl, contains('youtube-audio'));
      expect(fields.hasPlayableSource, isTrue);
    });

    test('falls back to youtubeUrl then videoId', () {
      final fields = SongPlaybackFields.fromJson({
        'youtubeUrl': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      });
      expect(fields.videoId, 'dQw4w9WgXcQ');
      expect(fields.resolvedStreamUrl, contains('dQw4w9WgXcQ'));
    });

    test('videoId alone is playable', () {
      final fields = SongPlaybackFields.fromJson({
        'videoId': 'abc123xyz01',
      });
      expect(fields.hasPlayableSource, isTrue);
      expect(fields.resolvedStreamUrl, contains('abc123xyz01'));
    });

    test('detects playMode video', () {
      final fields = SongPlaybackFields.fromJson({
        'videoId': 'x',
        'playMode': 'video',
      });
      expect(fields.isVideoRequest, isTrue);
    });

    test('resolvedAudioStreamUrl rejects youtube watch pages', () {
      final fields = SongPlaybackFields.fromJson({
        'musicUrl': 'https://www.youtube.com/watch?v=abc',
        'audioUrl': 'https://canlifal.com/api/chat/youtube-audio?v=abc',
      });
      expect(fields.resolvedAudioStreamUrl, contains('youtube-audio'));
    });

    test('resolvedVideoStreamUrl prefers videoUrl', () {
      final fields = SongPlaybackFields.fromJson({
        'videoUrl': 'https://cdn.example.com/music.mp4',
        'musicUrl': 'https://canlifal.com/api/chat/youtube-audio?v=abc',
        'playMode': 'video',
      });
      expect(fields.resolvedVideoStreamUrl, contains('cdn.example.com'));
    });
  });

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

    test('parses song_started with musicUrl only', () {
      final ev = RoomSongBloc.eventFromSse({
        'type': 'song_started',
        'currentSong': {
          'musicUrl': 'https://canlifal.com/stream/test',
          'title': 'Audio only',
        },
      });
      expect(ev, isA<RoomSongStarted>());
      final started = ev! as RoomSongStarted;
      expect(started.song.hasTrack, isTrue);
      expect(started.song.musicUrl, contains('stream'));
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

    test('parses unified dj payload', () {
      final ev = RoomSongBloc.eventFromSse({
        'type': 'dj',
        'playing': true,
        'nowPlaying': {
          'videoId': 'abc123',
          'title': 'Test',
          'elapsedSeconds': 42,
        },
        'musicQueue': [
          {'id': 'q1', 'videoId': 'v1', 'title': 'A'},
        ],
      });
      expect(ev, isA<RoomSongStarted>());
    });

    test('parses player_state with musicUrl', () {
      final ev = RoomSongBloc.eventFromSse({
        'type': 'player_state',
        'playing': true,
        'musicUrl': 'https://canlifal.com/api/chat/youtube-audio?v=xyz',
        'title': 'Live',
      });
      expect(ev, isA<RoomSongStarted>());
    });

    test('parses song_changed alias', () {
      final ev = RoomSongBloc.eventFromSse({
        'type': 'song_changed',
        'playing': true,
        'currentSong': {
          'videoId': 'newTrack',
          'title': 'Changed',
        },
      });
      expect(ev, isA<RoomSongStarted>());
    });
  });

  group('RoomSongDto', () {
    test('hasTrack with musicUrl only', () {
      final dto = RoomSongDto.fromJson({
        'musicUrl': 'https://example.com/audio.mp3',
        'title': 'Test',
      });
      expect(dto.hasTrack, isTrue);
    });

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
