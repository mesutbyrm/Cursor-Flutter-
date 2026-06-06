import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/voice_staff_rank.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/token_storage.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../data/datasources/chat_room_remote_datasource.dart';
import '../../data/services/voice_room_debug_log.dart';
import '../../data/services/voice_room_gift_socket.dart';
import '../../data/services/voice_room_sse_service.dart';
import '../../data/youtube_music_search_cache.dart';
import '../../../live/presentation/gifts/providers/live_gift_providers.dart';
import '../../domain/entities/chat_room_dj_state.dart';
import '../../domain/entities/chat_room_message.dart';
import '../../domain/voice_music_sync.dart';
import '../../domain/voice_official_join.dart';
import '../utils/voice_room_permissions.dart';
import '../widgets/voice_room/voice_room_music_request_flash.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/music_queue_item.dart';
import '../../domain/entities/popular_music_suggestion.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/youtube_stream_resolver.dart';
import '../audio/voice_room_music_audio_session.dart';
import '../services/voice_room_dj_player.dart';
import 'voice_gift_providers.dart';
import 'voice_room_ui_provider.dart';

final youtubeStreamResolverProvider = Provider<YoutubeStreamResolver>((ref) {
  return YoutubeStreamResolver(ref.watch(dioProvider));
});

final youtubeMusicSearchCacheProvider = Provider<YoutubeMusicSearchCache>((ref) {
  return YoutubeMusicSearchCache();
});

final chatRoomRemoteProvider = Provider<ChatRoomRemoteDataSource>((ref) {
  return ChatRoomRemoteDataSource(
    ref.watch(dioProvider),
    searchCache: ref.watch(youtubeMusicSearchCacheProvider),
  );
});

final voiceRoomSseServiceProvider = Provider<VoiceRoomSseService>((ref) {
  final s = VoiceRoomSseService();
  ref.onDispose(s.disconnect);
  return s;
});

final voiceRoomDjPlayerProvider = Provider<VoiceRoomDjPlayer>((ref) {
  final p = VoiceRoomDjPlayer(ref.watch(youtubeStreamResolverProvider));
  ref.onDispose(p.dispose);
  return p;
});

String? _roleSymbolForUser(UserEntity user) {
  final rank = VoiceStaffRankParser.resolve(
    username: user.username,
    chatRole: user.role,
  );
  return VoiceStaffRankParser.prefixSymbol(rank);
}

class VoiceRoomLiveState {
  const VoiceRoomLiveState({
    this.messages = const [],
    this.presence = const [],
    this.dj = const ChatRoomDjState(),
    this.loading = true,
    this.error,
    this.sending = false,
    this.enterBanner,
    this.musicRequestFlash,
    this.backgroundUrl,
    this.selfInRoom = false,
    this.sseConnected = false,
    this.openCommandsPanel = false,
  });

  final List<ChatRoomMessage> messages;
  final List<ChatRoomPresence> presence;
  final ChatRoomDjState dj;
  final bool loading;
  final String? error;
  final bool sending;
  final String? enterBanner;
  final String? musicRequestFlash;
  final String? backgroundUrl;
  final bool selfInRoom;
  final bool sseConnected;
  final bool openCommandsPanel;

  int onlineCountFor(VoiceRoomEntity room) {
    if (presence.isNotEmpty) return presence.length;
    if (room.displayOnline > 0) return room.displayOnline;
    return selfInRoom ? 1 : 0;
  }

  VoiceRoomLiveState copyWith({
    List<ChatRoomMessage>? messages,
    List<ChatRoomPresence>? presence,
    ChatRoomDjState? dj,
    bool? loading,
    String? error,
    bool? sending,
    String? enterBanner,
    bool clearEnterBanner = false,
    String? musicRequestFlash,
    bool clearMusicRequestFlash = false,
    String? backgroundUrl,
    bool? selfInRoom,
    bool? sseConnected,
    bool? openCommandsPanel,
    bool clearOpenCommandsPanel = false,
    bool clearError = false,
  }) {
    return VoiceRoomLiveState(
      messages: messages ?? this.messages,
      presence: presence ?? this.presence,
      dj: dj ?? this.dj,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      sending: sending ?? this.sending,
      enterBanner: clearEnterBanner ? null : (enterBanner ?? this.enterBanner),
      musicRequestFlash: clearMusicRequestFlash
          ? null
          : (musicRequestFlash ?? this.musicRequestFlash),
      backgroundUrl: backgroundUrl ?? this.backgroundUrl,
      selfInRoom: selfInRoom ?? this.selfInRoom,
      sseConnected: sseConnected ?? this.sseConnected,
      openCommandsPanel: clearOpenCommandsPanel
          ? false
          : (openCommandsPanel ?? this.openCommandsPanel),
    );
  }
}

