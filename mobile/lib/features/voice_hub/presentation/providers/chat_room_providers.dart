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
import '../../data/services/exo_player_probe.dart';
import '../../data/services/voice_room_music_pipeline_log.dart';
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
import '../audio/voice_room_dj_stream_loader.dart';
import '../audio/voice_room_music_audio_session.dart';
import '../services/voice_room_dj_player.dart';
import '../services/voice_room_music_control_delegate.dart';
import 'voice_gift_providers.dart';
import 'voice_room_diagnostic_provider.dart';
import 'voice_room_ui_provider.dart';

final youtubeStreamResolverProvider = Provider<YoutubeStreamResolver>((ref) {
  final resolver = YoutubeStreamResolver(ref.watch(dioProvider));
  ref.onDispose(resolver.close);
  return resolver;
});

final youtubeMusicSearchCacheProvider = Provider<YoutubeMusicSearchCache>((
  ref,
) {
  return YoutubeMusicSearchCache();
});

final chatRoomRemoteProvider = Provider<ChatRoomRemoteDataSource>((ref) {
  final remote = ChatRoomRemoteDataSource(
    ref.watch(dioProvider),
    searchCache: ref.watch(youtubeMusicSearchCacheProvider),
  );
  ref.onDispose(remote.close);
  return remote;
});

final voiceRoomSseServiceProvider = Provider<VoiceRoomSseService>((ref) {
  final s = VoiceRoomSseService();
  ref.onDispose(s.disconnect);
  return s;
});

final voiceRoomDjStreamLoaderProvider = Provider<VoiceRoomDjStreamLoader>((
  ref,
) {
  return VoiceRoomDjStreamLoader(ref.watch(dioProvider));
});

final voiceRoomDjPlayerProvider = Provider<VoiceRoomDjPlayer>((ref) {
  final p = VoiceRoomDjPlayer(
    ref.watch(youtubeStreamResolverProvider),
    ref.watch(voiceRoomDjStreamLoaderProvider),
  );
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
    bool clearBackgroundUrl = false,
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
      backgroundUrl: clearBackgroundUrl
          ? null
          : (backgroundUrl ?? this.backgroundUrl),
      selfInRoom: selfInRoom ?? this.selfInRoom,
      sseConnected: sseConnected ?? this.sseConnected,
      openCommandsPanel: clearOpenCommandsPanel
          ? false
          : (openCommandsPanel ?? this.openCommandsPanel),
    );
  }
}

