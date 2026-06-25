import 'chat_room_message.dart';
import 'music_queue_item.dart';

class ChatRoomDjState {
  const ChatRoomDjState({
    this.djUsers = const [],
    this.activeDjId,
    this.ownerPresent = false,
    this.canPlayMusic = false,
    this.canControlMusic = false,
    this.canRequestMusic = false,
    this.isOwner = false,
    this.musicUrl,
    this.backgroundImage,
    this.playing = false,
    this.musicQueue = const [],
    this.nowPlaying,
    this.musicRequestCost = 10,
    this.videoRequestCost = 20,
    this.maxMusicQueue = 20,
    this.musicEnabled = true,
    this.maxDj = 5,
  });

  factory ChatRoomDjState.fromJson(Map<String, dynamic> json) {
    final users = <ChatRoomUserRef>[];
    final raw = json['djUsers'];
    if (raw is List) {
      for (final u in raw) {
        if (u is Map) {
          users.add(ChatRoomUserRef.fromJson(Map<String, dynamic>.from(u)));
        }
      }
    }
    final canPlay = json['canPlayMusic'] == true ||
        json['canControlMusic'] == true ||
        json['canDj'] == true;
    final canRequest = json['canRequestMusic'] == true;
    final queueRaw = json['musicQueue'] ?? json['queue'] ?? json['items'];
    final queue = <MusicQueueItem>[];
    if (queueRaw is List) {
      for (final e in queueRaw) {
        if (e is Map) {
          queue.add(MusicQueueItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    MusicQueueItem? nowPlaying;
    final np = json['nowPlaying'];
    if (np is Map) {
      nowPlaying = MusicQueueItem.fromJson(Map<String, dynamic>.from(np));
    } else if (json['playing'] == true && queue.isNotEmpty) {
      nowPlaying = queue.first;
    }
    final canControl = json['canControlMusic'] == true || canPlay;
    final costs = _parseRequestCosts(json);
    return ChatRoomDjState(
      djUsers: users,
      activeDjId: json['activeDjId']?.toString() ?? json['djId']?.toString(),
      ownerPresent: json['ownerPresent'] == true,
      canPlayMusic: canPlay,
      canControlMusic: canControl,
      canRequestMusic: canRequest,
      isOwner: json['isOwner'] == true,
      musicUrl: json['musicUrl']?.toString() ?? json['url']?.toString(),
      backgroundImage: json['backgroundImage']?.toString() ??
          json['backgroundUrl']?.toString(),
      playing: json['playing'] == true || json['isPlaying'] == true,
      musicQueue: queue,
      nowPlaying: nowPlaying,
      musicRequestCost: costs.audio,
      videoRequestCost: costs.video,
      maxMusicQueue: json['maxMusicQueue'] as int? ??
          json['maxQueueLength'] as int? ??
          20,
      musicEnabled: json['musicEnabled'] != false,
      maxDj: json['maxDj'] as int? ?? 5,
    );
  }

  final List<ChatRoomUserRef> djUsers;
  final String? activeDjId;
  final bool ownerPresent;
  final bool canPlayMusic;
  final bool canControlMusic;
  final bool canRequestMusic;
  final bool isOwner;
  final String? musicUrl;
  final String? backgroundImage;
  final bool playing;
  final List<MusicQueueItem> musicQueue;
  final MusicQueueItem? nowPlaying;
  final int musicRequestCost;
  final int videoRequestCost;
  final int maxMusicQueue;
  final bool musicEnabled;
  final int maxDj;

  int get djCount => djUsers.length;

  ChatRoomDjState copyWith({
    List<ChatRoomUserRef>? djUsers,
    bool? playing,
    String? musicUrl,
    bool clearMusicUrl = false,
    MusicQueueItem? nowPlaying,
    bool clearNowPlaying = false,
    List<MusicQueueItem>? musicQueue,
  }) {
    return ChatRoomDjState(
      djUsers: djUsers ?? this.djUsers,
      activeDjId: activeDjId,
      ownerPresent: ownerPresent,
      canPlayMusic: canPlayMusic,
      canControlMusic: canControlMusic,
      canRequestMusic: canRequestMusic,
      isOwner: isOwner,
      musicUrl: clearMusicUrl ? null : (musicUrl ?? this.musicUrl),
      backgroundImage: backgroundImage,
      playing: playing ?? this.playing,
      musicQueue: musicQueue ?? this.musicQueue,
      nowPlaying: clearNowPlaying ? null : (nowPlaying ?? this.nowPlaying),
      musicRequestCost: musicRequestCost,
      videoRequestCost: videoRequestCost,
      maxMusicQueue: maxMusicQueue,
      musicEnabled: musicEnabled,
      maxDj: maxDj,
    );
  }

  ChatRoomDjState mergeMusicQueue({
    required List<MusicQueueItem> queue,
    MusicQueueItem? nowPlaying,
    bool? playing,
    int? musicRequestCost,
    int? videoRequestCost,
    int? maxMusicQueue,
    bool? musicEnabled,
    bool? canRequestMusic,
    String? musicUrl,
    bool overwriteNowPlaying = false,
  }) {
    final resolvedNowPlaying = overwriteNowPlaying
        ? nowPlaying
        : (nowPlaying ?? this.nowPlaying);
    final trackChanged = overwriteNowPlaying &&
        nowPlaying != null &&
        nowPlaying.id != this.nowPlaying?.id;
    final resolvedMusicUrl = musicUrl?.trim().isNotEmpty == true
        ? musicUrl
        : (trackChanged ? null : this.musicUrl);
    return ChatRoomDjState(
      djUsers: djUsers,
      activeDjId: activeDjId,
      ownerPresent: ownerPresent,
      canPlayMusic: canPlayMusic,
      canControlMusic: canControlMusic,
      canRequestMusic: canRequestMusic ?? this.canRequestMusic,
      isOwner: isOwner,
      musicUrl: resolvedMusicUrl,
      backgroundImage: backgroundImage,
      playing: playing ?? this.playing,
      musicQueue: queue,
      nowPlaying: resolvedNowPlaying,
      musicRequestCost: musicRequestCost ?? this.musicRequestCost,
      videoRequestCost: videoRequestCost ?? this.videoRequestCost,
      maxMusicQueue: maxMusicQueue ?? this.maxMusicQueue,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      maxDj: maxDj,
    );
  }

  int queuePositionFor(String? itemId) {
    if (itemId == null) return musicQueue.length;
    final idx = musicQueue.indexWhere((e) => e.id == itemId);
    return idx >= 0 ? idx + 1 : musicQueue.length;
  }

  /// Sunucunun kısa ömürlü YouTube CDN linkleri — mobilde doğrudan oynatılmaz.
  static bool isEphemeralStreamUrl(String url) {
    final lower = url.trim().toLowerCase();
    return lower.contains('googlevideo.com') || lower.contains('youtube.com/api/');
  }

  /// Herhangi bir kaynaktan YouTube watch URL'si (mobil çözümleme girişi).
  static String? youtubePlaybackSeed(String? url) {
    final trimmed = url?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (_isYoutubeWatchUrl(trimmed)) return trimmed;
    final id = videoIdFromLoose(trimmed);
    if (id != null && id.isNotEmpty) {
      return 'https://www.youtube.com/watch?v=$id';
    }
    if (isEphemeralStreamUrl(trimmed)) return null;
    return trimmed;
  }

  static String? videoIdFromLoose(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length <= 15 && !trimmed.contains('/')) return trimmed;
    final watch = RegExp(r'(?:v=|youtu\.be/)([a-zA-Z0-9_-]{6,})').firstMatch(trimmed);
    if (watch != null) return watch.group(1);
    try {
      final u = Uri.parse(trimmed);
      if (u.host.contains('googlevideo.com')) {
        return u.queryParameters['v'] ?? u.queryParameters['id'];
      }
    } catch (_) {}
    return null;
  }

  /// Mobil çözümleme — YouTube watch / videoId (sunucu googlevideo değil).
  String? get playbackResolveSeed {
    final np = nowPlaying?.youtubeUrl.trim() ?? '';
    if (np.isNotEmpty) {
      final seed = youtubePlaybackSeed(np);
      if (seed != null) return seed;
    }
    if (musicQueue.isNotEmpty) {
      final first = musicQueue.first.youtubeUrl.trim();
      if (first.isNotEmpty) {
        final seed = youtubePlaybackSeed(first);
        if (seed != null) return seed;
      }
    }
    return youtubePlaybackSeed(musicUrl);
  }

  /// Oynatma girişi — her zaman YouTube watch; sunucu CDN'i atlanır.
  String? get playbackSource => playbackResolveSeed;

  /// YouTube watch URL — akış çözümü mobilde yapılır (web iframe farkı).
  String? get youtubeFallbackSource {
    final np = nowPlaying?.youtubeUrl.trim() ?? '';
    if (np.isNotEmpty) return np;
    if (musicQueue.isNotEmpty) {
      final first = musicQueue.first.youtubeUrl.trim();
      if (first.isNotEmpty) return first;
    }
    final direct = musicUrl?.trim();
    if (direct != null && _isYoutubeWatchUrl(direct)) return direct;
    return null;
  }

  static bool _isYoutubeWatchUrl(String url) =>
      url.contains('youtube.com') || url.contains('youtu.be');

  static ({int audio, int video}) _parseRequestCosts(Map<String, dynamic> json) {
    final raw = json['requestCosts'];
    if (raw is Map) {
      final audio = _asInt(raw['audio']);
      final video = _asInt(raw['video']);
      if (audio > 0 && video > 0) {
        return (audio: audio, video: video);
      }
      if (audio > 0) {
        return (audio: audio, video: video > 0 ? video : audio * 2);
      }
      if (video > 0) {
        return (audio: 10, video: video);
      }
    }
    final audioCost = _asInt(json['musicRequestCost'] ?? json['cost']);
    final resolvedAudio = audioCost > 0 ? audioCost : 10;
    final videoCost = _asInt(
      json['videoRequestCost'] ?? json['videoMusicRequestCost'] ?? json['videoCost'],
    );
    return (
      audio: resolvedAudio,
      video: videoCost > 0 ? videoCost : resolvedAudio * 2,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
