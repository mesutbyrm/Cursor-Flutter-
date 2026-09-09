import '../../domain/entities/chat_room_dj_state.dart';
import '../../domain/entities/chat_room_message.dart';
import '../../domain/entities/music_queue_item.dart';
import '../../music/data/dto/room_song_dto.dart';
import '../../music/presentation/bloc/room_song_state.dart';

/// DJ pipeline + RoomSongBloc tek görünüm — sunucu otoritesi öncelikli.
enum VoiceRoomMusicSource { dj, songBloc, merged }

class VoiceRoomUnifiedMusic {
  const VoiceRoomUnifiedMusic({
    required this.nowPlaying,
    required this.queue,
    required this.waiting,
    required this.source,
    this.playing = false,
    this.progress,
  });

  final MusicQueueItem? nowPlaying;
  final List<MusicQueueItem> queue;
  final List<MusicQueueItem> waiting;
  final VoiceRoomMusicSource source;
  final bool playing;
  final double? progress;

  static VoiceRoomUnifiedMusic resolve({
    required ChatRoomDjState dj,
    RoomSongState? songState,
  }) {
    final djNow = dj.nowPlaying;
    final djQueue = dj.musicQueue;
    final blocCurrent = songState?.current;
    final blocQueue = songState?.queue ?? const <RoomSongQueueItemDto>[];

    final djHasData = djNow != null || djQueue.isNotEmpty;
    final blocHasData = blocCurrent?.hasTrack == true || blocQueue.isNotEmpty;

    if (djHasData && !blocHasData) {
      return _fromDj(dj, source: VoiceRoomMusicSource.dj);
    }
    if (!djHasData && blocHasData) {
      return _fromSongBloc(
        dj: dj,
        songState: songState,
        source: VoiceRoomMusicSource.songBloc,
      );
    }
    if (!djHasData && !blocHasData) {
      return const VoiceRoomUnifiedMusic(
        nowPlaying: null,
        queue: const [],
        waiting: const [],
        source: VoiceRoomMusicSource.dj,
        playing: false,
      );
    }

    // Her iki kaynak dolu — DJ kuyruğu öncelikli; nowPlaying boşsa bloc'tan tamamla.
    final base = _fromDj(dj, source: VoiceRoomMusicSource.merged);
    if (base.nowPlaying != null) return base;

    final blocView = _fromSongBloc(
      dj: dj,
      songState: songState,
      source: VoiceRoomMusicSource.merged,
    );
    if (blocView.nowPlaying == null) return base;

    return VoiceRoomUnifiedMusic(
      nowPlaying: blocView.nowPlaying,
      queue: base.queue.isNotEmpty ? base.queue : blocView.queue,
      waiting: _waitingItems(
        base.queue.isNotEmpty ? base.queue : blocView.queue,
        blocView.nowPlaying ?? base.nowPlaying,
      ),
      source: VoiceRoomMusicSource.merged,
      playing: dj.playing || blocView.playing,
      progress: blocView.progress ?? base.progress,
    );
  }

  static VoiceRoomUnifiedMusic _fromDj(
    ChatRoomDjState dj, {
    required VoiceRoomMusicSource source,
  }) {
    final queue = List<MusicQueueItem>.from(dj.musicQueue);
    final now = dj.nowPlaying ?? (queue.isNotEmpty ? queue.first : null);
    return VoiceRoomUnifiedMusic(
      nowPlaying: now,
      queue: queue,
      waiting: _waitingItems(queue, now),
      source: source,
      playing: dj.playing,
    );
  }

  static VoiceRoomUnifiedMusic _fromSongBloc({
    required ChatRoomDjState dj,
    required RoomSongState? songState,
    required VoiceRoomMusicSource source,
  }) {
    final current = songState?.current;
    final now = current != null && current.hasTrack
        ? _songDtoToItem(current)
        : null;
    final queue = songState?.queue.map(_queueDtoToItem).toList() ?? const [];
    final fullQueue = now != null &&
            !queue.any((e) => e.id == now.id || e.videoIdField == now.videoIdField)
        ? [now, ...queue]
        : queue;
    return VoiceRoomUnifiedMusic(
      nowPlaying: now,
      queue: fullQueue,
      waiting: _waitingItems(fullQueue, now),
      source: source,
      playing: dj.playing || (current?.paused != true && current?.hasTrack == true),
      progress: songState?.progress,
    );
  }

  static List<MusicQueueItem> _waitingItems(
    List<MusicQueueItem> queue,
    MusicQueueItem? nowPlaying,
  ) {
    if (queue.isEmpty) return const [];
    final npId = nowPlaying?.id;
    if (npId == null || npId.isEmpty) {
      if (queue.length <= 1) return const [];
      return queue.sublist(1);
    }
    return queue.where((e) => e.id != npId).toList();
  }

  static MusicQueueItem _songDtoToItem(RoomSongDto dto) {
    final vid = dto.resolvedVideoId ?? dto.videoId ?? '';
    final url = dto.musicUrl?.trim().isNotEmpty == true
        ? dto.musicUrl!
        : (dto.youtubeUrl?.trim().isNotEmpty == true
            ? dto.youtubeUrl!
            : (vid.isNotEmpty ? 'https://www.youtube.com/watch?v=$vid' : ''));
    ChatRoomUserRef? requester;
    if (dto.ownerId != null && dto.ownerId!.isNotEmpty) {
      requester = ChatRoomUserRef(
        id: dto.ownerId!,
        name: dto.ownerName ?? 'İsteyen',
      );
    }
    return MusicQueueItem(
      id: dto.queueId ?? vid,
      title: dto.title ?? 'Şarkı',
      youtubeUrl: url,
      thumbUrl: dto.thumbnail,
      createdAt: DateTime.now(),
      requestedBy: requester,
      uploader: dto.channel,
      duration: dto.durationSec?.toString(),
      withVideo: dto.isVideoRequest,
      videoIdField: vid.isNotEmpty ? vid : null,
    );
  }

  static MusicQueueItem _queueDtoToItem(RoomSongQueueItemDto dto) {
    final vid = dto.videoId.trim();
    final url = dto.musicUrl?.trim().isNotEmpty == true
        ? dto.musicUrl!
        : (dto.youtubeUrl?.trim().isNotEmpty == true
            ? dto.youtubeUrl!
            : (vid.isNotEmpty ? 'https://www.youtube.com/watch?v=$vid' : ''));
    ChatRoomUserRef? requester;
    if (dto.ownerId != null && dto.ownerId!.isNotEmpty) {
      requester = ChatRoomUserRef(
        id: dto.ownerId!,
        name: dto.ownerName ?? 'İsteyen',
      );
    }
    return MusicQueueItem(
      id: dto.queueId.isNotEmpty ? dto.queueId : vid,
      title: dto.title,
      youtubeUrl: url,
      thumbUrl: dto.thumbnail,
      createdAt: DateTime.now(),
      requestedBy: requester,
      uploader: dto.channel,
      duration: dto.duration,
      withVideo: dto.isVideoRequest,
      videoIdField: vid.isNotEmpty ? vid : null,
    );
  }
}