class VoiceRoomLiveController
    extends AutoDisposeFamilyNotifier<VoiceRoomLiveState, VoiceRoomEntity> {
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

  /// Bazı DJ/müzik uçları slug ile de çalışır (cuid 404).
  String? get _musicAlternateKey {
    final slug = arg.slug.trim();
    if (slug.isEmpty || slug == _roomKey) return null;
    return slug;
  }

  DateTime? get _lastMessageAt {
    if (state.messages.isEmpty) return null;
    return state.messages
        .map((m) => m.createdAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
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

  Object? _roomKeepAliveLink;

  @override
  VoiceRoomLiveState build(VoiceRoomEntity room) {
    _roomKeepAliveLink = ref.keepAlive();
    ref.onDispose(() {
      _poll?.cancel();
      _presenceHeartbeat?.cancel();
      _enterBannerTimer?.cancel();
      _musicRequestFlashTimer?.cancel();
      _giftSocket?.disconnect();
      _leavePresence();
      ref.read(voiceRoomSseServiceProvider).disconnect();
      final player = ref.read(voiceRoomDjPlayerProvider);
      final stillPlaying =
          player.playback.value.playing ||
          state.dj.playing ||
          state.dj.nowPlaying != null;
      final session = ref.read(voiceRoomMusicSessionProvider);
      if (stillPlaying && !session.dismissed && _roomKeepAliveLink != null) {
        ref.read(voiceRoomMusicSessionProvider.notifier).onRoomDetached(
          room: arg,
          dj: state.dj,
          canSyncServer: _canControlMusic(),
          keepAliveLink: _roomKeepAliveLink!,
        );
        _wireMusicControls();
      } else {
        _closeRoomKeepAlive();
      }
    });
    Future.microtask(() async {
      await VoiceRoomMusicAudioSession.ensureConfigured();
      ref.invalidate(coinBalanceProvider);
      ref.invalidate(walletBalancesProvider);
      await Future.wait([_joinPresence(), _warmBackgrounds()]);
      await refresh(includeDj: true);
      _startSse();
      _startGiftSocket();
      final player = ref.read(voiceRoomDjPlayerProvider);
      player.onTrackComplete = () => unawaited(_onDjTrackComplete());
      _wireMusicControls();
      // build() bitmeden state okunamaz — poll yalnızca microtask içinde.
      _schedulePoll(sseConnected: false);
    });
    _presenceHeartbeat = Timer.periodic(const Duration(seconds: 20), (_) {
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
      state = state.copyWith(loading: false, error: 'Geçersiz oda kimliği');
      return;
    }
    try {
      final token = await ref.read(tokenStorageProvider).readAccess();
      final hasJwt = token != null && token.isNotEmpty;
      VoiceRoomDebugLog.jwtStatus(hasToken: hasJwt, tokenLength: token?.length);
      ref.read(voiceRoomDiagnosticProvider.notifier).setJwt(hasJwt: hasJwt);
      VoiceRoomDebugLog.log('api.presence.join', {'room': _roomKey});
      final joined = await ref
          .read(chatRoomRemoteProvider)
          .joinPresence(_roomKey);
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
      ref
          .read(voiceRoomDiagnosticProvider.notifier)
          .setPresence(joined: true, count: merged.length);
    } on Object catch (e) {
      VoiceRoomDebugLog.log('api.presence.join.fail', {'error': e.toString()});
      ref.read(voiceRoomDiagnosticProvider.notifier).setPresence(joined: false);
      ref
          .read(voiceRoomDiagnosticProvider.notifier)
          .setError(ApiException.userMessage(e));
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
      final list = await ref
          .read(chatRoomRemoteProvider)
          .joinPresence(_roomKey);
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
    ref
        .read(voiceRoomSseServiceProvider)
        .connect(
          roomId: _roomKey,
          accessToken: storage.readAccess,
          onConnected: () {
            if (!state.sseConnected) {
              state = state.copyWith(sseConnected: true);
            }
            ref.read(voiceRoomDiagnosticProvider.notifier).setSse(true);
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
                VoiceOfficialJoin.isEntranceWorthy(
                  content: msg.content,
                  membership: msg.user?.membership,
                  chatRole: msg.user?.chatRole,
                ) &&
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
            ref.read(voiceRoomDiagnosticProvider.notifier).setSse(true);
            ref
                .read(voiceRoomDiagnosticProvider.notifier)
                .setPresence(joined: true, count: merged.length);
            if (!wasSse) _schedulePoll();
          },
        );
  }

  void _schedulePoll({bool? sseConnected, bool? musicActive}) {
    _poll?.cancel();
    _pollTick = 0;
    final sse = sseConnected ?? state.sseConnected;
    final active = musicActive ??
        (state.dj.playing || state.dj.nowPlaying != null);
    final interval = sse ? (active ? 5 : 12) : 6;
    _poll = Timer.periodic(Duration(seconds: interval), (_) {
      if (_pollPaused) return;
      _pollTick++;
      final djActive = state.dj.playing || state.dj.nowPlaying != null;
      final fullDj = !sse || djActive || (_pollTick % 2 == 0);
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
      onMessage: (msg) {
        final exists = state.messages.any((m) => m.id == msg.id);
        if (exists) return;
        state = state.copyWith(messages: [...state.messages, msg]);
        _onMusicRelatedChatMessage(msg);
        if (msg.kind == ChatMessageKind.systemJoin &&
            VoiceOfficialJoin.isEntranceWorthy(
              content: msg.content,
              membership: msg.user?.membership,
              chatRole: msg.user?.chatRole,
            ) &&
            _markEntranceOnce(msg.content)) {
          _showEnterBanner(msg.content);
        }
      },
      onPresence: (users) {
        final merged = _mergeSelf(users);
        state = state.copyWith(presence: merged, selfInRoom: true);
        ref.read(voiceRoomDiagnosticProvider.notifier).setSocket(true);
        ref
            .read(voiceRoomDiagnosticProvider.notifier)
            .setPresence(joined: true, count: merged.length);
      },
      onConnectionChanged: (connected) {
        ref.read(voiceRoomDiagnosticProvider.notifier).setSocket(connected);
      },
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
      var playDjInBackground = false;
      if (includeDj) {
        try {
          final pair = await Future.wait([
            remote.fetchDj(_roomKey, alternateKey: _musicAlternateKey),
            remote.fetchMusicQueue(
              _roomKey,
              alternateKey: _musicAlternateKey,
            ),
          ]);
          final djBase = pair[0] as ChatRoomDjState;
          final mq =
              pair[1]
                  as ({
                    List<MusicQueueItem> queue,
                    int cost,
                    int maxMusicQueue,
                    bool musicEnabled,
                    MusicQueueItem? nowPlaying,
                    bool? playing,
                    bool? canRequestMusic,
                    String? musicUrl,
                  });
          dj = _mergeMusicQueueRecord(djBase, mq);
        } catch (_) {
          try {
            dj = await remote.fetchDj(
              _roomKey,
              alternateKey: _musicAlternateKey,
            );
          } catch (_) {}
          dj = await _mergeMusicQueueIntoDj(dj);
        }
        bgFromDj = dj.backgroundImage?.trim();
        final ui = ref.read(voiceRoomUiProvider);
        final sig = _djPlaybackSignature(dj, muted: !ui.backgroundMusicEnabled);
        playDjInBackground = sig != _lastDjPlaybackSignature;
      }
      presence = _mergeSelf(presence);
      final previousMessages = state.messages;
      final messages = _mergeMessages(previousMessages, fetchedMsgs);
      _scanEntrancesFromMessages(previousMessages, messages);
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
      if (playDjInBackground) {
        unawaited(_playDjInBackground(dj));
      }
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
      await ref.read(chatRoomRemoteProvider).advanceMusicQueue(_roomKey);
      await refresh();
    } catch (e) {
      VoiceRoomDebugLog.log('music.track_complete.fail', {'error': '$e'});
    }
  }

  Future<void> _warmBackgrounds() async {
    try {
      final urls = await ref.read(chatRoomRemoteProvider).fetchBackgrounds();
      if (urls.isEmpty) return;
      final roomBg = arg.backgroundImageUrl?.trim();
      final current = state.backgroundUrl?.trim();
      final pick = (current != null && current.isNotEmpty)
          ? current
          : (roomBg != null && roomBg.isNotEmpty)
          ? roomBg
          : urls.first;
      state = state.copyWith(backgroundUrl: pick);
    } catch (_) {}
  }

  Future<ChatRoomDjState> _mergeMusicQueueIntoDj(ChatRoomDjState dj) async {
    try {
      final mq = await ref
          .read(chatRoomRemoteProvider)
          .fetchMusicQueue(
            _roomKey,
            alternateKey: _musicAlternateKey,
          );
      return _mergeMusicQueueRecord(dj, mq);
    } catch (_) {
      return dj;
    }
  }

  ChatRoomDjState _mergeMusicQueueRecord(
    ChatRoomDjState dj,
    ({
      List<MusicQueueItem> queue,
      int cost,
      int maxMusicQueue,
      bool musicEnabled,
      MusicQueueItem? nowPlaying,
      bool? playing,
      bool? canRequestMusic,
      String? musicUrl,
    })
    mq,
  ) {
    if ((mq.musicUrl == null || mq.musicUrl!.isEmpty) &&
        mq.queue.isNotEmpty &&
        (mq.playing == true || dj.playing)) {
      VoiceRoomMusicPipelineLog.mergeWarning(
        roomId: _roomKey,
        message: 'music-queue musicUrl boş ama kuyruk/playing var',
        fetchDjMusicUrl: dj.musicUrl,
        fetchQueueMusicUrl: mq.musicUrl,
        fetchDjPlaying: dj.playing,
        fetchQueuePlaying: mq.playing,
      );
    }
    if (dj.musicUrl != null &&
        dj.musicUrl!.isNotEmpty &&
        (mq.musicUrl == null || mq.musicUrl!.isEmpty)) {
      VoiceRoomMusicPipelineLog.mergeWarning(
        roomId: _roomKey,
        message: 'fetchDj musicUrl korunuyor — music-queue musicUrl null',
        fetchDjMusicUrl: dj.musicUrl,
        fetchQueueMusicUrl: mq.musicUrl,
        fetchDjPlaying: dj.playing,
        fetchQueuePlaying: mq.playing,
      );
    }
    final merged = dj.mergeMusicQueue(
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
    VoiceRoomMusicPipelineLog.compareDjState(
      stage: 'mergeMusicQueue',
      roomId: _roomKey,
      endpoint: '/api/chat/rooms/$_roomKey/music-queue',
      dj: merged,
      shouldPlay: merged.playing && merged.playbackSource != null,
    );
    return merged;
  }

  void _commitDjUi(ChatRoomDjState dj) {
    final wasMusicActive =
        state.dj.playing || state.dj.nowPlaying != null;
    state = state.copyWith(dj: dj, clearError: true);
    ref.read(voiceRoomMusicSessionProvider.notifier).syncFromRoom(
      room: arg,
      dj: dj,
      canSyncServer: _canControlMusic(),
    );
    final musicActive = dj.playing || dj.nowPlaying != null;
    if (musicActive != wasMusicActive) {
      _schedulePoll();
    }
  }

  void _closeRoomKeepAlive() {
    final link = _roomKeepAliveLink;
    _roomKeepAliveLink = null;
    if (link == null) return;
    try {
      (link as dynamic).close();
    } catch (_) {}
  }

  void _wireMusicControls() {
    final canSync = _canControlMusic();
    ref.read(voiceRoomDjPlayerProvider).controlDelegate =
        VoiceRoomMusicControlDelegate(
          syncServerControls: canSync,
          onPlay: () async {
            if (canSync) {
              await resumeMusic();
            } else {
              await ref.read(voiceRoomDjPlayerProvider).resumeLocal();
            }
          },
          onPause: () async {
            if (canSync) {
              await pauseMusic();
            } else {
              await ref.read(voiceRoomDjPlayerProvider).pauseLocal();
            }
          },
          onStop: () async {
            if (canSync) {
              await stopMusic();
            } else {
              await ref
                  .read(voiceRoomMusicSessionProvider.notifier)
                  .closePlayer();
            }
          },
          onSkipToNext: canSync ? () async => skipMusic() : null,
          onSkipToPrevious: () async {
            await ref.read(voiceRoomDjPlayerProvider).seekToStart();
          },
        );
  }

  Future<void> _playDjInBackground(ChatRoomDjState dj) async {
    final applied = await _applyDjPlayback(dj);
    state = state.copyWith(dj: applied);
  }

  MusicQueueItem? _resolveNowPlayingFromRequest({
    required List<MusicQueueItem> queue,
    MusicQueueItem? item,
    int? queuePosition,
    MusicQueueItem? fallback,
  }) {
    if (queue.isNotEmpty) return queue.first;
    if (queuePosition != null && queuePosition > 1 && item != null) {
      return fallback ?? item;
    }
    return item ?? fallback;
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
    _commitDjUi(dj);
    unawaited(_playDjInBackground(dj));
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
    final session = ref.read(voiceRoomMusicSessionProvider);
    if (session.dismissed || session.userDismissedPlayer) {
      await ref.read(voiceRoomDjPlayerProvider).stop();
      _lastDjPlaybackSignature = _djPlaybackSignature(dj, muted: muted);
      return dj;
    }

    if (!dj.musicEnabled) {
      await ref.read(voiceRoomDjPlayerProvider).stop();
      _lastDjPlaybackSignature = _djPlaybackSignature(dj, muted: muted);
      return dj.copyWith(playing: false);
    }

    final effectiveDj = _djWithQueuePlaybackFallback(dj);
    final playbackUrl = effectiveDj.playbackSource;
    final resolveSeed = effectiveDj.playbackResolveSeed;
    final shouldPlay =
        effectiveDj.playing && (playbackUrl != null || resolveSeed != null);
    if (effectiveDj.playing && playbackUrl == null && resolveSeed == null) {
      VoiceRoomMusicPipelineLog.nullMusicUrl(
        reason: 'playbackSource_null_while_playing',
        caller: '_applyDjPlayback',
        playing: effectiveDj.playing,
        queueLen: effectiveDj.musicQueue.length,
        hasNowPlaying: effectiveDj.nowPlaying != null,
        detail:
            'dj.musicUrl=${effectiveDj.musicUrl} np.youtube=${effectiveDj.nowPlaying?.youtubeUrl}',
      );
    }
    VoiceRoomMusicPipelineLog.compareDjState(
      stage: 'applyDjPlayback',
      roomId: _roomKey,
      dj: effectiveDj,
      shouldPlay: shouldPlay,
    );
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
    var ok = await player.sync(
      musicUrl: playbackUrl,
      resolveSeed: resolveSeed,
      fallbackYoutubeUrl: effectiveDj.youtubeFallbackSource,
      nowPlaying: effectiveDj.nowPlaying,
      playing: shouldPlay,
      muted: muted,
    );
    if (shouldPlay && !ok) {
      ref.read(youtubeStreamResolverProvider).invalidate(
        resolveSeed ?? playbackUrl ?? '',
      );
      final fallback = effectiveDj.youtubeFallbackSource;
      if (fallback != null) {
        ref.read(youtubeStreamResolverProvider).invalidate(fallback);
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
      ok = await player.sync(
        musicUrl: playbackUrl,
        resolveSeed: resolveSeed,
        fallbackYoutubeUrl: fallback,
        nowPlaying: effectiveDj.nowPlaying,
        playing: shouldPlay,
        muted: muted,
      );
    }
    VoiceRoomDebugLog.log(ok ? 'music.player.started' : 'music.player.failed', {
      'url': playbackUrl,
    });
    if (shouldPlay && !ok && playbackUrl != null) {
      VoiceRoomMusicPipelineLog.compareFields(
        stage: 'play_failed',
        roomId: _roomKey,
        serverMusicUrl: effectiveDj.musicUrl,
        nowPlayingYoutube: effectiveDj.nowPlaying?.youtubeUrl,
        videoId: VoiceRoomMusicPipelineLog.videoIdFromItem(
          effectiveDj.nowPlaying,
        ),
        playbackSource: playbackUrl,
        youtubeFallback: effectiveDj.youtubeFallbackSource,
        playing: effectiveDj.playing,
        shouldPlay: shouldPlay,
      );
      unawaited(ExoPlayerProbe.testUrlIfAndroid(playbackUrl));
      final fallback = effectiveDj.youtubeFallbackSource;
      if (fallback != null && fallback != playbackUrl) {
        unawaited(ExoPlayerProbe.testUrlIfAndroid(fallback));
      }
    }
    if (shouldPlay && ok) {
      _lastDjPlaybackSignature = _djPlaybackSignature(
        effectiveDj,
        muted: muted,
      );
    } else if (!shouldPlay) {
      _lastDjPlaybackSignature = _djPlaybackSignature(
        effectiveDj,
        muted: muted,
      );
    } else {
      _lastDjPlaybackSignature = null;
      final failedDj = effectiveDj.copyWith(playing: false);
      state = state.copyWith(dj: failedDj, clearError: true);
      return failedDj;
    }
    return effectiveDj;
  }

  Future<void> _syncMusicFromServer({bool optimisticUi = true}) async {
    if (_roomKey.isEmpty) return;
    try {
      VoiceRoomDebugLog.log('music.sync.start', {'room': _roomKey});
      final pair = await Future.wait([
        ref.read(chatRoomRemoteProvider).fetchDj(
          _roomKey,
          alternateKey: _musicAlternateKey,
        ),
        ref.read(chatRoomRemoteProvider).fetchMusicQueue(
          _roomKey,
          alternateKey: _musicAlternateKey,
        ),
      ]);
      var dj = _mergeMusicQueueRecord(
        pair[0] as ChatRoomDjState,
        pair[1]
            as ({
              List<MusicQueueItem> queue,
              int cost,
              int maxMusicQueue,
              bool musicEnabled,
              MusicQueueItem? nowPlaying,
              bool? playing,
              bool? canRequestMusic,
              String? musicUrl,
            }),
      );
      if (optimisticUi) {
        _commitDjUi(dj);
        unawaited(_playDjInBackground(dj));
      } else {
        dj = await _applyDjPlayback(dj);
        state = state.copyWith(dj: dj, clearError: true);
      }
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

  Future<void> _syncMusicFromServerIfNeeded({bool force = false}) async {
    if (!force) {
      final player = ref.read(voiceRoomDjPlayerProvider);
      if (player.playback.value.playing) return;
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (ref.read(voiceRoomDjPlayerProvider).playback.value.playing) return;
    }
    await _syncMusicFromServer();
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
    _commitDjUi(dj);
    unawaited(_playDjInBackground(dj));
    unawaited(_syncMusicFromServerIfNeeded(force: true));
  }

  void _onMusicRelatedChatMessage(ChatRoomMessage msg) {
    _maybeShowMusicRequestFlash(msg);
    final free = VoiceMusicSync.parseSongRequestFree(msg.content);
    if (free != null) {
      unawaited(_handleSongRequestFree(free, requester: msg.user));
      return;
    }
    if (VoiceMusicSync.isQueueUpdateMessage(msg.content)) {
      unawaited(_syncMusicFromServerIfNeeded());
    }
  }

  void _maybeShowMusicRequestFlash(ChatRoomMessage msg) {
    final line = VoiceMusicRequestFlashText.fromChatContent(
      msg.content,
      userName: msg.user?.displayName ?? msg.user?.name,
    );
    if (line == null) return;
    _appendSongRequestChatLine(line, dedupeKey: msg.id);
  }

  void _showMusicRequestFlashLine(String line) {
    if (line.trim().isEmpty) return;
    _appendSongRequestChatLine(line);
  }

  void _appendSongRequestChatLine(String line, {String? dedupeKey}) {
    final key = dedupeKey ?? line;
    if (_shownMusicRequestFlashKeys.contains(key)) return;
    _shownMusicRequestFlashKeys.add(key);
    final id = 'song-chat-$key';
    if (state.messages.any((m) => m.id == id)) return;
    final chatLine = ChatRoomMessage(
      id: id,
      content: line,
      createdAt: DateTime.now(),
      user: msgUserFromFlash(line),
    );
    state = state.copyWith(
      messages: [...state.messages, chatLine],
      clearMusicRequestFlash: true,
    );
  }

  ChatRoomUserRef? msgUserFromFlash(String line) {
    final m = RegExp(r'^🎵\s*([^:]+)\s+şarkı').firstMatch(line);
    if (m == null) return null;
    return ChatRoomUserRef(id: 'system', name: m.group(1)!.trim());
  }

  Future<String?> _submitMusicRequestByTitle(
    String title, {
    bool skipPayment = false,
    bool priority = true,
  }) async {
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
        skipPayment: skipPayment,
        priority: priority,
      );
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  void _scanEntrancesFromMessages(
    List<ChatRoomMessage> previous,
    List<ChatRoomMessage> merged,
  ) {
    final prevIds = previous.map((m) => m.id).toSet();
    for (final m in merged) {
      if (prevIds.contains(m.id)) continue;
      if (m.kind != ChatMessageKind.systemJoin) continue;
      if (!VoiceOfficialJoin.isEntranceWorthy(
        content: m.content,
        membership: m.user?.membership,
        chatRole: m.user?.chatRole,
      )) {
        continue;
      }
      if (_markEntranceOnce(m.content)) {
        _showEnterBanner(m.content);
      }
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
    _enterBannerTimer = Timer(const Duration(seconds: 8), () {
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
    _shownMusicRequestFlashKeys.clear();
    state = state.copyWith(
      messages: state.messages.where((m) {
        if (m.id.startsWith('song-chat-')) return false;
        if (VoiceMusicSync.isQueueUpdateMessage(m.content)) return false;
        if (m.kind != ChatMessageKind.text) return false;
        if (m.content.contains('temizlendi')) return true;
        if (m.content.toUpperCase().contains('DUYURU')) return true;
        return false;
      }).toList(),
      clearMusicRequestFlash: true,
    );
    unawaited(closeMusicPlayer());
  }

  Future<void> sendMessage(String text) async {
    final trimmed = VoiceOfficialJoin.normalizeCommandInput(text.trim());
    if (trimmed.isEmpty || _roomKey.isEmpty) return;

    if (_isLocalHelpCommand(trimmed)) {
      VoiceRoomDebugLog.log('chat.command.local_help', {'cmd': trimmed});
      state = state.copyWith(
        openCommandsPanel: true,
        clearError: true,
        messages: state.messages
            .where((m) => m.id.startsWith('local-') || m.content != trimmed)
            .toList(),
      );
      return;
    }

    if (VoiceMusicSync.isIstekCommand(trimmed)) {
      ref.read(voiceRoomMusicSessionProvider.notifier).clearUserDismissed();
      final song = VoiceMusicSync.parseIstekSongTitle(trimmed);
      if (song == null || song.isEmpty) {
        state = state.copyWith(error: 'Kullanım: !istek Sanatçı - Şarkı adı');
        _showMusicRequestFlashLine('🎵 Kullanım: !istek Sanatçı - Şarkı adı');
        return;
      }
      state = state.copyWith(sending: true, clearError: true);
      _showMusicRequestFlashLine('🔍 «$song» aranıyor…');
      VoiceRoomDebugLog.log('music.istek.search', {'song': song});
      try {
        final queueError = await _submitMusicRequestByTitle(
          song,
          skipPayment: true,
          priority: false,
        );
        if (queueError != null && queueError.isNotEmpty) {
          state = state.copyWith(sending: false, error: queueError);
          _showMusicRequestFlashLine('⚠️ $queueError');
          return;
        }
        unawaited(
          ref
              .read(chatRoomRemoteProvider)
              .sendMessage(roomKey: _roomKey, content: trimmed)
              .catchError((_) {}),
        );
        await _syncMusicFromServerIfNeeded(force: true);
        unawaited(_playDjInBackground(state.dj));
        final djAfter = state.dj;
        VoiceRoomMusicPipelineLog.istekSubmitted(
          song: song,
          roomId: _roomKey,
          requestEndpoint:
              '/api/chat/rooms/$_roomKey/song-request',
          responseMusicUrl: djAfter.musicUrl,
          responsePlaying: djAfter.playing,
          queuePosition: djAfter.queuePositionFor(djAfter.nowPlaying?.id),
        );
        VoiceRoomMusicPipelineLog.compareDjState(
          stage: 'istek_after_sync',
          roomId: _roomKey,
          endpoint: '/api/chat/rooms/$_roomKey/music-queue',
          dj: djAfter,
          shouldPlay: djAfter.playing && djAfter.playbackSource != null,
        );
        state = state.copyWith(sending: false);
        _showMusicRequestFlashLine('✅ «$song» kuyruğa eklendi');
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
      messages: optimistic != null
          ? [...state.messages, optimistic]
          : state.messages,
      clearError: true,
    );

    if (isClear && (perms.canModerate || perms.isRoomOwner)) {
      unawaited(
        ref
            .read(chatRoomRemoteProvider)
            .tryClearRoomMessages(roomKey: _roomKey),
      );
    }

    try {
      ChatRoomMessage? sent;
      try {
        sent = await ref
            .read(chatRoomRemoteProvider)
            .sendMessage(roomKey: _roomKey, content: trimmed)
            .timeout(const Duration(seconds: 22));
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
              (m.id.startsWith('local-') && m.content == delivered.content),
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
        unawaited(_applyRoomCommandFallback(trimmed));
        unawaited(_syncMusicFromServerIfNeeded());
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
    }
  }

  bool _musicItemHasPlayableUrl(MusicQueueItem? item) {
    final url = item?.youtubeUrl.trim() ?? '';
    return url.isNotEmpty &&
        (url.contains('youtube') ||
            url.contains('youtu.be') ||
            url.startsWith('http'));
  }

  bool _musicLooksQueued(String song) {
    final needle = song.trim().toLowerCase();
    if (needle.isEmpty) return false;
    final tokens = needle
        .split(RegExp(r'[\s\-–—]+'))
        .where((part) => part.length >= 3)
        .toList();
    bool match(String? value) =>
        value != null &&
        (value.toLowerCase().contains(needle) ||
            (tokens.isNotEmpty &&
                tokens.every((token) => value.toLowerCase().contains(token))));
    final dj = state.dj;
    final now = dj.nowPlaying;
    if (_musicItemHasPlayableUrl(now) &&
        (match(now?.title) || match(now?.youtubeUrl))) {
      return true;
    }
    return dj.musicQueue.any(
      (item) =>
          _musicItemHasPlayableUrl(item) &&
          (match(item.title) || match(item.youtubeUrl)),
    );
  }

  Future<void> _applyRoomCommandFallback(String raw) async {
    final command = _ParsedRoomCommand.tryParse(raw);
    if (command == null) return;
    final remote = ref.read(chatRoomRemoteProvider);
    final target = command.target == null
        ? null
        : _resolvePresence(command.target!);
    try {
      switch (command.name) {
        case 'ban':
          if (target == null) return;
          await remote.banUser(
            roomKey: _roomKey,
            alternateKey: arg.slug,
            userId: target.id,
            reason: command.reason,
          );
          break;
        case 'unban':
          if (target == null) return;
          await remote.unbanUser(
            roomKey: _roomKey,
            alternateKey: arg.slug,
            userId: target.id,
          );
          break;
        case 'at':
        case 'kick':
          if (target == null) return;
          await remote.kickUser(
            roomKey: _roomKey,
            alternateKey: arg.slug,
            userId: target.id,
            reason: command.reason,
          );
          break;
        case 'sessiz':
        case 'sustur':
        case 'mute':
          if (target == null) return;
          await remote.muteUser(
            roomKey: _roomKey,
            alternateKey: arg.slug,
            userId: target.id,
            minutes: command.minutes ?? 30,
            reason: command.reason,
          );
          break;
        case 'yetki':
          if (target == null || command.roleSymbol == null) return;
          await remote.assignRole(
            roomKey: _roomKey,
            alternateKey: arg.slug,
            userId: target.id,
            roleSymbol: command.roleSymbol!,
          );
          break;
        case 'dj':
          if (target == null) return;
          await addRoomDj(target.id);
          break;
        case 'muzik':
          await _syncMusicFromServerIfNeeded();
          break;
        case 'temizle':
          if (_permissions().canModerate || _permissions().isRoomOwner) {
            await remote.tryClearRoomMessages(roomKey: _roomKey);
            _applyLocalChatClear();
          }
          break;
        default:
          return;
      }
      await refresh();
    } catch (e) {
      VoiceRoomDebugLog.log('chat.command.fallback.fail', {
        'command': raw,
        'error': ApiException.userMessage(e),
      });
    }
  }

  ChatRoomPresence? _resolvePresence(String target) {
    final raw = target.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();
    if (raw.isEmpty) return null;
    for (final user in state.presence) {
      final keys = [
        user.id,
        user.name,
        user.nickname,
      ].whereType<String>().map((e) => e.trim().toLowerCase());
      if (keys.any((key) => key == raw || key.contains(raw))) return user;
    }
    return null;
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
      await ref.read(chatRoomRemoteProvider).requestSpeak(_roomKey);
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
      await ref.read(chatRoomRemoteProvider).cancelSpeakRequest(_roomKey);
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
      await ref
          .read(chatRoomRemoteProvider)
          .updateDj(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            musicUrl: state.dj.musicUrl,
            playing: false,
          );
      await ref.read(voiceRoomDjPlayerProvider).pauseLocal();
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
      await ref
          .read(chatRoomRemoteProvider)
          .updateDj(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
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
    try {
      final player = ref.read(voiceRoomDjPlayerProvider);
      await player.setMuted(!enabled);
      if (enabled) {
        await _applyDjPlayback(state.dj);
      }
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> setRoomBackground(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return 'Arka plan seçilemedi.';
    final previous = state.backgroundUrl;
    state = state.copyWith(backgroundUrl: trimmed, clearError: true);
    try {
      await ref
          .read(chatRoomRemoteProvider)
          .setRoomBackground(
            roomKey: _roomKey.isNotEmpty ? _roomKey : arg.id,
            alternateKey: arg.slug,
            backgroundImage: trimmed,
          );
      ref.invalidate(voiceRoomsProvider);
      return null;
    } catch (e) {
      state = state.copyWith(
        backgroundUrl: previous,
        clearBackgroundUrl: previous == null,
        error: ApiException.userMessage(e),
      );
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
      final list = await ref
          .read(chatRoomRemoteProvider)
          .joinPresence(_roomKey, nickname: nick);
      final merged = _mergeSelf(list);
      state = state.copyWith(
        presence: merged,
        selfInRoom: true,
        clearError: true,
      );
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
    })
  >
  fetchMusicQueue() =>
      ref.read(chatRoomRemoteProvider).fetchMusicQueue(_roomKey);

  Future<List<PopularMusicSuggestion>> fetchPopularMusic() =>
      ref.read(chatRoomRemoteProvider).fetchPopularMusic();

  Future<String?> skipMusic() async {
    try {
      await ref.read(chatRoomRemoteProvider).skipMusicQueue(
        roomKey: _roomKey,
        alternateKey: _musicAlternateKey,
      );
      await refresh();
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> removeQueueItem(String itemId) async {
    try {
      await ref
          .read(chatRoomRemoteProvider)
          .removeMusicQueueItem(roomKey: _roomKey, itemId: itemId);
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
        alternateKey: _musicAlternateKey,
      );
      await ref.read(voiceRoomDjPlayerProvider).stop();
      await refresh();
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  /// X / kapat — yerel oynatıcıyı durdur; DJ/owner ise sunucu kuyruğunu da temizle.
  Future<void> closeMusicPlayer() async {
    ref.read(voiceRoomMusicSessionProvider.notifier).markUserDismissed();
    await ref.read(voiceRoomDjPlayerProvider).stop();
    if (_canControlMusic()) {
      try {
        await ref.read(chatRoomRemoteProvider).clearMusicQueue(
          roomKey: _roomKey,
          alternateKey: _musicAlternateKey,
        );
        await refresh();
      } catch (_) {
        state = state.copyWith(
          dj: state.dj.copyWith(
            playing: false,
            clearNowPlaying: true,
            clearMusicUrl: true,
            musicQueue: const [],
          ),
        );
      }
    } else {
      state = state.copyWith(
        dj: state.dj.copyWith(
          playing: false,
          clearNowPlaying: true,
          clearMusicUrl: true,
        ),
      );
    }
    ref.read(voiceRoomMusicSessionProvider.notifier).dismissAfterClose();
  }

  Future<String?> updateMusicSettings({
    bool? musicEnabled,
    int? musicRequestCost,
    int? maxMusicQueue,
  }) async {
    try {
      await ref
          .read(chatRoomRemoteProvider)
          .updateMusicSettings(
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

  Future<String?> assignSeat({required int seatIndex, String? userId}) async {
    try {
      await ref
          .read(chatRoomRemoteProvider)
          .assignSeat(roomKey: _roomKey, seatIndex: seatIndex, userId: userId);
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
      var resolvedUrl = youtubeUrl.trim();
      var resolvedThumb = thumbUrl;
      var resolvedVideoId = videoId;
      if (resolvedUrl.isEmpty && title.trim().length >= 2) {
        final hits = await ref
            .read(chatRoomRemoteProvider)
            .searchYoutube(title.trim());
        if (hits.isEmpty) {
          return '«${title.trim()}» için YouTube sonucu bulunamadı.';
        }
        final hit = hits.first;
        resolvedUrl = hit.url;
        resolvedThumb ??= hit.thumbUrl;
        resolvedVideoId ??= hit.videoId;
      }
      if (resolvedUrl.isEmpty) {
        return 'Geçerli bir şarkı seçin veya arayın.';
      }
      unawaited(ref.read(youtubeStreamResolverProvider).prefetch(resolvedUrl));
      VoiceRoomDebugLog.log('music.request', {
        'title': title,
        'priority': priority,
        'skipPayment': skipPayment,
        'youtubeUrl': resolvedUrl,
      });
      final result = await ref
          .read(chatRoomRemoteProvider)
          .requestMusic(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            title: title,
            youtubeUrl: resolvedUrl,
            thumbUrl: resolvedThumb,
            videoId: resolvedVideoId,
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
      if (result.musicUrl != null && result.musicUrl!.isNotEmpty) {
        unawaited(
          ref.read(youtubeStreamResolverProvider).prefetch(result.musicUrl!),
        );
      }
      VoiceRoomMusicPipelineLog.istekSubmitted(
        song: title,
        roomId: _roomKey,
        requestEndpoint: '/api/chat/rooms/$_roomKey/song-request',
        responseMusicUrl: result.musicUrl,
        responsePlaying: result.playing,
        queuePosition: result.queuePosition,
      );
      final queue = result.queue.isNotEmpty
          ? result.queue
          : state.dj.musicQueue;
      final nowPlaying = _resolveNowPlayingFromRequest(
        queue: queue,
        item: result.item,
        queuePosition: result.queuePosition,
        fallback: state.dj.nowPlaying,
      );
      final shouldPlay =
          result.playing ||
          result.queuePosition == 1 ||
          (queue.isNotEmpty && nowPlaying != null);

      var dj = state.dj.copyWith(
        musicQueue: queue,
        nowPlaying: nowPlaying,
        playing: shouldPlay,
        musicUrl: result.musicUrl ?? nowPlaying?.youtubeUrl,
        clearMusicUrl:
            result.musicUrl == null &&
            nowPlaying?.id != state.dj.nowPlaying?.id,
      );
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
          playing: shouldPlay,
          musicQueue: queue,
          nowPlaying: nowPlaying,
          musicRequestCost: dj.musicRequestCost,
          maxMusicQueue: dj.maxMusicQueue,
          musicEnabled: dj.musicEnabled,
          maxDj: dj.maxDj,
        );
      }
      _commitDjUi(dj);
      unawaited(_playDjInBackground(dj));
      unawaited(_syncMusicFromServerIfNeeded());
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
      await ref
          .read(chatRoomRemoteProvider)
          .addRoomDj(roomKey: _roomKey, targetUserId: targetUserId);
      await refresh();
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> removeRoomDj(String targetUserId) async {
    try {
      await ref
          .read(chatRoomRemoteProvider)
          .removeRoomDj(roomKey: _roomKey, targetUserId: targetUserId);
      await refresh();
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<List<String>> fetchBannedWords() async {
    try {
      return await ref.read(chatRoomRemoteProvider).fetchBannedWords(_roomKey);
    } catch (_) {
      return const [];
    }
  }

  Future<String?> addBannedWord(String word) async {
    try {
      await ref
          .read(chatRoomRemoteProvider)
          .addBannedWord(roomKey: _roomKey, word: word);
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> removeBannedWord(String word) async {
    try {
      await ref
          .read(chatRoomRemoteProvider)
          .removeBannedWord(roomKey: _roomKey, word: word);
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }
}

class _ParsedRoomCommand {
  const _ParsedRoomCommand({
    required this.name,
    this.target,
    this.reason,
    this.roleSymbol,
    this.minutes,
  });

  final String name;
  final String? target;
  final String? reason;
  final String? roleSymbol;
  final int? minutes;

  static _ParsedRoomCommand? tryParse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.length < 2 ||
        (!trimmed.startsWith('!') && !trimmed.startsWith('/'))) {
      return null;
    }
    final parts = trimmed.substring(1).split(RegExp(r'\s+'));
    if (parts.isEmpty) return null;
    final name = parts.first.toLowerCase();
    final args = parts.skip(1).toList();
    String? target = args.isNotEmpty ? args.first : null;
    String? roleSymbol;
    int? minutes;
    if (name == 'yetki' && args.length >= 2) {
      roleSymbol = args[1];
    }
    if ({'sessiz', 'sustur', 'mute'}.contains(name) && args.length >= 2) {
      minutes = int.tryParse(args[1].replaceAll(RegExp(r'[^0-9]'), ''));
    }
    final reasonStart = (name == 'yetki' || minutes != null) ? 2 : 1;
    final reason = args.length > reasonStart
        ? args.skip(reasonStart).join(' ').trim()
        : null;
    return _ParsedRoomCommand(
      name: name,
      target: target,
      roleSymbol: roleSymbol,
      minutes: minutes,
      reason: reason != null && reason.isNotEmpty ? reason : null,
    );
  }
}

/// Sesli odadan çıkınca da süren müzik oturumu — global mini player.
class VoiceRoomMusicSessionState {
  const VoiceRoomMusicSessionState({
    this.room,
    this.dj = const ChatRoomDjState(),
    this.visible = false,
    this.dismissed = false,
    this.userDismissedPlayer = false,
    this.canSyncServer = false,
  });

  final VoiceRoomEntity? room;
  final ChatRoomDjState dj;
  final bool visible;
  final bool dismissed;
  /// Kullanıcı X ile kapattı — sunucu hâlâ çalsa bile mini player açılmasın.
  final bool userDismissedPlayer;
  final bool canSyncServer;

  bool get hasActiveMusic =>
      !dismissed &&
      !userDismissedPlayer &&
      (dj.playing || dj.nowPlaying != null || dj.musicQueue.isNotEmpty);

  VoiceRoomMusicSessionState copyWith({
    VoiceRoomEntity? room,
    bool clearRoom = false,
    ChatRoomDjState? dj,
    bool? visible,
    bool? dismissed,
    bool? userDismissedPlayer,
    bool? canSyncServer,
  }) {
    return VoiceRoomMusicSessionState(
      room: clearRoom ? null : (room ?? this.room),
      dj: dj ?? this.dj,
      visible: visible ?? this.visible,
      dismissed: dismissed ?? this.dismissed,
      userDismissedPlayer: userDismissedPlayer ?? this.userDismissedPlayer,
      canSyncServer: canSyncServer ?? this.canSyncServer,
    );
  }
}

class VoiceRoomMusicSessionNotifier extends Notifier<VoiceRoomMusicSessionState> {
  Object? _detachedKeepAlive;
  Timer? _syncTimer;

  @override
  VoiceRoomMusicSessionState build() {
    ref.onDispose(_disposeSession);
    return const VoiceRoomMusicSessionState();
  }

  void _disposeSession() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _closeDetachedKeepAlive();
  }

  void syncFromRoom({
    required VoiceRoomEntity room,
    required ChatRoomDjState dj,
    required bool canSyncServer,
  }) {
    final playing =
        dj.playing ||
        ref.read(voiceRoomDjPlayerProvider).playback.value.playing;
    final hasTrack = dj.nowPlaying != null || dj.musicQueue.isNotEmpty;

    if (state.userDismissedPlayer) {
      if (!playing && !hasTrack) {
        state = state.copyWith(
          userDismissedPlayer: false,
          dismissed: false,
          visible: false,
          room: room,
          dj: dj,
          canSyncServer: canSyncServer,
        );
      } else {
        state = state.copyWith(
          room: room,
          dj: dj,
          visible: false,
          dismissed: true,
          canSyncServer: canSyncServer,
        );
      }
      return;
    }

    if (!playing && !hasTrack) {
      if (state.room?.id == room.id && !state.dismissed) {
        state = state.copyWith(visible: false, dj: dj);
      }
      return;
    }
    final prevTrackId = state.dj.nowPlaying?.id;
    final newTrackId = dj.nowPlaying?.id;
    final trackChanged =
        newTrackId != null &&
        newTrackId.isNotEmpty &&
        newTrackId != prevTrackId;
    final dismissed = trackChanged ? false : state.dismissed;
    state = state.copyWith(
      room: room,
      dj: dj,
      visible: !dismissed,
      canSyncServer: canSyncServer,
      dismissed: dismissed,
    );
    if (!dismissed) {
      _ensureBackgroundSync(room);
    }
  }

  void clearUserDismissed() {
    if (!state.userDismissedPlayer) return;
    state = state.copyWith(userDismissedPlayer: false, dismissed: false);
  }

  void onRoomDetached({
    required VoiceRoomEntity room,
    required ChatRoomDjState dj,
    required bool canSyncServer,
    required Object keepAliveLink,
  }) {
    final player = ref.read(voiceRoomDjPlayerProvider);
    final stillPlaying =
        player.playback.value.playing || dj.playing || dj.nowPlaying != null;
    if (!stillPlaying || state.dismissed) {
      _tryCloseKeepAlive(keepAliveLink);
      return;
    }
    _detachedKeepAlive = keepAliveLink;
    state = state.copyWith(
      room: room,
      dj: dj,
      visible: !state.dismissed,
      canSyncServer: canSyncServer,
    );
    _ensureBackgroundSync(room);
  }

  void _ensureBackgroundSync(VoiceRoomEntity room) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 18), (_) async {
      if (state.dismissed || state.room?.id != room.id) return;
      try {
        await ref
            .read(voiceRoomLiveProvider(room.stableSessionKey).notifier)
            .refresh(includeDj: true);
        final live = ref.read(voiceRoomLiveProvider(room.stableSessionKey));
        state = state.copyWith(dj: live.dj);
        if (!live.dj.playing &&
            live.dj.nowPlaying == null &&
            live.dj.musicQueue.isEmpty &&
            !ref.read(voiceRoomDjPlayerProvider).playback.value.playing) {
          await closePlayer();
        }
      } catch (_) {}
    });
  }

  Future<void> closePlayer() async {
    _syncTimer?.cancel();
    _syncTimer = null;
    await ref.read(voiceRoomDjPlayerProvider).stop();
    state = state.copyWith(
      visible: false,
      dismissed: true,
      clearRoom: true,
      dj: const ChatRoomDjState(),
    );
    _closeDetachedKeepAlive();
  }

  void dismissAfterClose() {
    _syncTimer?.cancel();
    _syncTimer = null;
    state = state.copyWith(
      visible: false,
      dismissed: true,
      userDismissedPlayer: true,
      dj: const ChatRoomDjState(),
    );
    _closeDetachedKeepAlive();
  }

  void markUserDismissed() {
    state = state.copyWith(
      userDismissedPlayer: true,
      dismissed: true,
      visible: false,
    );
  }

  void _closeDetachedKeepAlive() {
    final link = _detachedKeepAlive;
    _detachedKeepAlive = null;
    if (link != null) _tryCloseKeepAlive(link);
  }

  void _tryCloseKeepAlive(Object link) {
    try {
      (link as dynamic).close();
    } catch (_) {}
  }
}

final voiceRoomMusicSessionProvider =
    NotifierProvider<VoiceRoomMusicSessionNotifier, VoiceRoomMusicSessionState>(
      VoiceRoomMusicSessionNotifier.new,
    );

final voiceRoomLiveProvider = NotifierProvider.autoDispose
    .family<VoiceRoomLiveController, VoiceRoomLiveState, VoiceRoomEntity>(
      VoiceRoomLiveController.new,
    );
