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
import '../../../home/presentation/providers/fortune_live_event_bus.dart';
import '../../data/datasources/chat_room_remote_datasource.dart';
import '../../data/services/voice_room_debug_log.dart';
import '../../data/services/exo_player_probe.dart';
import '../../data/services/voice_room_music_pipeline_log.dart';
import '../../data/services/chat_room_sse_service.dart';
import '../../data/youtube_music_search_cache.dart';
import '../../../live/presentation/gifts/providers/live_gift_providers.dart';
import '../../music/domain/entities/room_playback_sync.dart';
import '../../music/presentation/providers/room_music_providers.dart';
import '../../domain/entities/chat_room_dj_state.dart';
import '../../domain/entities/music_queue_item.dart';
import '../../domain/entities/chat_room_message.dart';
import '../../domain/voice_music_sync.dart';
import '../../domain/voice_official_join.dart';
import '../utils/voice_room_permissions.dart';
import '../utils/voice_music_access.dart';
import '../widgets/voice_room/voice_room_music_request_flash.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/chat_room_my_permissions.dart';
import '../../domain/entities/popular_music_suggestion.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/youtube_stream_resolver.dart';
import '../audio/voice_room_dj_stream_loader.dart';
import '../audio/voice_room_music_audio_session.dart';
import '../services/voice_room_dj_player.dart';
import '../services/voice_room_music_control_delegate.dart';
import '../../video/domain/youtube_video_id.dart';
import '../../video/presentation/room_video_controller.dart';
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

final voiceRoomSseServiceProvider = Provider<ChatRoomSseService>((ref) {
  final s = ChatRoomSseService();
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
    this.serverPermissions,
    this.myNickname,
    this.typingUsers = const [],
    this.roomMuted = false,
    this.pendingMusicSearchQuery,
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
  final ChatRoomMyPermissions? serverPermissions;
  final String? myNickname;
  final List<String> typingUsers;
  final bool roomMuted;
  final String? pendingMusicSearchQuery;

  bool get isAnyoneTyping => typingUsers.isNotEmpty;

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
    ChatRoomMyPermissions? serverPermissions,
    String? myNickname,
    List<String>? typingUsers,
    bool? roomMuted,
    String? pendingMusicSearchQuery,
    bool clearPendingMusicSearch = false,
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
      serverPermissions: serverPermissions ?? this.serverPermissions,
      myNickname: myNickname ?? this.myNickname,
      typingUsers: typingUsers ?? this.typingUsers,
      roomMuted: roomMuted ?? this.roomMuted,
      pendingMusicSearchQuery: clearPendingMusicSearch
          ? null
          : (pendingMusicSearchQuery ?? this.pendingMusicSearchQuery),
    );
  }
}

