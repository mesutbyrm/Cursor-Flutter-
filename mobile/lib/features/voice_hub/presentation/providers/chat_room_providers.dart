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
import '../../data/services/voice_room_sse_service.dart';
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
import '../services/voice_room_dj_player.dart';
import 'voice_room_ui_provider.dart';

final youtubeStreamResolverProvider = Provider<YoutubeStreamResolver>((ref) {
  return YoutubeStreamResolver(ref.watch(dioProvider));
});

final chatRoomRemoteProvider = Provider<ChatRoomRemoteDataSource>((ref) {
  return ChatRoomRemoteDataSource(ref.watch(dioProvider));
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
      _leavePresence();
      ref.read(voiceRoomSseServiceProvider).disconnect();
      ref.read(voiceRoomDjPlayerProvider).stop();
    });
    Future.microtask(() async {
      ref.invalidate(coinBalanceProvider);
      ref.invalidate(walletBalancesProvider);
      await _joinPresence();
      await refresh();
      await _syncMusicFromServer();
      _startSse();
      _warmBackgrounds();
      final player = ref.read(voiceRoomDjPlayerProvider);
      player.onTrackComplete = () => unawaited(_onDjTrackComplete());
    });
    _poll = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pollPaused) refresh();
    });
    _presenceHeartbeat = Timer.periodic(const Duration(seconds: 20), (_) {
      if (state.selfInRoom) unawaited(_presenceHeartbeatTick());
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
        state = state.copyWith(sseConnected: true);
      },
      onDjUpdate: () {
        unawaited(refresh());
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
        state = state.copyWith(
          presence: merged,
          sseConnected: true,
          selfInRoom: true,
        );
      },
    );
  }

  Future<void> refresh() async {
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

      try {
        fetchedMsgs = await remote.fetchMessages(
          _roomKey,
          since: since,
        );
      } catch (e) {
        refreshError ??= e;
      }
      try {
        presence = await remote.fetchPresence(
          _roomKey,
        );
      } catch (e) {
        refreshError ??= e;
      }
      try {
        dj = await remote.fetchDj(_roomKey);
      } catch (_) {}
      dj = await _mergeMusicQueueIntoDj(dj);
      final ui = ref.read(voiceRoomUiProvider);
      final playbackUrl = dj.playbackSource;
      await ref.read(voiceRoomDjPlayerProvider).sync(
        musicUrl: playbackUrl,
        playing: dj.playing && playbackUrl != null,
        muted: !ui.backgroundMusicEnabled,
      );
      final bgFromDj = dj.backgroundImage?.trim();
      presence = _mergeSelf(presence);
      final messages = _mergeMessages(state.messages, fetchedMsgs);
      state = state.copyWith(
        messages: messages,
        presence: presence,
        dj: dj,
        loading: false,
        error: refreshError != null
            ? ApiException.userMessage(refreshError)
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
    try {
      await ref.read(chatRoomRemoteProvider).advanceMusicQueue(
            _roomKey,
          );
      await refresh();
    } catch (_) {}
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
      );
    } catch (_) {
      return dj;
    }
  }

  Future<void> _syncMusicFromServer() async {
    if (_roomKey.isEmpty) return;
    try {
      var dj = await ref.read(chatRoomRemoteProvider).fetchDj(_roomKey);
      dj = await _mergeMusicQueueIntoDj(dj);
      final ui = ref.read(voiceRoomUiProvider);
      final playbackUrl = dj.playbackSource;
      await ref.read(voiceRoomDjPlayerProvider).sync(
            musicUrl: playbackUrl,
            playing: dj.playing && playbackUrl != null,
            muted: !ui.backgroundMusicEnabled,
          );
      state = state.copyWith(dj: dj, clearError: true);
      ref.invalidate(coinBalanceProvider);
      ref.invalidate(walletBalancesProvider);
    } catch (_) {}
  }

  void _onMusicRelatedChatMessage(ChatRoomMessage msg) {
    _maybeShowMusicRequestFlash(msg);
    if (VoiceMusicSync.isQueueUpdateMessage(msg.content)) {
      unawaited(_syncMusicFromServer());
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
      _showMusicRequestFlashLine('🔍 «$song» aranıyor…');
      final err = await _submitMusicRequestByTitle(song);
      if (err == null) {
        await _syncMusicFromServer();
        state = state.copyWith(sending: false);
        _showMusicRequestFlashLine('✅ «$song» kuyruğa eklendi');
        return;
      }
      // Yerel arama başarısız — komutu sunucuya ilet (sohbette sistem yanıtı).
      state = state.copyWith(sending: false, clearError: true);
      _showMusicRequestFlashLine(
        '⚠️ Yerel arama başarısız, sunucuya iletiliyor…',
      );
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
        unawaited(_syncMusicFromServer());
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

  Future<List<YoutubeSearchHit>> searchYoutube(String query) =>
      ref.read(chatRoomRemoteProvider).searchYoutube(query);

  Future<
      ({
        List<MusicQueueItem> queue,
        int cost,
        int maxMusicQueue,
        bool musicEnabled,
        MusicQueueItem? nowPlaying,
        bool playing,
        bool canRequestMusic,
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
  }) async {
    try {
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
          )
          .timeout(
            const Duration(seconds: 22),
            onTimeout: () => throw TimeoutException('Şarkı isteği zaman aşımı'),
          );
      ref.invalidate(coinBalanceProvider);
      ref.invalidate(walletBalancesProvider);
      await _syncMusicFromServer();
      await refresh();
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
