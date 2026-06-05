import 'chat_room_message.dart';
import 'music_queue_item.dart';

class ChatRoomDjState {
  const ChatRoomDjState({
    this.djUsers = const [],
    this.activeDjId,
    this.ownerPresent = false,
    this.canPlayMusic = false,
    this.canRequestMusic = false,
    this.isOwner = false,
    this.musicUrl,
    this.backgroundImage,
    this.playing = false,
    this.musicQueue = const [],
    this.nowPlaying,
    this.musicRequestCost = 10,
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
    final canRequest = json['canRequestMusic'] == true || canPlay;
    final queueRaw = json['musicQueue'];
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
    return ChatRoomDjState(
      djUsers: users,
      activeDjId: json['activeDjId']?.toString() ?? json['djId']?.toString(),
      ownerPresent: json['ownerPresent'] == true,
      canPlayMusic: canPlay,
      canRequestMusic: canRequest,
      isOwner: json['isOwner'] == true,
      musicUrl: json['musicUrl']?.toString() ?? json['url']?.toString(),
      backgroundImage: json['backgroundImage']?.toString() ??
          json['backgroundUrl']?.toString(),
      playing: json['playing'] == true || json['isPlaying'] == true,
      musicQueue: queue,
      nowPlaying: nowPlaying,
      musicRequestCost: json['musicRequestCost'] as int? ??
          json['cost'] as int? ??
          10,
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
  final bool canRequestMusic;
  final bool isOwner;
  final String? musicUrl;
  final String? backgroundImage;
  final bool playing;
  final List<MusicQueueItem> musicQueue;
  final MusicQueueItem? nowPlaying;
  final int musicRequestCost;
  final int maxMusicQueue;
  final bool musicEnabled;
  final int maxDj;

  int get djCount => djUsers.length;

  ChatRoomDjState copyWith({
    bool? playing,
    String? musicUrl,
    MusicQueueItem? nowPlaying,
    List<MusicQueueItem>? musicQueue,
  }) {
    return ChatRoomDjState(
      djUsers: djUsers,
      activeDjId: activeDjId,
      ownerPresent: ownerPresent,
      canPlayMusic: canPlayMusic,
      canRequestMusic: canRequestMusic,
      isOwner: isOwner,
      musicUrl: musicUrl ?? this.musicUrl,
      backgroundImage: backgroundImage,
      playing: playing ?? this.playing,
      musicQueue: musicQueue ?? this.musicQueue,
      nowPlaying: nowPlaying ?? this.nowPlaying,
      musicRequestCost: musicRequestCost,
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
    int? maxMusicQueue,
    bool? musicEnabled,
    bool? canRequestMusic,
    String? musicUrl,
    bool overwriteNowPlaying = false,
  }) {
    final resolvedNowPlaying = overwriteNowPlaying
        ? nowPlaying
        : (nowPlaying ?? this.nowPlaying);
    final resolvedMusicUrl = musicUrl?.trim().isNotEmpty == true
        ? musicUrl
        : this.musicUrl;
    return ChatRoomDjState(
      djUsers: djUsers,
      activeDjId: activeDjId,
      ownerPresent: ownerPresent,
      canPlayMusic: canPlayMusic,
      canRequestMusic: canRequestMusic ?? this.canRequestMusic,
      isOwner: isOwner,
      musicUrl: resolvedMusicUrl,
      backgroundImage: backgroundImage,
      playing: playing ?? this.playing,
      musicQueue: queue,
      nowPlaying: resolvedNowPlaying,
      musicRequestCost: musicRequestCost ?? this.musicRequestCost,
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

  /// Oynatılacak URL — önce sunucu akışı, yoksa YouTube watch (mobil çözer).
  String? get playbackSource {
    final direct = musicUrl?.trim();
    if (direct != null &&
        direct.isNotEmpty &&
        !_isYoutubeWatchUrl(direct)) {
      return direct;
    }
    final np = nowPlaying?.youtubeUrl.trim() ?? '';
    if (np.isNotEmpty) return np;
    if (direct != null && direct.isNotEmpty) return direct;
    if (musicQueue.isNotEmpty) {
      final first = musicQueue.first.youtubeUrl.trim();
      if (first.isNotEmpty) return first;
    }
    return null;
  }

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
}