class VoiceRoomLiveController
    extends AutoDisposeFamilyNotifier<VoiceRoomLiveState, String> {
  Timer? _poll;
  Timer? _presenceHeartbeat;
  Timer? _enterBannerTimer;
  Timer? _musicRequestFlashTimer;
  var _pollPaused = false;
  var _pollTick = 0;
  String? _lastDjPlaybackSignature;
  final Set<String> _shownEntranceKeys = {};
  final Set<String> _shownMusicRequestFlashKeys = {};
  String? _presenceNickname;
  var _presenceJoined = false;
  var _sseStarted = false;
  var _sessionActive = true;
  var _autoSeatAttempted = false;

  String? _effectiveNickname(UserEntity? user) {
    final server = state.myNickname?.trim();
    if (server != null && server.isNotEmpty) return server;
    final saved = _presenceNickname?.trim();
    if (saved != null && saved.isNotEmpty) return saved;
    final nick = user?.username.trim();
    if (nick != null && nick.isNotEmpty) return nick;
    return user?.display.trim();
  }

  /// Prisma cuid — slug değil.
  String get _roomKey => arg.trim();

  VoiceRoomEntity get _roomMeta {
    final key = _roomKey;
    if (key.isEmpty) {
      return const VoiceRoomEntity(id: '', slug: '', nameTr: 'Sohbet Odası');
    }
    final rooms = ref.read(voiceRoomsProvider).valueOrNull;
    if (rooms != null) {
      for (final r in rooms) {
        if (r.apiRoomKey == key || r.id == key) return r;
        final slug = r.slug.trim();
        if (slug.isNotEmpty && slug == key) return r;
      }
    }
    return VoiceRoomEntity(id: key, slug: key, nameTr: 'Sohbet Odası');
  }

  /// Bazı DJ/müzik uçları slug ile de çalışır (cuid 404).
  String? get _musicAlternateKey {
    final slug = _roomMeta.slug.trim();
    if (slug.isEmpty || slug == _roomKey) return null;
    return slug;
  }

  String? _djChatLabel(String userId) {
    for (final p in state.presence) {
      if (p.id == userId) {
        final nick = p.nickname?.trim();
        if (nick != null && nick.isNotEmpty) return nick;
        final name = p.name.trim();
        if (name.isNotEmpty) return name;
      }
    }
    final self = ref.read(authControllerProvider).valueOrNull;
    if (self?.id == userId) {
      final u = self!.username.trim();
      if (u.isNotEmpty) return u;
    }
    return null;
  }

  ChatRoomDjState _enrichDjUsers(
    ChatRoomDjState dj,
    List<ChatRoomPresence> presence,
  ) {
    final ids = <String>{
      ..._roomMeta.djUserIds,
      ...dj.djUsers.map((u) => u.id),
      ...presence.where((p) => p.chatRole == 'dj').map((p) => p.id),
    };
    if (ids.isEmpty) return dj;
    final users = <ChatRoomUserRef>[];
    for (final id in ids) {
      final existing = dj.djUsers.where((u) => u.id == id).firstOrNull;
      if (existing != null) {
        users.add(existing);
        continue;
      }
      final p = presence.where((x) => x.id == id).firstOrNull;
      users.add(
        ChatRoomUserRef(
          id: id,
          name: p?.displayName ?? 'DJ',
          nickname: p?.nickname,
          image: p?.image,
          chatRole: 'dj',
        ),
      );
    }
    return dj.copyWith(djUsers: users);
  }

  void _prefetchYoutubePlayback(ChatRoomDjState dj) {
    final seed = dj.playbackResolveSeed ?? dj.musicUrl;
    if (seed == null || seed.trim().isEmpty) return;
    unawaited(ref.read(youtubeStreamResolverProvider).prefetch(seed));
    final videoId = ChatRoomDjState.videoIdFromLoose(seed);
    if (videoId != null && videoId.isNotEmpty) {
      unawaited(
        ref.read(youtubeStreamResolverProvider).resolveByVideoId(videoId),
      );
    }
  }

  /// Web `buildDjPayload` uyumu: önce Piped / youtube_explode, sonra sunucu stream.
  Future<String?> _resolvePlaybackStreamUrl({
    required String? videoId,
    String? serverMusicUrl,
  }) async {
    final resolver = ref.read(youtubeStreamResolverProvider);
    if (videoId != null && videoId.isNotEmpty) {
      VoiceRoomMusicPipelineLog.compareFields(
        stage: 'resolvePlaybackStream.start',
        roomId: _roomKey,
        videoId: videoId,
        serverMusicUrl: serverMusicUrl,
      );
      final fresh = await resolver.resolveByVideoId(videoId);
      if (fresh != null && fresh.startsWith('http')) {
        final client = VoiceRoomDjStreamLoader.clientPlaybackUrl(fresh);
        VoiceRoomMusicPipelineLog.compareFields(
          stage: 'resolvePlaybackStream.client',
          roomId: _roomKey,
          videoId: videoId,
          resolvedStreamUrl: client,
        );
        return client;
      }
      try {
        final api = await ref.read(resolveStreamUseCaseProvider)(
          roomId: _roomKey,
          videoId: videoId,
        );
        if (api != null && api.startsWith('http')) {
          return VoiceRoomDjStreamLoader.clientPlaybackUrl(api);
        }
      } catch (e, st) {
        VoiceRoomMusicPipelineLog.justAudioError(
          e,
          st,
          phase: 'resolvePlaybackStream.api',
          url: videoId,
        );
      }
    }

    final server = serverMusicUrl?.trim();
    if (server != null &&
        server.startsWith('http') &&
        !ChatRoomDjState.isEphemeralStreamUrl(server) &&
        !YoutubeStreamResolver.isYoutubePageUrl(server)) {
      return VoiceRoomDjStreamLoader.clientPlaybackUrl(server);
    }
    return null;
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
    final key = VoiceOfficialJoin.entranceDedupeKey(raw, roomName: _roomMeta.nameTr);
    if (_shownEntranceKeys.contains(key)) return false;
    _shownEntranceKeys.add(key);
    return true;
  }

  Object? _roomKeepAliveLink;

  @override
  VoiceRoomLiveState build(String roomKey) {
    final room = _roomMeta;
    _roomKeepAliveLink = ref.keepAlive();
    ref.onDispose(() {
      if (_sessionActive) {
        VoiceRoomDebugLog.roomLeave(roomId: _roomKey, source: 'dispose');
      }
      _poll?.cancel();
      _presenceHeartbeat?.cancel();
      _enterBannerTimer?.cancel();
      _musicRequestFlashTimer?.cancel();
      if (_sessionActive) {
        _leavePresence();
        unawaited(ref.read(voiceRoomSseServiceProvider).disconnect());
      }
      unawaited(ref.read(voiceRoomDjPlayerProvider).shutdown());
      ref.read(voiceRoomMusicSessionProvider.notifier).closePlayer();
      _closeRoomKeepAlive();
    });
    Future.microtask(() async {
      await VoiceRoomMusicAudioSession.ensureConfigured();
      ref.invalidate(coinBalanceProvider);
      ref.invalidate(walletBalancesProvider);
      await Future.wait([_joinPresence(), _warmBackgrounds()]);
      await refresh(includeDj: true);
      _startSse();
      final player = ref.read(voiceRoomDjPlayerProvider);
      player.onTrackComplete = () => unawaited(_onDjTrackComplete());
      _wireMusicControls();
      // build() bitmeden state okunamaz — poll yalnızca microtask içinde.
      _schedulePoll(sseConnected: false);
    });
    _presenceHeartbeat = Timer.periodic(const Duration(seconds: 20), (_) {
      if (state.selfInRoom) {
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

  /// Boş presence güncellemelerinde koltuk/avatar kaybını önler; dolu listede sunucu otoriter.
  List<ChatRoomPresence> _mergePresenceStable(
    List<ChatRoomPresence> incoming, {
    required String source,
  }) {
    final previous = state.presence;
    final withSelf = _mergeSelf(incoming);
    if (withSelf.isEmpty && previous.isNotEmpty) {
      VoiceRoomDebugLog.presenceUpdate(
        roomId: _roomKey,
        previousCount: previous.length,
        incomingCount: 0,
        mergedCount: previous.length,
        source: '$source.keep_previous',
      );
      return previous;
    }
    final prevById = <String, ChatRoomPresence>{
      for (final p in previous) p.id: p,
    };
    final merged = <ChatRoomPresence>[];
    for (final p in withSelf) {
      final prev = prevById[p.id];
      if (prev == null) {
        merged.add(p);
        continue;
      }
      merged.add(
        ChatRoomPresence(
          id: p.id,
          name: p.name.trim().isNotEmpty ? p.name : prev.name,
          nickname: (p.nickname?.trim().isNotEmpty == true)
              ? p.nickname
              : prev.nickname,
          image: (p.image?.trim().isNotEmpty == true) ? p.image : prev.image,
          chatRole: (p.chatRole?.trim().isNotEmpty == true)
              ? p.chatRole!
              : (prev.chatRole ?? 'listener'),
          roleSymbol: p.roleSymbol ?? prev.roleSymbol,
          membership: p.membership ?? prev.membership,
          seatIndex: p.seatIndex ?? prev.seatIndex,
          isSpeaking: p.isSpeaking || prev.isSpeaking,
        ),
      );
    }
    VoiceRoomDebugLog.presenceUpdate(
      roomId: _roomKey,
      previousCount: previous.length,
      incomingCount: withSelf.length,
      mergedCount: merged.length,
      source: source,
    );
    final seatCount = merged.where((p) => p.seatIndex != null).length;
    if (seatCount > 0) {
      VoiceRoomDebugLog.seatUpdate(
        roomId: _roomKey,
        seatCount: seatCount,
        source: source,
      );
    }
    return merged;
  }

  /// Odadan çıkış — presence, SSE ve müzik temizliği (RTC sayfası).
  Future<void> leaveRoomSession({String source = 'ui_leave'}) async {
    if (!_sessionActive) return;
    _sessionActive = false;
    VoiceRoomDebugLog.roomLeave(roomId: _roomKey, source: source);
    _poll?.cancel();
    _presenceHeartbeat?.cancel();
    _sseStarted = false;
    _presenceJoined = false;
    await _leavePresence();
    await ref.read(voiceRoomSseServiceProvider).disconnect();
    await ref.read(voiceRoomMusicSessionProvider.notifier).closePlayer();
    await ref.read(voiceRoomDjPlayerProvider).shutdown();
    if (_roomKey.isNotEmpty) {
      ref.read(roomVideoControllerProvider(_roomKey).notifier).clear();
    }
    _closeRoomKeepAlive();
  }

  Future<void> _joinPresence() async {
    if (_roomKey.isEmpty) {
      state = state.copyWith(loading: false, error: 'Geçersiz oda kimliği');
      return;
    }
    if (_presenceJoined && state.selfInRoom) {
      VoiceRoomDebugLog.roomJoin(
        roomId: _roomKey,
        source: 'presence',
        skipped: true,
      );
      return;
    }
    VoiceRoomDebugLog.roomJoin(roomId: _roomKey, source: 'presence');
    try {
      final token = await ref.read(tokenStorageProvider).readAccess();
      final hasJwt = token != null && token.isNotEmpty;
      VoiceRoomDebugLog.jwtStatus(hasToken: hasJwt, tokenLength: token?.length);
      ref.read(voiceRoomDiagnosticProvider.notifier).setJwt(hasJwt: hasJwt);
      VoiceRoomDebugLog.log('api.presence.join', {'room': _roomKey});
      final user = ref.read(authControllerProvider).valueOrNull;
      final nick = _effectiveNickname(user);
      _presenceNickname = nick;
      final joined = await ref.read(chatRoomRemoteProvider).joinPresence(
            _roomKey,
            nickname: nick,
          );
      final merged = _mergeSelf(joined);
      VoiceRoomDebugLog.log('api.presence.join.ok', {
        'count': merged.length,
        'roomId': _roomKey,
      });
      _presenceJoined = true;
      state = state.copyWith(
        presence: _mergePresenceStable(merged, source: 'join'),
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
    if (_roomKey.isEmpty || !_presenceJoined) return;
    _presenceJoined = false;
    try {
      await ref.read(chatRoomRemoteProvider).leavePresence(_roomKey);
    } catch (_) {}
  }

  Future<void> _presenceHeartbeatTick() async {
    if (_roomKey.isEmpty) return;
    try {
      VoiceRoomDebugLog.log('api.presence.heartbeat', {'room': _roomKey});
      final user = ref.read(authControllerProvider).valueOrNull;
      final list = await ref.read(chatRoomRemoteProvider).joinPresence(
            _roomKey,
            nickname: _effectiveNickname(user),
          );
      final merged = _mergeSelf(list);
      state = state.copyWith(
        presence: _mergePresenceStable(merged, source: 'heartbeat'),
        selfInRoom: true,
      );
    } catch (e) {
      VoiceRoomDebugLog.log('api.presence.heartbeat.fail', {
        'error': e.toString(),
      });
    }
  }

  void _startSse() {
    if (_roomKey.isEmpty) return;
    if (_sseStarted) {
      VoiceRoomDebugLog.log('sse.subscribe.skip', {'roomId': _roomKey});
      return;
    }
    _sseStarted = true;
    final storage = ref.read(tokenStorageProvider);
    VoiceRoomDebugLog.log('sse.subscribe', {
      'url': ChatRoomSseService.streamUrlFor(_roomKey),
      'roomId': _roomKey,
    });
    final giftsRemote = ref.read(liveGiftsRemoteProvider);
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
            ref.read(voiceRoomGiftRealtimeProvider).setSocketPreferred(false);
          },
          onDjUpdate: (payload) {
            if (payload.isNotEmpty) {
              _applyRoomVideoPayload(payload);
              unawaited(_applyDjRealtimePayload(payload));
            } else {
              unawaited(refresh(includeDj: true));
            }
          },
          onSong: (payload) {
            _applyRoomVideoPayload(payload);
            unawaited(_applyDjRealtimePayload(payload));
            _showMusicRequestFlashLine('🎵 Şarkı kuyruğa eklendi');
          },
          onGift: (payload) {
            final giftRaw = payload['gift'] ?? payload;
            if (giftRaw is! Map) return;
            final ev = giftsRemote.parseGiftEvent(
              Map<String, dynamic>.from(giftRaw),
              streamId: _roomKey,
            );
            if (ev != null) {
              ref.read(voiceRoomGiftRealtimeProvider).publishRemote(ev);
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
            final merged = _mergePresenceStable(users, source: 'sse');
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
          onTyping: (users) {
            state = state.copyWith(typingUsers: users);
          },
          onFortuneRequest: (payload) {
            final session = parseFortuneSsePayload(payload);
            if (session == null) return;
            emitFortuneLiveRequest(ref, session);
          },
        );
  }

  void _schedulePoll({bool? sseConnected, bool? musicActive}) {
    _poll?.cancel();
    _pollTick = 0;
    final sse = sseConnected ?? state.sseConnected;
    final active = musicActive ??
        (state.dj.playing || state.dj.nowPlaying != null);
    final interval = sse ? (active ? 15 : 30) : 12;
    _poll = Timer.periodic(Duration(seconds: interval), (_) {
      if (_pollPaused) return;
      _pollTick++;
      final djActive = state.dj.playing || state.dj.nowPlaying != null;
      final fullDj = !sse || djActive || (_pollTick % 2 == 0);
      unawaited(refresh(includeDj: fullDj));
    });
  }

  void _syncRoomVideo(ChatRoomDjState dj, {RoomPlaybackSync? sync}) {
    if (_roomKey.isEmpty) return;
    ref
        .read(roomVideoControllerProvider(_roomKey).notifier)
        .applyDjState(dj, sync: sync);
  }

  void _applyRoomVideoPayload(Map<String, dynamic> payload) {
    if (_roomKey.isEmpty) return;
    ref
        .read(roomVideoControllerProvider(_roomKey).notifier)
        .applyDjPayload(payload);
  }

  String _djPlaybackSignature(ChatRoomDjState dj, {required bool muted}) {
    final effective = _djWithQueuePlaybackFallback(dj);
    final videoId = ChatRoomDjState.videoIdFromLoose(
          effective.nowPlaying?.youtubeUrl ??
              effective.playbackResolveSeed ??
              '',
        ) ??
        '';
    return '${effective.playing}|$videoId|${effective.nowPlaying?.id}|'
        '${effective.musicQueue.length}|'
        '${effective.musicEnabled}|$muted';
  }

  void clearOpenCommandsPanel() {
    if (state.openCommandsPanel) {
      state = state.copyWith(clearOpenCommandsPanel: true);
    }
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
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
    final room = _roomMeta;
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
      ChatRoomMyPermissions? serverPerms = state.serverPermissions;
      String? myNickname = state.myNickname;
      var roomMuted = state.roomMuted;

      final skipMessagePoll = state.sseConnected;
      final results = await Future.wait<Object?>([
        if (skipMessagePoll)
          Future.value((
            messages: state.messages,
            myPermissions: state.serverPermissions,
            myNickname: state.myNickname,
            roomMuted: state.roomMuted,
          ))
        else
          remote.fetchMessages(_roomKey, since: since).catchError((Object e) {
            refreshError ??= e;
            return (
              messages: state.messages,
              myPermissions: state.serverPermissions,
              myNickname: state.myNickname,
              roomMuted: state.roomMuted,
            );
          }),
        remote.fetchPresence(_roomKey).catchError((Object e) {
          refreshError ??= e;
          return state.presence;
        }),
      ]);
      final msgResult = results[0]! as ({
        List<ChatRoomMessage> messages,
        ChatRoomMyPermissions? myPermissions,
        String? myNickname,
        bool? roomMuted,
      });
      fetchedMsgs = msgResult.messages;
      serverPerms = msgResult.myPermissions ?? serverPerms;
      myNickname = msgResult.myNickname ?? myNickname;
      if (msgResult.roomMuted != null) roomMuted = msgResult.roomMuted!;
      presence = _mergePresenceStable(
        results[1]! as List<ChatRoomPresence>,
        source: 'refresh',
      );

      String? bgFromDj;
      var playDjInBackground = false;
      if (includeDj) {
        try {
          if (state.dj.playing || state.dj.nowPlaying != null) {
            try {
              final musicState = await remote.fetchMusicState(
                _roomKey,
                alternateKey: _musicAlternateKey,
              );
              dj = state.dj.copyWith(
                musicQueue: musicState.queue.isNotEmpty
                    ? musicState.queue
                    : state.dj.musicQueue,
                nowPlaying: musicState.nowPlaying ?? state.dj.nowPlaying,
                playing: musicState.playing ?? state.dj.playing,
                musicUrl: musicState.musicUrl ?? state.dj.musicUrl,
              );
            } catch (_) {}
          }
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
        dj = _enrichDjUsers(dj, presence);
        _prefetchYoutubePlayback(dj);
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
        serverPermissions: serverPerms,
        myNickname: myNickname,
        roomMuted: roomMuted,
        clearError: true,
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
      unawaited(_tryAutoPrivilegedSeat());
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: ApiException.userMessage(e),
      );
    }
  }

  Future<void> _onDjTrackComplete() async {
    try {
      VoiceRoomDebugLog.log('music.track_complete.advance');
      await ref
          .read(chatRoomRemoteProvider)
          .completeMusicQueue(_roomKey, alternateKey: _musicAlternateKey);
      await refresh();
      final dj = state.dj;
      final videoId = ChatRoomDjState.videoIdFromLoose(
        dj.nowPlaying?.youtubeUrl ?? dj.playbackResolveSeed ?? '',
      );
      if (!dj.playing || videoId == null || dj.nowPlaying == null) {
        ref.read(roomVideoControllerProvider(_roomKey).notifier).clear();
        _lastDjPlaybackSignature = _djPlaybackSignature(
          dj,
          muted: !ref.read(voiceRoomUiProvider).backgroundMusicEnabled,
        );
      }
    } catch (e) {
      VoiceRoomDebugLog.log('music.track_complete.fail', {'error': '$e'});
    }
  }

  /// YouTube video modu — parça bittiğinde kuyruğu ilerlet.
  Future<void> notifyVideoTrackEnded() => _onDjTrackComplete();

  Future<void> _warmBackgrounds() async {
    try {
      final urls = await ref.read(chatRoomRemoteProvider).fetchBackgrounds();
      if (urls.isEmpty) return;
      final roomBg = _roomMeta.backgroundImageUrl?.trim();
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
    _prefetchYoutubePlayback(merged);
    return merged;
  }

  void _commitDjUi(ChatRoomDjState dj) {
    final wasMusicActive =
        state.dj.playing || state.dj.nowPlaying != null;
    state = state.copyWith(dj: dj, clearError: true);
    ref.read(voiceRoomMusicSessionProvider.notifier).syncFromRoom(
      room: _roomMeta,
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

  Future<void> _playDjInBackground(
    ChatRoomDjState dj, {
    RoomPlaybackSync? sync,
  }) async {
    final applied = await _applyDjPlayback(dj, sync: sync);
    state = state.copyWith(dj: applied);
  }

  Future<String?> _playDjInBackgroundAndReport(
    ChatRoomDjState dj, {
    RoomPlaybackSync? sync,
  }) async {
    await _playDjInBackground(dj, sync: sync);
    final player = ref.read(voiceRoomDjPlayerProvider);
    if (dj.playing &&
        !player.playback.value.playing &&
        player.diagnostics.value.lastPhase == 'sync_verify_failed') {
      return state.error ??
          'Şarkı oynatılamadı. Bağlantınızı kontrol edip tekrar deneyin.';
    }
    return state.error;
  }

  void clearPendingMusicSearch() {
    if (state.pendingMusicSearchQuery != null) {
      state = state.copyWith(clearPendingMusicSearch: true);
    }
  }

  Future<String?> submitSelectedSong(YoutubeSearchHit hit) async {
    state = state.copyWith(sending: true, clearPendingMusicSearch: true);
    try {
      final result = await ref.read(enqueueSongUseCaseProvider)(
            roomId: _roomKey,
            alternateRoomId: _musicAlternateKey,
            videoId: hit.videoId,
            title: hit.title,
            channelTitle: hit.uploader,
            thumbUrl: hit.thumbUrl,
            duration: hit.duration,
            skipPayment: false,
          );
      if (result.newBalance != null) {
        ref.invalidate(walletBalancesProvider);
      }
      await _syncMusicFromServerIfNeeded(force: true);
      final playErr = await _playDjInBackgroundAndReport(state.dj);
      state = state.copyWith(sending: false, error: playErr);
      if (playErr == null) {
        _showMusicRequestFlashLine('✅ «${hit.title}» kuyruğa eklendi');
      }
      return playErr;
    } catch (e) {
      state = state.copyWith(
        sending: false,
        error: ApiException.userMessage(e),
      );
      return ApiException.userMessage(e);
    }
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
    final np = payload['nowPlaying'];
    String? title;
    String? eventVideoId;
    if (np is Map) {
      title = np['title']?.toString();
      eventVideoId = np['videoId']?.toString() ?? np['youtubeUrl']?.toString();
    }
    eventVideoId ??= payload['currentVideoId']?.toString();
    VoiceRoomDebugLog.djUpdate(
      roomId: _roomKey,
      playing: payload['playing'] == true,
      musicUrl: payload['musicUrl']?.toString(),
      videoId: eventVideoId,
      title: title,
      source: payload['type']?.toString() ?? 'realtime',
    );
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
    if (payload['djUserIds'] is List) {
      final ids = (payload['djUserIds'] as List)
          .map((e) => e.toString())
          .where((s) => s.isNotEmpty)
          .toList();
      dj = _enrichDjUsers(
        dj.copyWith(
          djUsers: ids
              .map(
                (id) => dj.djUsers.where((u) => u.id == id).firstOrNull ??
                    ChatRoomUserRef(
                      id: id,
                      name: _djChatLabel(id) ?? 'DJ',
                      chatRole: 'dj',
                    ),
              )
              .toList(),
        ),
        state.presence,
      );
    } else if (payload['djUsers'] is List) {
      final users = (payload['djUsers'] as List)
          .whereType<Map>()
          .map(
            (e) => ChatRoomUserRef(
              id: (e['id'] ?? e['userId'] ?? '').toString(),
              name: (e['name'] ?? e['displayName'] ?? 'DJ').toString(),
              nickname: e['nickname']?.toString(),
              image: e['image']?.toString() ?? e['avatarUrl']?.toString(),
              chatRole: (e['chatRole'] ?? 'dj').toString(),
            ),
          )
          .where((u) => u.id.isNotEmpty)
          .toList();
      if (users.isNotEmpty) {
        dj = dj.copyWith(djUsers: users);
      }
    }
    _commitDjUi(dj);
    final sync = RoomPlaybackSync.fromPayload(payload);
    _syncRoomVideo(dj, sync: sync);
    final ui = ref.read(voiceRoomUiProvider);
    final sig = _djPlaybackSignature(dj, muted: !ui.backgroundMusicEnabled);
    if (sig != _lastDjPlaybackSignature) {
      unawaited(_playDjInBackground(dj, sync: sync));
      return;
    }
    if (!sync.isPlaying) {
      return;
    }
    if (sync.isPlaying) {
      final targetMs = sync.resolvedPositionMs();
      final currentMs =
          ref.read(roomVideoControllerProvider(_roomKey)).resolvedPositionMs();
      if ((targetMs - currentMs).abs() > 2500) {
        _syncRoomVideo(dj, sync: sync);
      }
    }
  }

  ChatRoomDjState _djWithQueuePlaybackFallback(ChatRoomDjState dj) {
    if (dj.playing) return dj;
    if (dj.musicQueue.isEmpty && dj.nowPlaying == null) return dj;
    if (dj.playbackSource == null && dj.youtubeFallbackSource == null) {
      return dj;
    }
    return dj.copyWith(playing: true);
  }

  Future<ChatRoomDjState> _applyDjPlayback(
    ChatRoomDjState dj, {
    RoomPlaybackSync? sync,
  }) async {
    final ui = ref.read(voiceRoomUiProvider);
    final muted = !ui.backgroundMusicEnabled;
    final session = ref.read(voiceRoomMusicSessionProvider);
    await ref.read(voiceRoomDjPlayerProvider).stop();

    if (session.dismissed || session.userDismissedPlayer) {
      _syncRoomVideo(const ChatRoomDjState(), sync: sync);
      _lastDjPlaybackSignature = _djPlaybackSignature(dj, muted: muted);
      return dj;
    }

    if (!dj.musicEnabled) {
      _syncRoomVideo(dj.copyWith(playing: false), sync: sync);
      _lastDjPlaybackSignature = _djPlaybackSignature(dj, muted: muted);
      return dj.copyWith(playing: false);
    }

    final effectiveDj = dj;
    final videoId = YoutubeVideoId.fromDj(
      currentVideoId: sync?.currentVideoId,
      nowPlayingUrl: effectiveDj.nowPlaying?.youtubeUrl,
    );
    final shouldPlay = (sync?.isPlaying ?? effectiveDj.playing) &&
        videoId != null;

    if (shouldPlay) {
      _syncRoomVideo(effectiveDj, sync: sync);
      VoiceRoomDebugLog.log('roomVideo.active', {
        'videoId': videoId,
        'room': _roomKey,
        'positionMs': sync?.resolvedPositionMs() ?? 0,
        'muted': muted,
      });
      _lastDjPlaybackSignature = _djPlaybackSignature(
        effectiveDj,
        muted: muted,
      );
      return effectiveDj;
    }

    _syncRoomVideo(effectiveDj.copyWith(playing: false), sync: sync);
    _lastDjPlaybackSignature = _djPlaybackSignature(
      effectiveDj,
      muted: muted,
    );
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
      user: msgUserFromFlash(line) ??
          const ChatRoomUserRef(id: 'system', name: 'Sistem'),
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

  MusicQueueItem _musicItemWithRequester(MusicQueueItem item, UserEntity user) {
    if (item.requestedBy != null && item.requestedBy!.id.isNotEmpty) {
      return item;
    }
    return MusicQueueItem(
      id: item.id,
      title: item.title,
      youtubeUrl: item.youtubeUrl,
      createdAt: item.createdAt,
      thumbUrl: item.thumbUrl,
      requestedBy: ChatRoomUserRef(
        id: user.id,
        name: user.display,
        nickname: user.username,
        image: user.avatarUrl,
      ),
      giftTo: item.giftTo,
      note: item.note,
      uploader: item.uploader,
      duration: item.duration,
    );
  }

  Future<String?> _submitMusicRequestByTitle(
    String title, {
    bool priority = true,
    bool skipPayment = false,
  }) async {
    final q = title.trim();
    if (q.length < 2) return 'Şarkı adı çok kısa.';

    final user = ref.read(authControllerProvider).valueOrNull;
    final perms = _permissions();
    if (!skipPayment) {
      final jeton = VoiceMusicAccess.jetonFromBalances(
        ref.read(walletBalancesProvider).valueOrNull,
      );
      if (!VoiceMusicAccess.canRequestSongs(
        dj: state.dj,
        perms: perms,
        jetonBalance: jeton,
      )) {
        return 'Şarkı isteği gönderebilmek için en az ${state.dj.musicRequestCost} jetona sahip olmalısınız.';
      }
    }

    try {
      ({
        MusicQueueItem? item,
        List<MusicQueueItem> queue,
        int? newBalance,
        int? queuePosition,
        String? musicUrl,
        bool playing,
      }) result;

      if (skipPayment) {
        final hits = await ref.read(chatRoomRemoteProvider).searchYoutube(q);
        if (hits.isEmpty) {
          return '«$q» için sonuç bulunamadı.';
        }
        final hit = hits.first;
        result = await ref
            .read(chatRoomRemoteProvider)
            .requestMusic(
              roomKey: _roomKey,
              alternateKey: _musicAlternateKey,
              title: hit.title,
              youtubeUrl: hit.url,
              thumbUrl: hit.thumbUrl,
              videoId: hit.videoId,
              duration: hit.duration,
              priority: priority,
              skipPayment: true,
            )
            .timeout(
              const Duration(seconds: 45),
              onTimeout: () => throw TimeoutException('Şarkı isteği zaman aşımı'),
            );
      } else {
        try {
          result = await ref
              .read(chatRoomRemoteProvider)
              .requestMusicByQuery(
                roomKey: _roomKey,
                alternateKey: _musicAlternateKey,
                query: q,
              )
              .timeout(
                const Duration(seconds: 45),
                onTimeout: () =>
                    throw TimeoutException('Şarkı isteği zaman aşımı'),
              );
        } on ApiException catch (e) {
          if (e.statusCode != 404 && e.statusCode != 405) rethrow;
          final hits = await ref.read(chatRoomRemoteProvider).searchYoutube(q);
          if (hits.isEmpty) {
            return '«$q» için sonuç bulunamadı.';
          }
          final hit = hits.first;
          final err = await requestMusic(
            title: hit.title,
            youtubeUrl: hit.url,
            thumbUrl: hit.thumbUrl,
            videoId: hit.videoId,
            duration: hit.duration,
            priority: priority,
          );
          if (err != null) return err;
          await _syncMusicFromServerIfNeeded(force: true);
          var dj = _djWithQueuePlaybackFallback(
            state.dj.copyWith(playing: true),
          );
          if (user != null && dj.nowPlaying != null) {
            dj = dj.copyWith(
              nowPlaying: _musicItemWithRequester(dj.nowPlaying!, user),
            );
          }
          _prefetchYoutubePlayback(dj);
          state = state.copyWith(dj: dj);
          await _playDjInBackground(dj);
          return null;
        }
      }

      ref.invalidate(coinBalanceProvider);
      ref.invalidate(walletBalancesProvider);

      var queue = result.queue;
      var nowPlaying =
          result.item ?? (queue.isNotEmpty ? queue.first : null);
      if (user != null && nowPlaying != null) {
        nowPlaying = _musicItemWithRequester(nowPlaying, user);
        queue = queue
            .map((e) => e.id == nowPlaying!.id ? nowPlaying! : e)
            .toList();
      }

      final shouldPlay = result.playing ||
          result.queuePosition == 1 ||
          queue.isNotEmpty;

      var dj = state.dj.copyWith(
        musicQueue: queue,
        nowPlaying: nowPlaying,
        playing: shouldPlay,
        musicUrl: result.musicUrl ?? nowPlaying?.youtubeUrl,
      );
      dj = _djWithQueuePlaybackFallback(dj);
      if (dj.musicUrl == null || dj.musicUrl!.isEmpty) {
        final yt = dj.nowPlaying?.youtubeUrl ?? '';
        if (yt.isNotEmpty) {
          dj = dj.copyWith(musicUrl: yt);
        }
      }
      _prefetchYoutubePlayback(dj);
      state = state.copyWith(dj: dj);
      await _syncMusicFromServerIfNeeded(force: true);
      await _playDjInBackground(state.dj);
      return null;
    } on TimeoutException {
      return await _recoverMusicRequestAfterTimeout(title);
    } on ApiException catch (e) {
      if (e.statusCode == 402 ||
          e.message.toLowerCase().contains('jeton')) {
        return 'Şarkı isteği gönderebilmek için en az ${state.dj.musicRequestCost} jetona sahip olmalısınız.';
      }
      return e.message;
    } catch (e) {
      if (e is TimeoutException) {
        return await _recoverMusicRequestAfterTimeout(title);
      }
      return ApiException.userMessage(e);
    }
  }

  Future<String?> _recoverMusicRequestAfterTimeout(String title) async {
    final needle = title.trim().toLowerCase();
    if (needle.isEmpty) {
      return 'İstek zaman aşımına uğradı. Bağlantınızı kontrol edip tekrar deneyin.';
    }
    try {
      await _syncMusicFromServerIfNeeded(force: true);
    } catch (_) {}
    final haystack = [
      state.dj.nowPlaying?.title ?? '',
      ...state.dj.musicQueue.map((e) => e.title),
    ].join(' ').toLowerCase();
    if (haystack.contains(needle) ||
        state.dj.musicQueue.any(
          (e) => e.title.toLowerCase().contains(needle),
        )) {
      await _playDjInBackground(state.dj);
      _showMusicRequestFlashLine('✅ «$title» kuyruğa eklendi');
      return null;
    }
    return 'Sunucu yanıt vermedi; bağlantınızı kontrol edip tekrar deneyin.';
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
      roomName: _roomMeta.nameTr,
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
      room: _roomMeta,
      selfPresence: self,
      server: state.serverPermissions,
    );
  }

  int _seatRolePriority(ChatRoomPresence occupant) {
    final room = _roomMeta;
    if (room.ownerId == occupant.id ||
        occupant.chatRole == 'owner' ||
        occupant.chatRole == 'founder') {
      return 4;
    }
    if (occupant.chatRole == 'admin' || occupant.chatRole == 'superadmin') {
      return 3;
    }
    if (occupant.chatRole == 'moderator' ||
        occupant.chatRole == 'mod' ||
        occupant.chatRole == 'op' ||
        occupant.chatRole == 'sop') {
      return 2;
    }
    if (occupant.chatRole == 'dj' || room.djUserIds.contains(occupant.id)) {
      return 1;
    }
    return 0;
  }

  int? _privilegedRolePriority(
    UserEntity user,
    ChatRoomMyPermissions? server,
    ChatRoomPresence? self,
  ) {
    final perms = VoiceRoomPermissions.forUser(
      user: user,
      room: _roomMeta,
      selfPresence: self,
      server: server,
    );
    if (server?.isRoomOwner == true || perms.isRoomOwner) return 4;
    if (server?.isGlobalAdmin == true || perms.isSiteAdmin) return 3;
    final role = (server?.role ?? self?.chatRole ?? '').toLowerCase();
    if (role == 'moderator' ||
        role == 'mod' ||
        role == 'op' ||
        role == 'sop' ||
        perms.canModerate) {
      return 2;
    }
    if (role == 'dj' ||
        _roomMeta.djUserIds.contains(user.id) ||
        perms.canManageDj) {
      return 1;
    }
    return null;
  }

  int? _pickAutoSeatIndex({
    required int myPriority,
    required List<ChatRoomPresence> presence,
  }) {
    if (myPriority >= 4) return 1;
    final occupied = <int, ChatRoomPresence>{
      for (final p in presence)
        if (p.seatIndex != null) p.seatIndex!: p,
    };
    for (var seat = 2; seat <= 11; seat++) {
      final occupant = occupied[seat];
      if (occupant == null) return seat;
      if (myPriority > _seatRolePriority(occupant)) return seat;
    }
    return null;
  }

  Future<void> _tryAutoPrivilegedSeat() async {
    if (_autoSeatAttempted || _roomKey.isEmpty || !state.selfInRoom) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    ChatRoomPresence? self;
    for (final p in state.presence) {
      if (p.id == user.id) {
        self = p;
        break;
      }
    }
    if (self?.seatIndex != null) {
      _autoSeatAttempted = true;
      return;
    }

    final priority = _privilegedRolePriority(
      user,
      state.serverPermissions,
      self,
    );
    if (priority == null) return;

    final seatIndex = _pickAutoSeatIndex(
      myPriority: priority,
      presence: state.presence,
    );
    if (seatIndex == null) return;

    _autoSeatAttempted = true;
    VoiceRoomDebugLog.log('seat.auto_join', {
      'room': _roomKey,
      'seat': seatIndex,
      'priority': priority,
    });
    try {
      await ref.read(chatRoomRemoteProvider).joinSeat(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            seatIndex: seatIndex,
            userId: user.id,
          );
      await refresh();
    } catch (e) {
      await assignSeat(seatIndex: seatIndex);
    }
  }

  Future<String?> toggleRoomMute({required bool mute}) async {
    final perms = _permissions();
    if (!perms.canMuteRoom && !perms.isRoomOwner && !perms.isSiteAdmin) {
      return 'Oda sessize alma yetkiniz yok.';
    }
    try {
      await ref.read(chatRoomRemoteProvider).muteRoom(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            mute: mute,
          );
      state = state.copyWith(roomMuted: mute);
      await refresh();
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
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

    if (VoiceMusicSync.isIstekCommand(trimmed)) {
      final song = VoiceMusicSync.parseIstekSongTitle(trimmed);
      if (song == null || song.isEmpty) {
        state = state.copyWith(error: 'Kullanım: !istek Sanatçı - Şarkı adı');
        _showMusicRequestFlashLine('🎵 Kullanım: !istek Sanatçı - Şarkı adı');
        return;
      }
      VoiceRoomDebugLog.log('music.istek.api', {'song': song, 'room': _roomKey});
      ref.read(voiceRoomMusicSessionProvider.notifier).clearUserDismissed();
      _showMusicRequestFlashLine('🔍 «$song» aranıyor…');
      state = state.copyWith(sending: true, clearError: true);
      try {
        final err = await _submitMusicRequestByTitle(song, priority: false);
        state = state.copyWith(sending: false);
        if (err != null) {
          state = state.copyWith(error: err);
          _showMusicRequestFlashLine('⚠️ $err');
        } else {
          _showMusicRequestFlashLine('✅ «$song» kuyruğa eklendi');
        }
      } catch (e) {
        final msg = ApiException.userMessage(e);
        state = state.copyWith(sending: false, error: msg);
        _showMusicRequestFlashLine('⚠️ $msg');
      }
      return;
    } else if (_isLocalHelpCommand(trimmed)) {
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
            .sendMessage(
              roomKey: _roomKey,
              content: trimmed,
              nickname: _effectiveNickname(user),
            )
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
            alternateKey: _roomMeta.slug,
            userId: target.id,
            reason: command.reason,
          );
          break;
        case 'unban':
          if (target == null) return;
          await remote.unbanUser(
            roomKey: _roomKey,
            alternateKey: _roomMeta.slug,
            userId: target.id,
          );
          break;
        case 'at':
        case 'kick':
          if (target == null) return;
          await remote.kickUser(
            roomKey: _roomKey,
            alternateKey: _roomMeta.slug,
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
            alternateKey: _roomMeta.slug,
            userId: target.id,
            minutes: command.minutes ?? 30,
            reason: command.reason,
          );
          break;
        case 'yetki':
          if (target == null || command.roleSymbol == null) return;
          await remote.assignRole(
            roomKey: _roomKey,
            alternateKey: _roomMeta.slug,
            userId: target.id,
            roleSymbol: command.roleSymbol!,
          );
          break;
        case 'dj':
          if (target == null) return;
          await Future<void>.delayed(const Duration(milliseconds: 900));
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
        case 'odasesiz':
        case 'sessizoda':
          if (_permissions().canMuteRoom ||
              _permissions().isRoomOwner ||
              _permissions().isSiteAdmin) {
            await remote.muteRoom(roomKey: _roomKey, mute: true);
          }
          break;
        case 'odaac':
        case 'odases':
          if (_permissions().canMuteRoom ||
              _permissions().isRoomOwner ||
              _permissions().isSiteAdmin) {
            await remote.muteRoom(roomKey: _roomKey, mute: false);
          }
          break;
        case 'unmute':
        case 'susturma':
          if (target == null) return;
          await remote.unmuteUser(
            roomKey: _roomKey,
            alternateKey: _roomMeta.slug,
            userId: target.id,
          );
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
    if (state.dj.canControlMusic || state.dj.canPlayMusic) return true;
    final user = ref.read(authControllerProvider).valueOrNull;
    final np = state.dj.nowPlaying;
    if (user != null && np?.requestedBy?.id == user.id) return true;
    final perms = _permissions();
    return perms.isRoomOwner || perms.isSiteAdmin || perms.canManageDj;
  }

  Future<String?> pauseMusic() async {
    if (!_canControlMusic()) {
      return 'Bu işlemi gerçekleştirme yetkiniz bulunmamaktadır.';
    }
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
      _syncRoomVideo(state.dj.copyWith(playing: false));
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> resumeMusic() async {
    if (!_canControlMusic()) {
      return 'Bu işlemi gerçekleştirme yetkiniz bulunmamaktadır.';
    }
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
            roomKey: _roomKey.isNotEmpty ? _roomKey : _roomMeta.id,
            alternateKey: _roomMeta.slug,
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
    String? duration,
    String? giftTo,
    String? note,
    bool priority = true,
    bool djMusicControl = false,
  }) async {
    try {
      var resolvedUrl = youtubeUrl.trim();
      var resolvedThumb = thumbUrl;
      var resolvedVideoId = videoId;
      var resolvedDuration = duration;
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
        resolvedDuration ??= hit.duration;
      }
      if (resolvedUrl.isEmpty) {
        return 'Geçerli bir şarkı seçin veya arayın.';
      }
      unawaited(ref.read(youtubeStreamResolverProvider).prefetch(resolvedUrl));
      VoiceRoomDebugLog.log('music.request', {
        'title': title,
        'priority': priority,
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
            duration: resolvedDuration,
            dedication: giftTo,
            giftTo: giftTo,
            note: note,
            priority: priority,
            djMusicControl: djMusicControl,
          )
          .timeout(
            const Duration(seconds: 45),
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
      dj = _djWithQueuePlaybackFallback(dj);
      _prefetchYoutubePlayback(dj);
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
      final label = _djChatLabel(targetUserId);
      final ids = await ref.read(chatRoomRemoteProvider).addRoomDj(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            targetUserId: targetUserId,
            targetLabel: label,
          );
      final enriched = _enrichDjUsers(
        state.dj,
        state.presence,
      ).copyWith(
        djUsers: ids
            .map(
              (id) => state.dj.djUsers
                      .where((u) => u.id == id)
                      .firstOrNull ??
                  ChatRoomUserRef(
                    id: id,
                    name: _djChatLabel(id) ?? 'DJ',
                    chatRole: 'dj',
                  ),
            )
            .toList(),
      );
      state = state.copyWith(dj: enriched);
      await refresh(includeDj: true);
      ref.invalidate(voiceRoomsProvider);
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> removeRoomDj(String targetUserId) async {
    try {
      final label = _djChatLabel(targetUserId);
      await ref.read(chatRoomRemoteProvider).removeRoomDj(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            targetUserId: targetUserId,
            targetLabel: label,
          );
      await refresh();
      ref.invalidate(voiceRoomsProvider);
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> setActiveDj(String? targetUserId) async {
    try {
      await ref.read(chatRoomRemoteProvider).setActiveDj(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            userId: targetUserId,
          );
      await refresh(includeDj: true);
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
            .read(voiceRoomLiveProvider(room.liveKey).notifier)
            .refresh(includeDj: true);
        final live = ref.read(voiceRoomLiveProvider(room.liveKey));
        state = state.copyWith(dj: live.dj);
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
    .family<VoiceRoomLiveController, VoiceRoomLiveState, String>(
      VoiceRoomLiveController.new,
    );