class VoiceRoomLiveController extends AutoDisposeFamilyNotifier<
    VoiceRoomLiveState, VoiceRoomEntity> {
  Timer? _poll;
  Timer? _presenceHeartbeat;
  Timer? _enterBannerTimer;
  Timer? _musicRequestFlashTimer;
  var _pollPaused = false;
  var _pollTick = 0;
  String? _lastDjPlaybackSignature;
  VoiceRoomGiftSocket? _giftSocket;
  final Set<String> _shownEntranceKeys = {};
  final Set<String> _shownMusicRequestFlashKeys = {};

  /// Prisma cuid — slug değil.
  String get _roomKey => arg.apiRoomKey;

  DateTime? get _lastMessageAt {
    if (state.messages.isEmpty) return null;
    return state.messages.map((m) => m.createdAt).reduce(
          (a, b) => a.isAfter(b) ? a : b,
        );
  }

  List<ChatRoomMessage> _mergeMessages(
    List<ChatRoomMessage> current,
    List<ChatRoomMessage> fetched,
  ) {
    final byId = <String, ChatRoomMessage>{};
    for (final m in current) {
      byId[m.id] = m;
    }
    for (final m in fetched) {
      final dup = byId.entries.where(
        (e) =>
            e.key.startsWith('local-') &&
            e.value.content == m.content &&
            e.value.user?.id == m.user?.id,
      );
      for (final d in dup) {
        byId.remove(d.key);
      }
      byId[m.id] = m;
    }
    final merged = byId.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return merged;
  }

  bool _markEntranceOnce(String raw) {
    final key = VoiceOfficialJoin.entranceDedupeKey(raw, roomName: arg.nameTr);
    if (_shownEntranceKeys.contains(key)) return false;
    _shownEntranceKeys.add(key);
    return true;
  }

  @override
  VoiceRoomLiveState build(VoiceRoomEntity room) {
    ref.keepAlive();
    ref.onDispose(() {
      _poll?.cancel();
      _presenceHeartbeat?.cancel();
      _enterBannerTimer?.cancel();
      _musicRequestFlashTimer?.cancel();
      _giftSocket?.disconnect();
      _leavePresence();
      ref.read(voiceRoomSseServiceProvider).disconnect();
      ref.read(voiceRoomDjPlayerProvider).stop();
    });
    Future.microtask(() async {
      await VoiceRoomMusicAudioSession.ensureConfigured();
      ref.invalidate(coinBalanceProvider);
      ref.invalidate(walletBalancesProvider);
      await _joinPresence();
      await refresh(includeDj: true);
      _startSse();
      _startGiftSocket();
      _warmBackgrounds();
      final player = ref.read(voiceRoomDjPlayerProvider);
      player.onTrackComplete = () => unawaited(_onDjTrackComplete());
    });
    _schedulePoll();
    _presenceHeartbeat = Timer.periodic(const Duration(seconds: 45), (_) {
      if (!state.sseConnected && state.selfInRoom) {
        unawaited(_presenceHeartbeatTick());
      }
    });
    return VoiceRoomLiveState(
      backgroundUrl: room.backgroundImageUrl?.trim().isNotEmpty == true
          ? room.backgroundImageUrl
          : null,
    );
  }

  List<ChatRoomPresence> _mergeSelf(List<ChatRoomPresence> list) {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return list;
    if (list.any((p) => p.id == user.id)) return list;
    return [
      ...list,
      ChatRoomPresence(
        id: user.id,
        name: user.display,
        nickname: user.username,
        image: user.avatarUrl,
        chatRole: user.role ?? 'listener',
        roleSymbol: _roleSymbolForUser(user),
      ),
    ];
  }

  Future<void> _joinPresence() async {
    if (_roomKey.isEmpty) {
      state = state.copyWith(
        loading: false,
        error: 'Geçersiz oda kimliği',
      );
      return;
    }
    try {
      VoiceRoomDebugLog.log('api.presence.join', {'room': _roomKey});
      final joined = await ref.read(chatRoomRemoteProvider).joinPresence(_roomKey);
      final merged = _mergeSelf(joined);
      VoiceRoomDebugLog.log('api.presence.join.ok', {
        'count': merged.length,
        'roomId': _roomKey,
      });
      state = state.copyWith(
        presence: merged,
        selfInRoom: true,
        loading: false,
        clearError: true,
      );
    } on Object catch (e) {
      VoiceRoomDebugLog.log('api.presence.join.fail', {'error': e.toString()});
      final msg = ApiException.userMessage(e);
      if (msg.toLowerCase().contains('yasak') ||
          msg.contains('403') ||
          msg.toLowerCase().contains('forbidden')) {
        state = state.copyWith(
          loading: false,
          error: 'Bu odadan yasaklandınız',
        );
        return;
      }
      state = state.copyWith(
        loading: false,
        error: msg.contains('401') || msg.toLowerCase().contains('oturum')
            ? 'Listede görünmek için tekrar giriş yapın.'
            : msg,
      );
    }
  }

  Future<void> _leavePresence() async {
    if (_roomKey.isEmpty) return;
    try {
      await ref.read(chatRoomRemoteProvider).leavePresence(_roomKey);
    } catch (_) {}
  }

  Future<void> _presenceHeartbeatTick() async {
    if (_roomKey.isEmpty) return;
    try {
      VoiceRoomDebugLog.log('api.presence.heartbeat', {'room': _roomKey});
      final list =
          await ref.read(chatRoomRemoteProvider).joinPresence(_roomKey);
      final merged = _mergeSelf(list);
      state = state.copyWith(presence: merged, selfInRoom: true);
    } catch (e) {
      VoiceRoomDebugLog.log('api.presence.heartbeat.fail', {
        'error': e.toString(),
      });
    }
  }

  void _startSse() {
    if (_roomKey.isEmpty) return;
    final storage = ref.read(tokenStorageProvider);
    VoiceRoomDebugLog.log('sse.subscribe', {
      'url': VoiceRoomSseService.streamUrlFor(_roomKey),
      'roomId': _roomKey,
    });
    ref.read(voiceRoomSseServiceProvider).connect(
      roomId: _roomKey,
      accessToken: storage.readAccess,
      onConnected: () {
        if (!state.sseConnected) {
          state = state.copyWith(sseConnected: true);
        }
      },
      onDjUpdate: (payload) {
        if (payload != null && payload.isNotEmpty) {
          unawaited(_applyDjRealtimePayload(payload));
        } else {
          unawaited(refresh(includeDj: true));
        }
      },
      onMessage: (msg) {
        final exists = state.messages.any((m) => m.id == msg.id);
        if (exists) return;
        state = state.copyWith(messages: [...state.messages, msg]);
        _onMusicRelatedChatMessage(msg);
        if (msg.kind == ChatMessageKind.systemJoin &&
            VoiceOfficialJoin.isOfficialEntrance(msg.content) &&
            _markEntranceOnce(msg.content)) {
          _showEnterBanner(msg.content);
        }
      },
      onPresence: (users) {
        final merged = _mergeSelf(users);
        final wasSse = state.sseConnected;
        state = state.copyWith(
          presence: merged,
          sseConnected: true,
          selfInRoom: true,
        );
        if (!wasSse) _schedulePoll();
      },
    );
  }

  void _schedulePoll() {
    _poll?.cancel();
    _pollTick = 0;
    final sse = state.sseConnected;
    final interval = sse ? 15 : 8;
    _poll = Timer.periodic(Duration(seconds: interval), (_) {
      if (_pollPaused) return;
      _pollTick++;
      final fullDj = !sse || (_pollTick % 3 == 0);
      unawaited(refresh(includeDj: fullDj));
    });
  }

  void _startGiftSocket() {
    if (_roomKey.isEmpty) return;
    _giftSocket?.disconnect();
    final storage = ref.read(tokenStorageProvider);
    final slug = arg.slug.trim();
    _giftSocket = VoiceRoomGiftSocket(ref.read(liveGiftsRemoteProvider));
    VoiceRoomDebugLog.log('socket.dj.subscribe', {'room': _roomKey});
    ref.read(voiceRoomGiftRealtimeProvider).setSocketPreferred(true);
    _giftSocket!.connect(
      roomId: _roomKey,
      alternateRoomId: slug.isNotEmpty && slug != _roomKey ? slug : null,
      onEvent: (event) {
        ref.read(voiceRoomGiftRealtimeProvider).publishRemote(event);
      },
      onDjUpdate: (payload) => unawaited(_applyDjRealtimePayload(payload)),
      accessToken: storage.readAccess,
    );
  }

  String _djPlaybackSignature(ChatRoomDjState dj, {required bool muted}) {
    final effective = _djWithQueuePlaybackFallback(dj);
    final url = effective.playbackSource ?? '';
    return '${effective.playing}|$url|${effective.musicUrl}|'
        '${effective.nowPlaying?.id}|${effective.musicQueue.length}|'
        '${effective.musicEnabled}|$muted';
  }

  void clearOpenCommandsPanel() {
    if (state.openCommandsPanel) {
      state = state.copyWith(clearOpenCommandsPanel: true);
    }
  }

  static bool _isLocalHelpCommand(String text) {
    final t = text.trim().toLowerCase();
    return t == '!yardım' ||
        t == '!yardim' ||
        t == '!komutlar' ||
        t == '/yardım' ||
        t == '/yardim' ||
        t == '/komutlar';
  }

  Future<void> refresh({bool includeDj = true}) async {
    if (_roomKey.isEmpty) return;
    final room = arg;
    final remote = ref.read(chatRoomRemoteProvider);
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user != null && !state.selfInRoom) {
      unawaited(_joinPresence());
    }
    Object? refreshError;
    try {
      final since = _lastMessageAt?.toUtc().toIso8601String();
      List<ChatRoomMessage> fetchedMsgs = state.messages;
      List<ChatRoomPresence> presence = state.presence;
      ChatRoomDjState dj = state.dj;

      final results = await Future.wait<Object?>([
        remote.fetchMessages(_roomKey, since: since).catchError((Object e) {
          refreshError ??= e;
          return state.messages;
        }),
        remote.fetchPresence(_roomKey).catchError((Object e) {
          refreshError ??= e;
          return state.presence;
        }),
      ]);
      fetchedMsgs = results[0]! as List<ChatRoomMessage>;
      presence = results[1]! as List<ChatRoomPresence>;

      String? bgFromDj;
      if (includeDj) {
        try {
          dj = await remote.fetchDj(_roomKey);
        } catch (_) {}
        dj = await _mergeMusicQueueIntoDj(dj);
        final ui = ref.read(voiceRoomUiProvider);
        final sig = _djPlaybackSignature(
          dj,
          muted: !ui.backgroundMusicEnabled,
        );
        if (sig != _lastDjPlaybackSignature) {
          dj = await _applyDjPlayback(dj);
        }
        bgFromDj = dj.backgroundImage?.trim();
      }
      presence = _mergeSelf(presence);
      final messages = _mergeMessages(state.messages, fetchedMsgs);
      state = state.copyWith(
        messages: messages,
        presence: presence,
        dj: includeDj ? dj : state.dj,
        loading: false,
        error: refreshError != null
            ? ApiException.userMessage(refreshError!)
            : null,
        clearError: refreshError == null,
        backgroundUrl: (bgFromDj != null && bgFromDj.isNotEmpty)
            ? bgFromDj
            : (state.backgroundUrl?.isNotEmpty == true)
                ? state.backgroundUrl
                : room.backgroundImageUrl,
        selfInRoom: state.selfInRoom || presence.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: ApiException.userMessage(e),
      );
    }
  }

  Future<void> _onDjTrackComplete() async {
    final perms = _permissions();
    final canAdvance =
        perms.canManageDj || perms.isRoomOwner || state.dj.canPlayMusic;
    if (!canAdvance) {
      VoiceRoomDebugLog.log('music.track_complete.listener_only');
      return;
    }
    try {
      VoiceRoomDebugLog.log('music.track_complete.advance');
      await ref.read(chatRoomRemoteProvider).advanceMusicQueue(
            _roomKey,
          );
      await refresh();
    } catch (e) {
      VoiceRoomDebugLog.log('music.track_complete.fail', {'error': '$e'});
    }
  }

  Future<void> _warmBackgrounds() async {
    try {
      final urls = await ref.read(chatRoomRemoteProvider).fetchBackgrounds();
      if (urls.isEmpty) return;
      state = state.copyWith(
        backgroundUrl: state.backgroundUrl?.isNotEmpty == true
            ? state.backgroundUrl
            : urls.first,
      );
    } catch (_) {}
  }

  Future<ChatRoomDjState> _mergeMusicQueueIntoDj(ChatRoomDjState dj) async {
    try {
      final mq = await ref.read(chatRoomRemoteProvider).fetchMusicQueue(_roomKey);
      return dj.mergeMusicQueue(
        queue: mq.queue,
        nowPlaying: mq.nowPlaying,
        playing: mq.playing,
        musicRequestCost: mq.cost,
        maxMusicQueue: mq.maxMusicQueue,
        musicEnabled: mq.musicEnabled,
        canRequestMusic: mq.canRequestMusic,
        musicUrl: mq.musicUrl,
        overwriteNowPlaying: mq.nowPlaying != null,
      );
    } catch (_) {
      return dj;
    }
  }

  Future<void> _applyDjRealtimePayload(Map<String, dynamic> payload) async {
    VoiceRoomDebugLog.log('music.realtime.recv', {
      'playing': payload['playing'],
      'hasUrl': payload['musicUrl'] != null,
      'hasQueue': payload['queue'] != null,
      'type': payload['type'],
    });
    var dj = state.dj;
    if (payload.containsKey('playing')) {
      dj = dj.copyWith(playing: payload['playing'] == true);
    }
    if (payload['musicUrl'] is String) {
      final url = payload['musicUrl'] as String;
      if (url.isNotEmpty) dj = dj.copyWith(musicUrl: url);
    }
    if (payload['nowPlaying'] is Map) {
      dj = dj.copyWith(
        nowPlaying: MusicQueueItem.fromJson(
          Map<String, dynamic>.from(payload['nowPlaying'] as Map),
        ),
      );
    }
    final queueRaw = payload['queue'] ?? payload['musicQueue'];
    if (queueRaw is List) {
      final queue = queueRaw
          .whereType<Map>()
          .map((e) => MusicQueueItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      dj = dj.copyWith(musicQueue: queue);
    }
    dj = await _applyDjPlayback(dj);
    state = state.copyWith(dj: dj);
  }

  ChatRoomDjState _djWithQueuePlaybackFallback(ChatRoomDjState dj) {
    if (dj.playing) return dj;
    if (dj.musicQueue.isEmpty && dj.nowPlaying == null) return dj;
    if (dj.playbackSource == null && dj.youtubeFallbackSource == null) {
      return dj;
    }
    return dj.copyWith(playing: true);
  }

  Future<ChatRoomDjState> _applyDjPlayback(ChatRoomDjState dj) async {
    final ui = ref.read(voiceRoomUiProvider);
    final muted = !ui.backgroundMusicEnabled;

    if (!dj.musicEnabled) {
      await ref.read(voiceRoomDjPlayerProvider).stop();
      _lastDjPlaybackSignature = _djPlaybackSignature(dj, muted: muted);
      return dj.copyWith(playing: false);
    }

    final effectiveDj = _djWithQueuePlaybackFallback(dj);
    final playbackUrl = effectiveDj.playbackSource;
    final shouldPlay = effectiveDj.playing && playbackUrl != null;
    VoiceRoomDebugLog.log('music.player.sync', {
      'roomId': _roomKey,
      'musicId': effectiveDj.nowPlaying?.id,
      'youtubeVideoId': effectiveDj.nowPlaying?.youtubeUrl,
      'streamUrl': playbackUrl,
      'audioUrl': playbackUrl,
      'playState': effectiveDj.playing,
      'shouldPlay': shouldPlay,
      'hasUrl': playbackUrl != null,
      'muted': muted,
      'musicEnabled': effectiveDj.musicEnabled,
      'nowPlaying': effectiveDj.nowPlaying?.title,
    });
    final player = ref.read(voiceRoomDjPlayerProvider);
    final ok = await player.sync(
      musicUrl: playbackUrl,
      fallbackYoutubeUrl: effectiveDj.youtubeFallbackSource,
      playing: shouldPlay,
      muted: muted,
    );
    VoiceRoomDebugLog.log(
      ok ? 'music.player.started' : 'music.player.failed',
      {'url': playbackUrl},
    );
    if (shouldPlay && ok) {
      _lastDjPlaybackSignature = _djPlaybackSignature(effectiveDj, muted: muted);
    } else if (!shouldPlay) {
      _lastDjPlaybackSignature = _djPlaybackSignature(effectiveDj, muted: muted);
    } else {
      _lastDjPlaybackSignature = null;
      state = state.copyWith(
        dj: effectiveDj,
        error:
            'Müzik yüklenemedi. Birkaç saniye sonra yenileyin veya DJ şarkıyı tekrar seçsin.',
      );
      return effectiveDj;
    }
    return effectiveDj;
  }

  Future<void> _syncMusicFromServer() async {
    if (_roomKey.isEmpty) return;
    try {
      VoiceRoomDebugLog.log('music.sync.start', {'room': _roomKey});
      var dj = await ref.read(chatRoomRemoteProvider).fetchDj(_roomKey);
      dj = await _mergeMusicQueueIntoDj(dj);
      dj = await _applyDjPlayback(dj);
      state = state.copyWith(dj: dj, clearError: true);
      ref.invalidate(coinBalanceProvider);
      ref.invalidate(walletBalancesProvider);
      VoiceRoomDebugLog.log('music.sync.ok', {
        'playing': dj.playing,
        'queue': dj.musicQueue.length,
      });
    } catch (e) {
      VoiceRoomDebugLog.log('music.sync.fail', {'error': '$e'});
    }
  }

  Future<void> _syncMusicFromServerWithRetries() async {
    const delays = <Duration>[
      Duration.zero,
      Duration(milliseconds: 500),
      Duration(milliseconds: 1500),
    ];
    for (final delay in delays) {
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
      await _syncMusicFromServer();
      final dj = state.dj;
      final player = ref.read(voiceRoomDjPlayerProvider);
      if (dj.playing && player.playback.value.playing) {
        return;
      }
      if (dj.musicQueue.isNotEmpty || dj.nowPlaying != null) {
        final applied = await _applyDjPlayback(dj);
        state = state.copyWith(dj: applied);
        if (applied.playing &&
            ref.read(voiceRoomDjPlayerProvider).playback.value.playing) {
          return;
        }
      }
    }
  }

  Future<void> _handleSongRequestFree(
    SongRequestFreePayload payload, {
    ChatRoomUserRef? requester,
  }) async {
    VoiceRoomDebugLog.log('music.song_request_free', {
      'videoId': payload.videoId,
      'title': payload.title,
    });
    final item = MusicQueueItem(
      id: 'free-${payload.videoId}',
      title: payload.title,
      youtubeUrl: payload.youtubeUrl,
      createdAt: DateTime.now(),
      requestedBy: requester,
    );
    var dj = state.dj;
    final alreadyQueued = dj.musicQueue.any(
      (q) => q.youtubeUrl.contains(payload.videoId),
    );
    final queue = alreadyQueued ? dj.musicQueue : [...dj.musicQueue, item];
    dj = dj.copyWith(
      musicQueue: queue,
      nowPlaying: dj.nowPlaying ?? item,
      playing: true,
      musicUrl: dj.musicUrl?.isNotEmpty == true
          ? dj.musicUrl
          : payload.youtubeUrl,
    );
    dj = await _applyDjPlayback(dj);
    state = state.copyWith(dj: dj, clearError: true);
    unawaited(_syncMusicFromServerWithRetries());
  }

  void _onMusicRelatedChatMessage(ChatRoomMessage msg) {
    _maybeShowMusicRequestFlash(msg);
    final free = VoiceMusicSync.parseSongRequestFree(msg.content);
    if (free != null) {
      unawaited(_handleSongRequestFree(free, requester: msg.user));
      return;
    }
    if (VoiceMusicSync.isQueueUpdateMessage(msg.content)) {
      unawaited(_syncMusicFromServerWithRetries());
    }
  }

  void _maybeShowMusicRequestFlash(ChatRoomMessage msg) {
    final line = VoiceMusicRequestFlashText.fromChatContent(
      msg.content,
      userName: msg.user?.displayName ?? msg.user?.name,
    );
    if (line == null) return;
    final key = '${msg.id}:$line';
    if (_shownMusicRequestFlashKeys.contains(key)) return;
    _shownMusicRequestFlashKeys.add(key);
    state = state.copyWith(musicRequestFlash: line);
    _musicRequestFlashTimer?.cancel();
    _musicRequestFlashTimer = Timer(const Duration(seconds: 8), () {
      state = state.copyWith(clearMusicRequestFlash: true);
    });
  }

  void _showMusicRequestFlashLine(String line) {
    if (line.trim().isEmpty) return;
    state = state.copyWith(musicRequestFlash: line);
    _musicRequestFlashTimer?.cancel();
    _musicRequestFlashTimer = Timer(const Duration(seconds: 8), () {
      state = state.copyWith(clearMusicRequestFlash: true);
    });
  }

  Future<String?> _submitMusicRequestByTitle(String title) async {
    final q = title.trim();
    if (q.length < 2) return 'Şarkı adı çok kısa.';
    try {
      final hits = await ref.read(chatRoomRemoteProvider).searchYoutube(q);
      if (hits.isEmpty) {
        return '«$q» için sonuç bulunamadı. Müzik Aç ile tekrar deneyin.';
      }
      final hit = hits.first;
      return requestMusic(
        title: hit.title,
        youtubeUrl: hit.url,
        thumbUrl: hit.thumbUrl,
        videoId: hit.videoId,
      );
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  void _showEnterBanner(String raw) {
    final formatted = VoiceOfficialJoin.formatEntranceBanner(
      raw,
      roomName: arg.nameTr,
    );
    if (formatted.isEmpty) return;
    state = state.copyWith(enterBanner: formatted);
    _enterBannerTimer?.cancel();
    _enterBannerTimer = Timer(const Duration(seconds: 5), () {
      state = state.copyWith(clearEnterBanner: true);
    });
  }

  VoiceRoomPermissions _permissions() {
    final user = ref.read(authControllerProvider).valueOrNull;
    ChatRoomPresence? self;
    if (user != null) {
      for (final p in state.presence) {
        if (p.id == user.id) {
          self = p;
          break;
        }
      }
    }
    return VoiceRoomPermissions.forUser(
      user: user,
      room: arg,
      selfPresence: self,
    );
  }

  void _applyLocalChatClear() {
    state = state.copyWith(
      messages: state.messages
          .where(
            (m) =>
                m.kind != ChatMessageKind.text ||
                m.content.contains('temizlendi') ||
                m.content.toUpperCase().contains('DUYURU'),
          )
          .toList(),
    );
  }

  Future<void> sendMessage(String text) async {
    final trimmed = VoiceOfficialJoin.normalizeCommandInput(text.trim());
    if (trimmed.isEmpty || _roomKey.isEmpty) return;

    if (_isLocalHelpCommand(trimmed)) {
      VoiceRoomDebugLog.log('chat.command.local_help', {'cmd': trimmed});
      state = state.copyWith(openCommandsPanel: true, clearError: true);
      return;
    }

    if (VoiceMusicSync.isIstekCommand(trimmed)) {
      final song = VoiceMusicSync.parseIstekSongTitle(trimmed);
      if (song == null || song.isEmpty) {
        state = state.copyWith(
          error: 'Kullanım: !istek Sanatçı - Şarkı adı',
        );
        _showMusicRequestFlashLine('🎵 Kullanım: !istek Sanatçı - Şarkı adı');
        return;
      }
      state = state.copyWith(sending: true, clearError: true);
      _showMusicRequestFlashLine('🔍 «$song» sunucuda aranıyor…');
      VoiceRoomDebugLog.log('music.istek.server', {'song': song});
      try {
        VoiceRoomDebugLog.log('music.istek.send', {'song': song});
        await ref.read(chatRoomRemoteProvider).sendMessage(
              roomKey: _roomKey,
              content: trimmed,
            );
        await _syncMusicFromServerWithRetries();
        state = state.copyWith(sending: false);
        _showMusicRequestFlashLine('✅ «$song» isteği iletildi');
      } catch (e) {
        state = state.copyWith(
          sending: false,
          error: ApiException.userMessage(e),
        );
        _showMusicRequestFlashLine('⚠️ İstek gönderilemedi');
      }
      return;
    }

    final user = ref.read(authControllerProvider).valueOrNull;
    final isClear = VoiceOfficialJoin.isClearChatCommand(trimmed);
    final perms = _permissions();
    final optimisticId = 'local-${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = user != null
        ? ChatRoomMessage(
            id: optimisticId,
            content: trimmed,
            createdAt: DateTime.now(),
            user: ChatRoomUserRef(
              id: user.id,
              name: user.display,
              nickname: user.username,
              image: user.avatarUrl,
            ),
          )
        : null;

    state = state.copyWith(
      sending: true,
      messages: optimistic != null
          ? [...state.messages, optimistic]
          : state.messages,
      clearError: true,
    );

    if (isClear && (perms.canModerate || perms.isRoomOwner)) {
      unawaited(
        ref.read(chatRoomRemoteProvider).tryClearRoomMessages(
              roomKey: _roomKey,
            ),
      );
    }

    try {
      ChatRoomMessage? sent;
      try {
        sent = await ref.read(chatRoomRemoteProvider).sendMessage(
              roomKey: _roomKey,
              content: trimmed,
            ).timeout(const Duration(seconds: 22));
      } on TimeoutException {
        rethrow;
      }

      var list = [...state.messages];
      if (optimistic != null) {
        list.removeWhere((m) => m.id == optimisticId);
      }
      if (sent != null) {
        final delivered = sent;
        final idx = list.indexWhere(
          (m) =>
              m.id == delivered.id ||
              (m.id.startsWith('local-') &&
                  m.content == delivered.content),
        );
        if (idx >= 0) {
          list[idx] = delivered;
        } else {
          list.add(delivered);
        }
      } else if (optimistic != null) {
        list.add(optimistic);
      }
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      state = state.copyWith(messages: list, clearError: true);
      if (isClear && (perms.canModerate || perms.isRoomOwner)) {
        _applyLocalChatClear();
      }
      if (VoiceOfficialJoin.looksLikeRoomCommand(trimmed) ||
          VoiceMusicSync.isQueueUpdateMessage(trimmed)) {
        unawaited(_syncMusicFromServerWithRetries());
      }
    } on TimeoutException {
      await _recoverAfterSendTimeout(
        trimmed: trimmed,
        optimisticId: optimistic?.id,
        isClear: isClear,
        canModerate: perms.canModerate || perms.isRoomOwner,
      );
    } catch (e) {
      state = state.copyWith(
        messages: optimistic != null
            ? state.messages.where((m) => m.id != optimisticId).toList()
            : state.messages,
        error: ApiException.userMessage(e),
      );
    } finally {
      state = state.copyWith(sending: false);
    }
  }

  Future<void> _recoverAfterSendTimeout({
    required String trimmed,
    String? optimisticId,
    required bool isClear,
    required bool canModerate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    try {
      await refresh();
    } catch (_) {}
    final delivered = state.messages.any(
      (m) =>
          m.content == trimmed &&
          !m.id.startsWith('local-') &&
          (m.user?.id == ref.read(authControllerProvider).valueOrNull?.id ||
              m.kind != ChatMessageKind.text),
    );
    var list = state.messages;
    if (optimisticId != null) {
      list = list.where((m) => m.id != optimisticId).toList();
    }
    if (delivered || (isClear && canModerate)) {
      if (isClear && canModerate) _applyLocalChatClear();
      state = state.copyWith(messages: list, clearError: true);
      return;
    }
    state = state.copyWith(
      messages: list,
      error: 'Mesaj gecikmeli iletildi; listede görünmüyorsa tekrar deneyin.',
    );
  }

  Future<String?> requestSpeak() async {
    try {
      await ref.read(chatRoomRemoteProvider).requestSpeak(
            _roomKey,
          );
      ref.read(voiceRoomUiProvider.notifier).setRequestSpeakPending(true);
      return null;
    } catch (e) {
      final msg = ApiException.userMessage(e);
      if (msg.contains('404')) {
        return 'Mikrofon isteği bu odada desteklenmiyor; boş koltuğa dokunarak oturmayı deneyin.';
      }
      return msg;
    }
  }

  Future<String?> cancelSpeakRequest() async {
    try {
      await ref.read(chatRoomRemoteProvider).cancelSpeakRequest(
            _roomKey,
          );
      ref.read(voiceRoomUiProvider.notifier).setRequestSpeakPending(false);
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  bool _canControlMusic() {
    final perms = _permissions();
    return perms.canManageDj || perms.isRoomOwner || state.dj.canPlayMusic;
  }

  Future<String?> pauseMusic() async {
    if (!_canControlMusic()) return 'Yetki yok';
    try {
      await ref.read(chatRoomRemoteProvider).updateDj(
            roomKey: _roomKey,
            musicUrl: state.dj.musicUrl,
            playing: false,
          );
      await ref.read(voiceRoomDjPlayerProvider).pause();
      state = state.copyWith(dj: state.dj.copyWith(playing: false));
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> resumeMusic() async {
    if (!_canControlMusic()) return 'Yetki yok';
    final url = state.dj.playbackSource;
    if (url == null) return 'Çalınacak şarkı yok';
    try {
      await ref.read(chatRoomRemoteProvider).updateDj(
            roomKey: _roomKey,
            musicUrl: state.dj.musicUrl ?? url,
            playing: true,
          );
      final dj = await _applyDjPlayback(state.dj.copyWith(playing: true));
      state = state.copyWith(dj: dj);
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> stopMusic() => clearMusicQueue();

  Future<String?> toggleBackgroundMusic(bool enabled) async {
    final dj = state.dj;
    try {
      if (enabled) {
        await ref.read(chatRoomRemoteProvider).updateDj(
              roomKey: _roomKey,
              musicUrl: dj.musicUrl ??
                  'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
              playing: true,
            );
      } else {
        await ref.read(chatRoomRemoteProvider).updateDj(
              roomKey: _roomKey,
              musicUrl: dj.musicUrl,
              playing: false,
            );
        await ref.read(voiceRoomDjPlayerProvider).stop();
      }
      await refresh();
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> setRoomBackground(String url) async {
    try {
      await ref.read(chatRoomRemoteProvider).setRoomBackground(
            roomKey: _roomKey,
            backgroundImage: url,
          );
      state = state.copyWith(backgroundUrl: url);
      ref.invalidate(voiceRoomsProvider);
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<List<String>> fetchBackgrounds() =>
      ref.read(chatRoomRemoteProvider).fetchBackgrounds();

  Future<String?> updateRoomNickname(String nickname) async {
    final nick = nickname.trim();
    if (nick.isEmpty || _roomKey.isEmpty) {
      return 'Rumuz boş olamaz.';
    }
    try {
      final list = await ref.read(chatRoomRemoteProvider).joinPresence(
            _roomKey,
            nickname: nick,
          );
      final merged = _mergeSelf(list);
      state = state.copyWith(presence: merged, selfInRoom: true, clearError: true);
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<List<YoutubeSearchHit>> searchYoutube(String query) =>
      ref.read(chatRoomRemoteProvider).searchYoutube(query);

  Future<
      ({
        List<MusicQueueItem> queue,
        int cost,
        int maxMusicQueue,
        bool musicEnabled,
        MusicQueueItem? nowPlaying,
        bool? playing,
        bool? canRequestMusic,
        String? musicUrl,
      })> fetchMusicQueue() =>
      ref.read(chatRoomRemoteProvider).fetchMusicQueue(
            _roomKey,
          );

  Future<List<PopularMusicSuggestion>> fetchPopularMusic() =>
      ref.read(chatRoomRemoteProvider).fetchPopularMusic();

  Future<String?> skipMusic() async {
    try {
      await ref.read(chatRoomRemoteProvider).skipMusicQueue(
            roomKey: _roomKey,
          );
      await refresh();
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> removeQueueItem(String itemId) async {
    try {
      await ref.read(chatRoomRemoteProvider).removeMusicQueueItem(
            roomKey: _roomKey,
            itemId: itemId,
          );
      await refresh();
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> clearMusicQueue() async {
    try {
      await ref.read(chatRoomRemoteProvider).clearMusicQueue(
            roomKey: _roomKey,
          );
      await ref.read(voiceRoomDjPlayerProvider).stop();
      await refresh();
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> updateMusicSettings({
    bool? musicEnabled,
    int? musicRequestCost,
    int? maxMusicQueue,
  }) async {
    try {
      await ref.read(chatRoomRemoteProvider).updateMusicSettings(
            roomKey: _roomKey,
            musicEnabled: musicEnabled,
            musicRequestCost: musicRequestCost,
            maxMusicQueue: maxMusicQueue,
          );
      await refresh();
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> assignSeat({
    required int seatIndex,
    String? userId,
  }) async {
    try {
      await ref.read(chatRoomRemoteProvider).assignSeat(
            roomKey: _roomKey,
            seatIndex: seatIndex,
            userId: userId,
          );
      await refresh();
      return null;
    } catch (e) {
      final self = ref.read(authControllerProvider).valueOrNull;
      if (self != null && (userId == null || userId == self.id)) {
        final list = [...state.presence];
        final idx = list.indexWhere((p) => p.id == self.id);
        final updated = ChatRoomPresence(
          id: self.id,
          name: self.display,
          nickname: self.username,
          image: self.avatarUrl,
          chatRole: self.role ?? 'listener',
          roleSymbol: _roleSymbolForUser(self),
          seatIndex: seatIndex,
          isSpeaking: idx >= 0 ? list[idx].isSpeaking : false,
        );
        if (idx >= 0) {
          list[idx] = updated;
        } else {
          list.add(updated);
        }
        state = state.copyWith(presence: list, selfInRoom: true);
        return null;
      }
      return ApiException.userMessage(e);
    }
  }

  Future<String?> requestMusic({
    required String title,
    required String youtubeUrl,
    String? thumbUrl,
    String? videoId,
    String? giftTo,
    String? note,
    bool priority = true,
    bool skipPayment = false,
  }) async {
    try {
      VoiceRoomDebugLog.log('music.request', {
        'title': title,
        'priority': priority,
        'skipPayment': skipPayment,
      });
      final result = await ref
          .read(chatRoomRemoteProvider)
          .requestMusic(
            roomKey: _roomKey,
            title: title,
            youtubeUrl: youtubeUrl,
            thumbUrl: thumbUrl,
            videoId: videoId,
            giftTo: giftTo,
            note: note,
            priority: priority,
            skipPayment: skipPayment,
          )
          .timeout(
            const Duration(seconds: 22),
            onTimeout: () => throw TimeoutException('Şarkı isteği zaman aşımı'),
          );
      ref.invalidate(coinBalanceProvider);
      ref.invalidate(walletBalancesProvider);
      VoiceRoomDebugLog.log('music.request.ok', {
        'playing': result.playing,
        'queuePos': result.queuePosition,
        'hasUrl': result.musicUrl != null,
      });
      if (result.playing) {
        var dj = state.dj;
        if (result.musicUrl != null && result.musicUrl!.isNotEmpty) {
          dj = ChatRoomDjState(
            djUsers: dj.djUsers,
            activeDjId: dj.activeDjId,
            ownerPresent: dj.ownerPresent,
            canPlayMusic: dj.canPlayMusic,
            canRequestMusic: dj.canRequestMusic,
            isOwner: dj.isOwner,
            musicUrl: result.musicUrl,
            backgroundImage: dj.backgroundImage,
            playing: true,
            musicQueue: result.queue.isNotEmpty ? result.queue : dj.musicQueue,
            nowPlaying: result.item ?? dj.nowPlaying,
            musicRequestCost: dj.musicRequestCost,
            maxMusicQueue: dj.maxMusicQueue,
            musicEnabled: dj.musicEnabled,
            maxDj: dj.maxDj,
          );
        } else {
          dj = dj.copyWith(
            playing: true,
            nowPlaying: result.item,
            musicQueue: result.queue.isNotEmpty ? result.queue : dj.musicQueue,
          );
        }
        dj = await _applyDjPlayback(dj);
        state = state.copyWith(dj: dj);
      } else {
        var updated = state.dj.copyWith(
          musicQueue:
              result.queue.isNotEmpty ? result.queue : state.dj.musicQueue,
          nowPlaying: result.item ?? state.dj.nowPlaying,
          musicUrl: result.musicUrl ??
              result.item?.youtubeUrl ??
              state.dj.musicUrl,
        );
        final shouldStart = result.playing ||
            result.queuePosition == 1 ||
            (updated.musicQueue.isNotEmpty && updated.nowPlaying != null);
        if (shouldStart) {
          updated = updated.copyWith(playing: true);
        }
        updated = await _applyDjPlayback(updated);
        state = state.copyWith(dj: updated);
      }
      unawaited(_syncMusicFromServerWithRetries());
      if (result.queuePosition != null && result.queuePosition! > 1) {
        return 'Sıranız: #${result.queuePosition}';
      }
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> addRoomDj(String targetUserId) async {
    try {
      await ref.read(chatRoomRemoteProvider).addRoomDj(
            roomKey: _roomKey,
            targetUserId: targetUserId,
          );
      await refresh();
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> removeRoomDj(String targetUserId) async {
    try {
      await ref.read(chatRoomRemoteProvider).removeRoomDj(
            roomKey: _roomKey,
            targetUserId: targetUserId,
          );
      await refresh();
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<List<String>> fetchBannedWords() async {
    try {
      return await ref.read(chatRoomRemoteProvider).fetchBannedWords(
            _roomKey,
          );
    } catch (_) {
      return const [];
    }
  }

  Future<String?> addBannedWord(String word) async {
    try {
      await ref.read(chatRoomRemoteProvider).addBannedWord(
            roomKey: _roomKey,
            word: word,
          );
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> removeBannedWord(String word) async {
    try {
      await ref.read(chatRoomRemoteProvider).removeBannedWord(
            roomKey: _roomKey,
            word: word,
          );
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }
}

final voiceRoomLiveProvider = NotifierProvider.autoDispose
    .family<VoiceRoomLiveController, VoiceRoomLiveState, VoiceRoomEntity>(
  VoiceRoomLiveController.new,
);
