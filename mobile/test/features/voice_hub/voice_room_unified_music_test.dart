import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_dj_state.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/music_queue_item.dart';
import 'package:canlifal_social/features/voice_hub/music/data/dto/room_song_dto.dart';
import 'package:canlifal_social/features/voice_hub/music/presentation/bloc/room_song_state.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_unified_music.dart';

void main() {
  test('resolve prefers DJ queue when only DJ has data', () {
    final dj = ChatRoomDjState(
      musicQueue: [
        MusicQueueItem(
          id: 'a',
          title: 'A',
          youtubeUrl: 'https://youtu.be/a',
          createdAt: DateTime(2026),
        ),
      ],
      nowPlaying: MusicQueueItem(
        id: 'a',
        title: 'A',
        youtubeUrl: 'https://youtu.be/a',
        createdAt: DateTime(2026),
      ),
      playing: true,
    );
    final view = VoiceRoomUnifiedMusic.resolve(dj: dj, songState: null);
    expect(view.source, VoiceRoomMusicSource.dj);
    expect(view.queue.length, 1);
    expect(view.nowPlaying?.id, 'a');
  });

  test('resolve uses song bloc when DJ queue empty', () {
    const dj = ChatRoomDjState();
    const songState = RoomSongState(
      current: RoomSongDto(
        queueId: 'q1',
        videoId: 'vid1',
        title: 'Bloc Song',
      ),
      queue: [
        RoomSongQueueItemDto(
          queueId: 'q2',
          videoId: 'vid2',
          title: 'Next',
        ),
      ],
    );
    final view = VoiceRoomUnifiedMusic.resolve(dj: dj, songState: songState);
    expect(view.source, VoiceRoomMusicSource.songBloc);
    expect(view.nowPlaying?.title, 'Bloc Song');
    expect(view.queue.length, greaterThanOrEqualTo(1));
  });

  test('waiting excludes now playing', () {
    const dj = ChatRoomDjState(
      musicQueue: [
        MusicQueueItem(
          id: '1',
          title: 'Now',
          youtubeUrl: 'u',
          createdAt: DateTime(2026),
        ),
        MusicQueueItem(
          id: '2',
          title: 'Next',
          youtubeUrl: 'u',
          createdAt: DateTime(2026),
        ),
      ],
      nowPlaying: MusicQueueItem(
        id: '1',
        title: 'Now',
        youtubeUrl: 'u',
        createdAt: DateTime(2026),
      ),
    );
    final view = VoiceRoomUnifiedMusic.resolve(dj: dj, songState: null);
    expect(view.waiting.length, 1);
    expect(view.waiting.first.id, '2');
  });
}
