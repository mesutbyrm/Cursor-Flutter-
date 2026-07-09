import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/voice_staff_rank.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/performance/network_perf.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../live_psychics/presentation/providers/psychic_live_event_bus.dart';
import '../../data/datasources/chat_room_remote_datasource.dart';
import '../../data/services/voice_room_debug_log.dart';
import '../../data/services/voice_room_music_pipeline_log.dart';
import '../../data/services/chat_room_sse_service.dart';
import '../../data/services/voice_room_gift_socket.dart';
import '../../data/services/voice_seat_rest_service.dart';
import 'pk_battle_provider.dart';
import 'pk_battle_remote_provider.dart';
import '../../../../core/network/sse/sse_hub_provider.dart';
import '../../data/youtube_music_search_cache.dart';
import '../../../live/presentation/gifts/providers/live_gift_providers.dart';
import '../../music/domain/entities/room_playback_sync.dart';
import '../../music/presentation/providers/room_music_providers.dart';
import '../../domain/entities/chat_room_dj_state.dart';
import '../../domain/entities/music_queue_item.dart';
import '../../domain/entities/chat_room_message.dart';
import '../../domain/voice_playback_limits.dart';
import '../../domain/voice_music_sync.dart';
import '../../domain/utils/voice_banned_word_filter.dart';
import '../../domain/voice_official_join.dart';
import '../audio/voice_room_music_audio_session.dart';
import '../utils/voice_room_permissions.dart';
import '../utils/kick_strike_ui.dart';
import '../utils/voice_sse_dj_payload.dart';
import '../utils/voice_music_access.dart';
import '../utils/voice_room_duyuru_access.dart';
import '../utils/voice_room_mention.dart';
import '../utils/voice_room_seat_priority.dart';
import '../utils/voice_staff_chat_style.dart';
import '../utils/voice_room_message_merge.dart';
import 'voice_rooms_presence_provider.dart';
import '../widgets/voice_room/voice_room_music_request_flash.dart';
import '../basic/voice_room_basic_mode.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/chat_room_my_permissions.dart';
import '../../domain/entities/moderation_result.dart';
import '../../domain/entities/voice_room_ban_entry.dart';
import '../../domain/entities/voice_room_realtime_event.dart';
import '../../domain/entities/popular_music_suggestion.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/youtube_stream_resolver.dart';
import '../audio/voice_room_dj_stream_loader.dart';
import '../services/voice_room_dj_player.dart';
import '../services/voice_room_sse_audio_player.dart';
import '../services/voice_room_music_control_delegate.dart';
import '../../video/domain/youtube_video_id.dart';
import '../../video/presentation/room_video_controller.dart';
import 'voice_gift_providers.dart';
import 'voice_gift_leaderboard_provider.dart';
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

final voiceSeatRestServiceProvider = Provider<VoiceSeatRestService>((ref) {
  return VoiceSeatRestService(ref.watch(chatRoomRemoteProvider));
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

final voiceRoomSseAudioPlayerProvider = Provider<VoiceRoomSseAudioPlayer>((ref) {
  final p = VoiceRoomSseAudioPlayer();
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
    this.pendingMusicSearchSkipPayment = false,
    this.moderatorAnnouncement,
    this.pinnedAnnouncement,
    this.chatClearedBannerNonce = 0,
    this.moderationToast,
    this.kickStrikeWarning,
    this.kickStrikeCount = 0,
    this.realtimeEvents = const [],
    this.musicLikeCount = 0,
    this.bannedWords = const [],
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
  final bool pendingMusicSearchSkipPayment;
  final String? moderatorAnnouncement;
  final String? pinnedAnnouncement;
  final int chatClearedBannerNonce;
  final String? moderationToast;
  final String? kickStrikeWarning;
  final int kickStrikeCount;
  final List<VoiceRoomRealtimeEvent> realtimeEvents;
  final int musicLikeCount;
  final List<String> bannedWords;

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
    bool? pendingMusicSearchSkipPayment,
    String? moderatorAnnouncement,
    bool clearModeratorAnnouncement = false,
    String? pinnedAnnouncement,
    bool clearPinnedAnnouncement = false,
    int? chatClearedBannerNonce,
    String? moderationToast,
    bool clearModerationToast = false,
    String? kickStrikeWarning,
    int? kickStrikeCount,
    bool clearKickStrikeWarning = false,
    List<VoiceRoomRealtimeEvent>? realtimeEvents,
    int? musicLikeCount,
    List<String>? bannedWords,
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
      pendingMusicSearchSkipPayment: clearPendingMusicSearch
          ? false
          : (pendingMusicSearchSkipPayment ?? this.pendingMusicSearchSkipPayment),
      moderatorAnnouncement: clearModeratorAnnouncement
          ? null
          : (moderatorAnnouncement ?? this.moderatorAnnouncement),
      pinnedAnnouncement: clearPinnedAnnouncement
          ? null
          : (pinnedAnnouncement ?? this.pinnedAnnouncement),
      chatClearedBannerNonce:
          chatClearedBannerNonce ?? this.chatClearedBannerNonce,
      moderationToast: clearModerationToast
          ? null
          : (moderationToast ?? this.moderationToast),
      kickStrikeWarning: clearKickStrikeWarning
          ? null
          : (kickStrikeWarning ?? this.kickStrikeWarning),
      kickStrikeCount: clearKickStrikeWarning
          ? 0
          : (kickStrikeCount ?? this.kickStrikeCount),
      realtimeEvents: realtimeEvents ?? this.realtimeEvents,
      musicLikeCount: musicLikeCount ?? this.musicLikeCount,
      bannedWords: bannedWords ?? this.bannedWords,
    );
  }
}

class VoiceRoomLiveController
    extends AutoDisposeFamilyNotifier<VoiceRoomLiveState, String> {
  Timer? _poll;
  Timer? _presenceHeartbeat;
  Timer? _typingStopTimer;
  Timer? _enterBannerTimer;
  Timer? _musicRequestFlashTimer;
  Timer? _announcementTimer;
  Timer? _pinnedAnnouncementTimer;
  Timer? _moderationToastTimer;
  Timer? _kickWarningTimer;
  final _pollPaused = false;
  var _pollTick = 0;
  String? _lastDjPlaybackSignature;
  /// Sohbet temizlendiğinde işaretlenen zaman — sonraki poll'de sunucunun
  /// tekrar döndürdüğü eski mesajlar bu işaretten eski ise gösterilmez
  /// ("temizle sonrası yazılar geri geliyor" sorunu).
  DateTime? _chatClearedWatermark;
  final Set<String> _shownEntranceKeys = {};
  final Set<String> _knownPresenceIds = {};
  /// Ayrılış duyurusu için son bilinen isimler (id → ad).
  final Map<String, String> _lastKnownPresenceNames = {};
  final Set<String> _shownMusicRequestFlashKeys = {};
  String? _lastDuyuruText;
  DateTime? _lastDuyuruShownAt;
  String? _presenceNickname;
  var _presenceJoined = false;
  var _voiceJoined = false;
  var _typingActive = false;
  var _sseStarted = false;
  var _giftSocketStarted = false;
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
    final orderedIds = <String>[];
    void addId(String id) {
      final trimmed = id.trim();
      if (trimmed.isEmpty || orderedIds.contains(trimmed)) return;
      orderedIds.add(trimmed);
    }

    final active = dj.activeDjId?.trim();
    if (active != null && active.isNotEmpty) addId(active);
    for (final u in dj.djUsers) {
      addId(u.id);
    }
    for (final id in _roomMeta.djUserIds) {
      addId(id);
    }
    for (final p in presence) {
      if (p.chatRole == 'dj') addId(p.id);
    }
    if (orderedIds.isEmpty) return dj;

    final users = <ChatRoomUserRef>[];
    for (final id in orderedIds) {
      final existing = dj.djUsers.where((u) => u.id == id).firstOrNull;
      if (existing != null) {
        users.add(existing);
        continue;
      }
      final p = presence.where((x) => x.id == id).firstOrNull;
      users.add(
        ChatRoomUserRef(
          id: id,
          name: p?.displayName ?? _djChatLabel(id) ?? 'DJ',
          nickname: p?.nickname,
          image: p?.image,
          chatRole: 'dj',
        ),
      );
    }
    return dj.copyWith(djUsers: users);
  }

  Future<String?> _resolveDjStreamUrl(
    ChatRoomDjState dj, {
    RoomPlaybackSync? sync,
  }) async {
    final resolver = ref.read(youtubeStreamResolverProvider);
    final videoId = ChatRoomDjState.videoIdFromLoose(
          dj.nowPlaying?.youtubeUrl ??
              sync?.currentVideoId ??
              dj.playbackResolveSeed ??
              dj.musicUrl ??
              '',
        ) ??
        YoutubeVideoId.fromDj(
          currentVideoId: sync?.currentVideoId,
          nowPlayingUrl: dj.nowPlaying?.youtubeUrl,
        );
    if (videoId != null && videoId.isNotEmpty) {
      final viaId = await resolver.resolveByVideoId(videoId);
      if (viaId != null &&
          viaId.startsWith('http') &&
          !YoutubeStreamResolver.isYoutubeStreamApiUrl(viaId)) {
        return viaId;
      }
    }
    final seed = dj.playbackResolveSeed ?? dj.youtubeFallbackSource;
    if (seed != null && seed.trim().isNotEmpty) {
      final resolved = await resolver.resolvePlayableUrl(seed);
      if (resolved != null &&
          resolved.startsWith('http') &&
          !YoutubeStreamResolver.isYoutubeStreamApiUrl(resolved)) {
        return resolved;
      }
    }
    final raw = sync?.streamUrl ?? dj.musicUrl;
    if (raw != null &&
        raw.trim().isNotEmpty &&
        !YoutubeStreamResolver.isYoutubeStreamApiUrl(raw) &&
        !ChatRoomDjState.isEphemeralStreamUrl(raw) &&
        !YoutubeStreamResolver.isYoutubePageUrl(raw)) {
      return raw.trim();
    }
    return null;
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
    return VoiceRoomMessageMerge.merge(current, fetched);
  }

  bool _markEntranceOnce(String raw) {
    final key = VoiceOfficialJoin.entranceDedupeKey(raw, roomName: _roomMeta.nameTr);
    if (_shownEntranceKeys.contains(key)) return false;
    _shownEntranceKeys.add(key);
    return true;
  }

  void _syncPresenceJoinAnnouncements(List<ChatRoomPresence> merged) {
    final previous = _knownPresenceIds;
    final nextIds = merged.map((p) => p.id).where((id) => id.isNotEmpty).toSet();
    if (previous.isEmpty) {
      _knownPresenceIds
        ..clear()
        ..addAll(nextIds);
      return;
    }
    for (final user in merged) {
      if (user.id.isEmpty || previous.contains(user.id)) continue;
      _announcePresenceJoin(user);
    }
    // Ayrılanlar — poll ile (SSE gelmese de) herkes çıkışı görsün.
    final departedIds = previous.difference(nextIds);
    if (departedIds.isNotEmpty) {
      final self = ref.read(authControllerProvider).valueOrNull?.id;
      for (final id in departedIds) {
        if (id.isEmpty || id == self) continue;
        final name = _lastKnownPresenceNames[id];
        if (name != null && name.isNotEmpty) {
          _notifyRealtimeIfBasic(
            VoiceRoomRealtimeKind.leave,
            '$name odadan ayrıldı',
          );
        }
      }
    }
    for (final p in merged) {
      if (p.id.isEmpty) continue;
      final n = p.displayName.trim().isNotEmpty
          ? p.displayName.trim()
          : p.name.trim();
      if (n.isNotEmpty) _lastKnownPresenceNames[p.id] = n;
    }
    _knownPresenceIds
      ..clear()
      ..addAll(nextIds);
  }

  void _announcePresenceJoin(ChatRoomPresence user) {
    final name = user.displayName.trim().isNotEmpty
        ? user.displayName.trim()
        : user.name.trim();
    if (name.isEmpty) return;
    final userRef = ChatRoomUserRef(
      id: user.id,
      name: user.name,
      nickname: user.nickname,
      image: user.image,
      chatRole: user.chatRole,
    );
    if (VoiceStaffChatStyle.isStaffEntry(content: name, user: userRef)) {
      _showStaffEnterBanner(name, user: userRef);
      return;
    }
    final line = VoiceOfficialJoin.formatEntranceBanner(
      '$name giriş yaptı',
      roomName: _roomMeta.nameTr,
    );
    if (line.isEmpty || !_markEntranceOnce(line)) return;
    state = state.copyWith(enterBanner: line);
    _enterBannerTimer?.cancel();
    _enterBannerTimer = Timer(const Duration(seconds: 10), () {
      if (!_sessionActive) return;
      state = state.copyWith(clearEnterBanner: true);
    });
  }

  void _showStaffEnterBanner(String name, {ChatRoomUserRef? user}) {
    final line = VoiceStaffChatStyle.formatStaffEntryLine(
      name,
      user: user,
      roomName: _roomMeta.nameTr,
    );
    if (!_markEntranceOnce(line)) return;
    state = state.copyWith(enterBanner: line);
    _enterBannerTimer?.cancel();
    _enterBannerTimer = Timer(const Duration(seconds: 10), () {
      if (!_sessionActive) return;
      state = state.copyWith(clearEnterBanner: true);
    });
  }

  Object? _roomKeepAliveLink;
  var _keepAliveTransferred = false;

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
      _typingStopTimer?.cancel();
      _enterBannerTimer?.cancel();
      _musicRequestFlashTimer?.cancel();
      _announcementTimer?.cancel();
      _pinnedAnnouncementTimer?.cancel();
      _moderationToastTimer?.cancel();
      _kickWarningTimer?.cancel();
      if (_sessionActive) {
        unawaited(_leaveVoiceSession());
        unawaited(_leavePresence());
        unawaited(_stopTyping());
        ref.read(sseConnectionHubProvider).releaseVoiceRoom(_roomKey);
        ref.read(voiceRoomGiftSocketProvider).disconnect();
      }
      final session = ref.read(voiceRoomMusicSessionProvider);
      final detachedHere =
          session.room?.liveKey == roomKey && session.hasActiveMusic;
      if (!_keepAliveTransferred && !detachedHere) {
        unawaited(ref.read(voiceRoomDjPlayerProvider).shutdown());
        ref.read(voiceRoomMusicSessionProvider.notifier).closePlayer();
        _closeRoomKeepAlive();
      }
    });
    Future.microtask(() => _beginRoomSession());
    _presenceHeartbeat = Timer.periodic(
      ChatRoomRemoteDataSource.presenceHeartbeatInterval,
      (_) {
      if (state.selfInRoom) {
        unawaited(_presenceHeartbeatTick());
      }
    });
    return VoiceRoomLiveState(
      backgroundUrl: room.backgroundImageUrl?.trim().isNotEmpty == true
          ? room.backgroundImageUrl
          : null,
      loading: false,
    );
  }

  /// Odaya giriş — POST presence → GET messages → SSE → heartbeat.
  Future<void> _beginRoomSession() async {
    ref
        .read(voiceRoomMusicSessionProvider.notifier)
        .prepareForRoomEntry(_roomMeta);
    unawaited(VoiceRoomMusicAudioSession.ensureConfigured());
    state = state.copyWith(loading: false);

    try {
      await _joinPresence();
      unawaited(_loadInitialMessages());
    } catch (_) {
      state = state.copyWith(loading: false);
    }

    _startSse();
    _schedulePoll(sseConnected: false);
    unawaited(_bootstrapRoomData());
  }

  Future<void> _loadInitialMessages() async {
    if (_roomKey.isEmpty) return;
    try {
      final bundle =
          await ref.read(chatRoomRemoteProvider).fetchMessages(_roomKey);
      state = state.copyWith(
        messages: _filterClearedMessages(
          _mergeMessages(state.messages, bundle.messages),
        ),
        serverPermissions: bundle.myPermissions ?? state.serverPermissions,
        myNickname: bundle.myNickname ?? state.myNickname,
        roomMuted: bundle.roomMuted ?? state.roomMuted,
        loading: false,
      );
    } catch (_) {}
  }

  Future<void> _bootstrapRoomData() async {
    unawaited(_loadBannedWords());
    try {
      await _warmBackgrounds();
    } catch (_) {
      state = state.copyWith(loading: false);
    }

    final includeDj = VoiceRoomBasicMode.enabled
        ? VoiceRoomBasicMode.musicEnabled
        : true;
    try {
      await refresh(includeDj: includeDj);
    } catch (_) {}

    if (VoiceRoomBasicMode.enabled) {
      if (VoiceRoomBasicMode.musicEnabled) {
        final player = ref.read(voiceRoomDjPlayerProvider);
        player.onTrackComplete = () => unawaited(_onDjTrackComplete());
        _wireMusicControls();
      }
      if (VoiceRoomBasicMode.premiumEnabled) {
        _startGiftSocket();
      }
      unawaited(_loadGiftLeaderboard());
      return;
    }

    _startGiftSocket();
    final player = ref.read(voiceRoomDjPlayerProvider);
    player.onTrackComplete = () => unawaited(_onDjTrackComplete());
    _wireMusicControls();
    unawaited(_loadGiftLeaderboard());
  }

  Future<void> _loadBannedWords() async {
    if (_roomKey.isEmpty) return;
    try {
      final words =
          await ref.read(chatRoomRemoteProvider).fetchBannedWords(_roomKey);
      state = state.copyWith(bannedWords: words);
    } catch (_) {}
  }

  Future<void> _loadGiftLeaderboard() async {
    if (_roomKey.isEmpty) return;
    try {
      final entries = await ref
          .read(chatRoomGiftsRemoteProvider)
          .fetchRoomGiftLeaderboard(roomId: _roomKey);
      if (entries.isNotEmpty) {
        ref.read(voiceSessionGiftLeaderboardProvider.notifier).seedFromApi(entries);
      }
    } catch (_) {}
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
          isMuted: p.isMuted,
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

  void _pushRealtimeEvent(VoiceRoomRealtimeKind kind, String message) {
    final line = message.trim();
    if (line.isEmpty) return;
    final event = VoiceRoomRealtimeEvent(
      kind: kind,
      message: line,
      at: DateTime.now(),
    );
    state = state.copyWith(
      realtimeEvents: VoiceRoomRealtimeEvent.append(state.realtimeEvents, event),
    );
  }

  void _notifyRealtimeIfBasic(VoiceRoomRealtimeKind kind, String message) {
    _pushRealtimeEvent(kind, message);
  }

  void _pushBasicChatEvent(ChatRoomMessage msg) {
    final name = msg.user?.displayName.trim().isNotEmpty == true
        ? msg.user!.displayName.trim()
        : (msg.user?.name.trim().isNotEmpty == true
            ? msg.user!.name.trim()
            : 'Biri');
    switch (msg.kind) {
      case ChatMessageKind.gift:
        final emoji = msg.giftEmoji ?? '🎁';
        _pushRealtimeEvent(
          VoiceRoomRealtimeKind.system,
          '$name $emoji hediye gönderdi',
        );
      case ChatMessageKind.systemJoin:
        _pushRealtimeEvent(VoiceRoomRealtimeKind.join, msg.content.trim());
      case ChatMessageKind.systemLeave:
        _pushRealtimeEvent(VoiceRoomRealtimeKind.leave, msg.content.trim());
      case ChatMessageKind.text:
        final text = msg.content.trim();
        if (text.isNotEmpty) {
          _pushRealtimeEvent(VoiceRoomRealtimeKind.system, '$name: $text');
        }
      case ChatMessageKind.unknown:
        break;
    }
  }

  void _detectMicChanges(List<ChatRoomPresence> next) {
    final prev = {for (final p in state.presence) p.id: p.isSpeaking};
    for (final p in next) {
      final was = prev[p.id];
      if (was == null || was == p.isSpeaking) continue;
      final name = p.displayName.trim().isNotEmpty
          ? p.displayName.trim()
          : p.name.trim();
      if (name.isEmpty) continue;
      _pushRealtimeEvent(
        p.isSpeaking ? VoiceRoomRealtimeKind.micOn : VoiceRoomRealtimeKind.micOff,
        p.isSpeaking ? '$name konuşuyor' : '$name sustu',
      );
    }
  }

  void _handleSseRoomUpdate(Map<String, dynamic> payload) {
    final users = _presenceFromSsePayload(payload);
    if (users.isNotEmpty) {
      final merged = _mergePresenceStable(users, source: 'sse_room_update');
      _detectMicChanges(merged);
      state = state.copyWith(
        presence: merged,
        sseConnected: true,
        selfInRoom: true,
      );
      ref
          .read(voiceRoomDiagnosticProvider.notifier)
          .setPresence(joined: true, count: merged.length);
    }

    final msg = payload['message']?.toString().trim();
    if (msg != null && msg.isNotEmpty) {
      _notifyRealtimeIfBasic(VoiceRoomRealtimeKind.roomUpdate, msg);
      if (VoiceRoomBasicMode.enabled) {
        showModerationToast(msg);
      }
    } else {
      _notifyRealtimeIfBasic(
        VoiceRoomRealtimeKind.roomUpdate,
        'Oda güncellendi',
      );
    }

    final bg = payload['backgroundImageUrl']?.toString().trim() ??
        payload['backgroundUrl']?.toString().trim();
    if (bg != null && bg.isNotEmpty) {
      state = state.copyWith(backgroundUrl: bg);
    }

    unawaited(refresh(includeDj: true));
  }

  /// Odadan çıkış — presence, SSE ve müzik temizliği (RTC sayfası).
  /// Ağır işlemler UI'ı bloklamaz; navigasyon hemen yapılabilir.
  Future<void> leaveRoomSession({String source = 'ui_leave'}) async {
    if (!_sessionActive) return;
    _sessionActive = false;
    VoiceRoomDebugLog.roomLeave(roomId: _roomKey, source: source);
    _poll?.cancel();
    _presenceHeartbeat?.cancel();
    _typingStopTimer?.cancel();
    _sseStarted = false;
    _giftSocketStarted = false;
    unawaited(_leaveVoiceSession());
    unawaited(_leavePresence());
    unawaited(_stopTyping());
    ref.read(sseConnectionHubProvider).releaseVoiceRoom(_roomKey);
    ref.read(voiceRoomGiftSocketProvider).disconnect();

    final player = ref.read(voiceRoomDjPlayerProvider);
    final dj = state.dj;
    final stillPlaying = player.playback.value.playing ||
        dj.playing ||
        dj.nowPlaying != null ||
        dj.musicQueue.isNotEmpty;

    if (stillPlaying && _roomKeepAliveLink != null) {
      ref.read(voiceRoomMusicSessionProvider.notifier).onRoomDetached(
            room: _roomMeta,
            dj: dj,
            canSyncServer: _canControlMusic(),
            canStopMusic: _canStopMusic(),
            keepAliveLink: _roomKeepAliveLink!,
          );
      _keepAliveTransferred = true;
      _roomKeepAliveLink = null;
    } else {
      unawaited(ref.read(voiceRoomMusicSessionProvider.notifier).closePlayer());
      unawaited(player.shutdown());
      if (_roomKey.isNotEmpty) {
        ref.read(roomVideoControllerProvider(_roomKey).notifier).clear();
      }
      _closeRoomKeepAlive();
    }
  }

  bool _hasDjPlayableSource(
    ChatRoomDjState dj, {
    RoomPlaybackSync? sync,
    String? videoId,
  }) {
    if (videoId != null && videoId.isNotEmpty) return true;
    if (sync?.currentVideoId?.trim().isNotEmpty == true) return true;
    if (dj.nowPlaying?.resolvedVideoId?.trim().isNotEmpty == true) return true;
    if (dj.nowPlaying?.youtubeUrl?.trim().isNotEmpty == true) return true;
    if (sync?.streamUrl?.trim().isNotEmpty == true) return true;
    if (dj.musicUrl?.trim().isNotEmpty == true) return true;
    return false;
  }

  Future<void> _handleUnplayableEmbed() async {
    _showMusicRequestFlashLine(
      '⚠️ Bu şarkı çalınamıyor, lütfen başka bir şarkı deneyin.',
    );
    if (!_canControlMusic() && !_canStopMusic()) return;
    try {
      final result = await ref.read(chatRoomRemoteProvider).clearMusicQueue(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
          );
      if (result.autoAdvanced) {
        await refresh();
      } else {
        await _handleMusicStoppedFromSse();
      }
    } catch (_) {
      await _handleMusicStoppedFromSse();
    }
  }

  void _patchHubPresenceCount(int count) {
    if (_roomKey.isEmpty) return;
    ref.read(voiceRoomsPresenceProvider.notifier).patchRoomCount(_roomKey, count);
    final alt = _roomMeta.slug.trim();
    if (alt.isNotEmpty && alt != _roomKey) {
      ref.read(voiceRoomsPresenceProvider.notifier).patchRoomCount(alt, count);
    }
  }

  Future<void> _broadcastStaffEntryIfNeeded() async {
    if (_roomKey.isEmpty) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;
    ChatRoomPresence? self;
    for (final p in state.presence) {
      if (p.id == user.id) {
        self = p;
        break;
      }
    }
    final userRef = ChatRoomUserRef(
      id: user.id,
      name: user.display,
      nickname: user.username,
      image: user.avatarUrl,
      chatRole: self?.chatRole,
    );
    if (!VoiceStaffChatStyle.isStaffEntry(
      content: '',
      user: userRef,
    ) &&
        !VoiceRoomPermissions.forUser(
          user: user,
          room: _roomMeta,
          selfPresence: self,
          server: state.serverPermissions,
        ).isSiteAdmin &&
        !VoiceRoomPermissions.forUser(
          user: user,
          room: _roomMeta,
          selfPresence: self,
          server: state.serverPermissions,
        ).canModerate) {
      return;
    }
    final name = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : user.username;
    final symbol = self?.roleSymbol?.trim() ?? '';
    try {
      await ref.read(chatRoomRemoteProvider).postEntryAnnouncement(
            roomKey: _roomKey,
            alternateKey: _roomMeta.slug,
            userName: name,
            roleSymbol: symbol.isNotEmpty ? symbol : null,
            entryType: VoiceStaffChatStyle.entryRoleLabel(userRef),
          );
    } catch (_) {}
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
      await ref.read(chatRoomRemoteProvider).postPresence(_roomKey);
      final joined = await ref.read(chatRoomRemoteProvider).fetchPresence(_roomKey);
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
      _knownPresenceIds
        ..clear()
        ..addAll(merged.map((p) => p.id).where((id) => id.isNotEmpty));
      ref
          .read(voiceRoomDiagnosticProvider.notifier)
          .setPresence(joined: true, count: merged.length);
      _patchHubPresenceCount(merged.length);
      unawaited(_tryAutoPrivilegedSeat());
      unawaited(_broadcastStaffEntryIfNeeded());
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
    // selfInRoom=true means join was acknowledged by backend; even if the
    // _presenceJoined flag wasn't set yet (race during room switch), still
    // send DELETE to avoid the user appearing in the old room.
    if (!_presenceJoined && !state.selfInRoom) return;
    _presenceJoined = false;
    try {
      await ref.read(chatRoomRemoteProvider).leavePresence(_roomKey);
    } catch (_) {}
  }

  Future<void> joinVoiceSession() async {
    if (_roomKey.isEmpty || _voiceJoined) return;
    try {
      await ref.read(chatRoomRemoteProvider).joinVoiceSession(_roomKey);
      _voiceJoined = true;
      VoiceRoomDebugLog.log('api.voice.join.ok', {'room': _roomKey});
    } on Object catch (e) {
      VoiceRoomDebugLog.log('api.voice.join.fail', {'error': e.toString()});
    }
  }

  Future<void> leaveVoiceSession() async {
    await _leaveVoiceSession();
  }

  Future<void> _leaveVoiceSession() async {
    if (_roomKey.isEmpty || !_voiceJoined) return;
    _voiceJoined = false;
    try {
      await ref.read(chatRoomRemoteProvider).leaveVoiceSession(_roomKey);
      VoiceRoomDebugLog.log('api.voice.leave.ok', {'room': _roomKey});
    } catch (_) {}
  }

  /// Yazıyor göstergesi — POST /typing (SSE ile birlikte).
  void notifyTyping(bool active) {
    if (_roomKey.isEmpty) return;
    if (active) {
      _typingStopTimer?.cancel();
      if (!_typingActive) {
        _typingActive = true;
        unawaited(
          ref.read(chatRoomRemoteProvider).setTyping(_roomKey, isTyping: true),
        );
      }
      _typingStopTimer = Timer(const Duration(seconds: 2), () {
        unawaited(_stopTyping());
      });
    } else {
      unawaited(_stopTyping());
    }
  }

  Future<void> _stopTyping() async {
    _typingStopTimer?.cancel();
    if (!_typingActive || _roomKey.isEmpty) return;
    _typingActive = false;
    try {
      await ref.read(chatRoomRemoteProvider).setTyping(_roomKey, isTyping: false);
    } catch (_) {}
  }

  Future<void> _presenceHeartbeatTick() async {
    if (_roomKey.isEmpty) return;
    try {
      VoiceRoomDebugLog.log('api.presence.heartbeat', {'room': _roomKey});
      await ref.read(chatRoomRemoteProvider).presenceHeartbeat(_roomKey);
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
    final hub = ref.read(sseConnectionHubProvider);
    hub.attachVoiceRoom(_roomKey);
    final sse = hub.voiceRoom(_roomKey);
    VoiceRoomDebugLog.log('sse.subscribe', {
      'url': ChatRoomSseService.streamUrlFor(_roomKey),
      'roomId': _roomKey,
      'refs': hub.voiceRoomRefCount(_roomKey),
    });
    final giftsRemote = ref.read(liveGiftsRemoteProvider);
    sse
        .connect(
          roomId: _roomKey,
          accessToken: storage.readAccess,
          onConnected: () {
            if (!state.sseConnected) {
              state = state.copyWith(sseConnected: true);
            }
            ref.read(voiceRoomDiagnosticProvider.notifier).setSse(true);
            if (!VoiceRoomBasicMode.enabled ||
                VoiceRoomBasicMode.premiumEnabled) {
              ref.read(voiceRoomGiftRealtimeProvider).setSocketPreferred(false);
            }
            _notifyRealtimeIfBasic(
              VoiceRoomRealtimeKind.system,
              'Canlı bağlantı kuruldu',
            );
          },
          onDjUpdate: (payload) {
            if (payload.isNotEmpty) {
              if (VoiceRoomBasicMode.musicEnabled) {
                _applyRoomVideoPayload(payload);
              }
              unawaited(_applyDjRealtimePayload(payload));
            } else {
              unawaited(refresh(includeDj: true));
            }
          },
          onSong: (payload) {
            if (VoiceRoomBasicMode.musicEnabled) {
              _applyRoomVideoPayload(payload);
            }
            unawaited(_applyDjRealtimePayload(payload));
          },
          onGift: (payload) {
            if (!VoiceRoomBasicMode.premiumEnabled &&
                VoiceRoomBasicMode.enabled) {
              return;
            }
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
            if (msg.kind == ChatMessageKind.systemJoin) {
              _pushBasicChatEvent(msg);
              return;
            }
            if (VoiceRoomBasicMode.enabled && !VoiceRoomBasicMode.premiumEnabled) {
              return;
            }
            final exists = state.messages.any((m) => m.id == msg.id);
            if (exists) return;
            state = state.copyWith(messages: [...state.messages, msg]);
            _onMusicRelatedChatMessage(msg);
            _pushBasicChatEvent(msg);
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
            _detectMicChanges(merged);
            _syncPresenceJoinAnnouncements(merged);
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
            _patchHubPresenceCount(merged.length);
            if (!wasSse) _schedulePoll();
          },
          onUserJoin: _handleSseUserJoin,
          onUserLeave: _handleSseUserLeave,
          onTyping: (users) {
            state = state.copyWith(typingUsers: users);
          },
          onFortuneRequest: (payload) {
            if (VoiceRoomBasicMode.enabled) return;
            final session = parsePsychicSsePayload(payload);
            if (session == null) return;
            emitPsychicLiveRequest(ref, session);
          },
          onPk: (battle, event) {
            if (VoiceRoomBasicMode.enabled && !VoiceRoomBasicMode.premiumEnabled) {
              return;
            }
            // PK battle — artık ayrı bir Socket.IO bağlantısı yerine
            // odanın ana SSE akışından besleniyor.
            ref.read(pkBattleProvider.notifier).applyRemoteBattle(battle);
            ref.read(pkBattleRemoteProvider.notifier).ingestSseBattle(battle);
            VoiceRoomDebugLog.log('sse.pk', {
              'roomId': _roomKey,
              'battleId': battle.id,
              'event': event,
              'status': battle.status,
            });
          },
          onSystem: _handleSseSystemEvent,
          onAnnouncement: _handleSseAnnouncement,
          onModeration: _handleSseModeration,
          onRoomUpdate: _handleSseRoomUpdate,
        );
  }

  void _handleSseAnnouncement(Map<String, dynamic> payload) {
    final text = payload['message']?.toString().trim() ??
        payload['content']?.toString().trim() ??
        payload['text']?.toString().trim();
    if (text == null || text.isEmpty) return;
    _notifyRealtimeIfBasic(VoiceRoomRealtimeKind.system, text);
    _showModeratorAnnouncement(text);
  }

  void _handleSseModeration(Map<String, dynamic> payload) {
    final event = payload['event']?.toString().toUpperCase().trim() ?? '';
    switch (event) {
      case 'CHAT_CLEARED':
      case 'MESSAGES_CLEARED':
        _applyLocalChatClear();
        _notifyRealtimeIfBasic(
          VoiceRoomRealtimeKind.moderation,
          'Sohbet temizlendi',
        );
        return;
      case 'ROOM_MUTED':
        state = state.copyWith(roomMuted: true);
        _notifyRealtimeIfBasic(
          VoiceRoomRealtimeKind.mute,
          payload['message']?.toString().trim() ?? 'Oda susturuldu',
        );
        return;
      case 'ROOM_UNMUTED':
        state = state.copyWith(roomMuted: false);
        _notifyRealtimeIfBasic(
          VoiceRoomRealtimeKind.unmute,
          payload['message']?.toString().trim() ?? 'Oda susturması kaldırıldı',
        );
        return;
      case 'USER_MUTED':
        _notifyRealtimeIfBasic(
          VoiceRoomRealtimeKind.mute,
          payload['message']?.toString().trim() ??
              '${payload['userName'] ?? 'Kullanıcı'} susturuldu',
        );
        return;
      case 'USER_UNMUTED':
        _notifyRealtimeIfBasic(
          VoiceRoomRealtimeKind.unmute,
          payload['message']?.toString().trim() ??
              '${payload['userName'] ?? 'Kullanıcı'} susturması kaldırıldı',
        );
        return;
      case 'USER_KICKED':
        _notifyRealtimeIfBasic(
          VoiceRoomRealtimeKind.moderation,
          payload['message']?.toString().trim() ??
              '${payload['userName'] ?? 'Kullanıcı'} odadan atıldı',
        );
        return;
      case 'USER_BANNED':
        _notifyRealtimeIfBasic(
          VoiceRoomRealtimeKind.moderation,
          payload['message']?.toString().trim() ??
              '${payload['userName'] ?? 'Kullanıcı'} yasaklandı',
        );
        return;
      case 'ANNOUNCEMENT':
        _handleSseAnnouncement(payload);
        return;
      default:
        final msg = payload['message']?.toString().trim();
        if (msg != null && msg.isNotEmpty) {
          _notifyRealtimeIfBasic(VoiceRoomRealtimeKind.moderation, msg);
          if (VoiceRoomBasicMode.enabled) showModerationToast(msg);
        }
        return;
    }
  }

  void _handleSseSystemEvent(Map<String, dynamic> payload) {
    final event = payload['event']?.toString().toUpperCase().trim() ?? '';
    switch (event) {
      case 'ANNOUNCEMENT':
        _handleSseAnnouncement(payload);
        return;
      case 'CHAT_CLEARED':
      case 'MESSAGES_CLEARED':
        _applyLocalChatClear();
        return;
      case 'ROLE_CHANGED':
      case 'ROLE_REMOVED': {
        final name = payload['userName']?.toString() ?? 'Kullanıcı';
        final newRole = payload['newRole']?.toString();
        final removed = payload['removedRole']?.toString();
        if (event == 'ROLE_CHANGED' && newRole != null) {
          final line = '$name → $newRole rolü verildi';
          showModerationToast(line);
          _notifyRealtimeIfBasic(VoiceRoomRealtimeKind.moderation, line);
        } else if (removed != null) {
          final line = '$name → $removed rolü alındı';
          showModerationToast(line);
          _notifyRealtimeIfBasic(VoiceRoomRealtimeKind.moderation, line);
        }
        unawaited(_presenceHeartbeatTick());
        return;
      }
      case 'ENTRY_ANNOUNCEMENT': {
        final name = payload['userName']?.toString() ?? 'Kullanıcı';
        final entry = payload['entryType']?.toString() ?? '';
        final userRef = ChatRoomUserRef(
          id: payload['userId']?.toString() ?? '',
          name: name,
          nickname: payload['userNickname']?.toString(),
          chatRole: entry.isNotEmpty ? entry.toLowerCase() : null,
        );
        _showStaffEnterBanner(name, user: userRef);
        return;
      }
      case 'ROOM_MUTED':
        state = state.copyWith(roomMuted: true);
        _notifyRealtimeIfBasic(
          VoiceRoomRealtimeKind.mute,
          payload['message']?.toString().trim() ?? 'Oda susturuldu',
        );
        return;
      case 'ROOM_UNMUTED':
        state = state.copyWith(roomMuted: false);
        _notifyRealtimeIfBasic(
          VoiceRoomRealtimeKind.unmute,
          payload['message']?.toString().trim() ?? 'Oda susturması kaldırıldı',
        );
        return;
      case 'USER_KICKED':
      case 'USER_BANNED':
        final targetId = payload['targetUserId']?.toString() ??
            payload['userId']?.toString();
        final selfId = ref.read(authControllerProvider).valueOrNull?.id;
        if (event == 'USER_KICKED' &&
            targetId != null &&
            selfId != null &&
            targetId == selfId) {
          final count = payload['kickCount'] is int
              ? payload['kickCount'] as int
              : int.tryParse(payload['kickCount']?.toString() ?? '') ?? 1;
          _showKickStrikeWarning(
            count,
            autoBanned: count >= 3,
          );
        }
        if (event == 'USER_BANNED' &&
            targetId != null &&
            selfId != null &&
            targetId == selfId) {
          _notifyRealtimeIfBasic(
            VoiceRoomRealtimeKind.moderation,
            'Odadan yasaklandınız',
          );
        }
        final modMsg = payload['message']?.toString().trim();
        if (modMsg != null && modMsg.isNotEmpty) {
          if (VoiceRoomBasicMode.enabled) {
            _pushRealtimeEvent(VoiceRoomRealtimeKind.moderation, modMsg);
            showModerationToast(modMsg);
          } else {
            _showMusicRequestFlashLine(modMsg);
          }
        }
        return;
      case 'USER_MUTED':
      case 'USER_UNMUTED':
        final muteMsg = payload['message']?.toString().trim();
        if (muteMsg != null && muteMsg.isNotEmpty) {
          _pushRealtimeEvent(
            event == 'USER_MUTED'
                ? VoiceRoomRealtimeKind.mute
                : VoiceRoomRealtimeKind.unmute,
            muteMsg,
          );
          if (VoiceRoomBasicMode.enabled) {
            showModerationToast(muteMsg);
          } else {
            _showMusicRequestFlashLine(muteMsg);
          }
        }
        return;
      default:
        return;
    }
  }

  void _handleSseUserJoin(Map<String, dynamic> payload) {
    final users = _presenceFromSsePayload(payload);
    if (users.isEmpty) return;
    final byId = {for (final p in state.presence) p.id: p};
    for (final user in users) {
      byId[user.id] = user;
    }
    final merged = _mergePresenceStable(
      byId.values.toList(),
      source: 'sse_user_join',
    );
    _detectMicChanges(merged);
    _syncPresenceJoinAnnouncements(merged);
    state = state.copyWith(
      presence: merged,
      sseConnected: true,
      selfInRoom: true,
    );
    ref
        .read(voiceRoomDiagnosticProvider.notifier)
        .setPresence(joined: true, count: merged.length);
  }

  void _handleSseUserLeave(Map<String, dynamic> payload) {
    final userId = payload['userId']?.toString() ?? payload['id']?.toString();
    if (userId == null || userId.isEmpty) return;
    ChatRoomPresence? departed;
    for (final p in state.presence) {
      if (p.id == userId) {
        departed = p;
        break;
      }
    }
    final name = departed?.displayName.trim().isNotEmpty == true
        ? departed!.displayName.trim()
        : (payload['userName']?.toString().trim().isNotEmpty == true
            ? payload['userName'].toString().trim()
            : 'Bir kullanıcı');
    _notifyRealtimeIfBasic(
      VoiceRoomRealtimeKind.leave,
      '$name odadan ayrıldı',
    );
    final remaining = state.presence.where((p) => p.id != userId).toList();
    if (remaining.length == state.presence.length) return;
    state = state.copyWith(presence: remaining);
    _patchHubPresenceCount(remaining.length);
    ref
        .read(voiceRoomDiagnosticProvider.notifier)
        .setPresence(joined: true, count: remaining.length);
    VoiceRoomDebugLog.log('sse.user_left', {'userId': userId});
  }

  List<ChatRoomPresence> _presenceFromSsePayload(Map<String, dynamic> payload) {
    dynamic raw = payload['users'] ?? payload['presence'] ?? payload['members'];
    if (raw == null && payload['user'] is Map) {
      raw = [payload['user']];
    }
    if (raw == null) {
      final userId = payload['userId']?.toString() ?? payload['id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        raw = [payload];
      }
    }
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => ChatRoomPresence.fromJson(Map<String, dynamic>.from(e)))
        .where((u) => u.id.isNotEmpty)
        .toList();
  }

  void _showModeratorAnnouncement(String text) {
    final key = text.trim().toLowerCase();
    if (key.isEmpty) return;
    final now = DateTime.now();
    if (_lastDuyuruText == key &&
        _lastDuyuruShownAt != null &&
        now.difference(_lastDuyuruShownAt!) < const Duration(seconds: 3)) {
      return;
    }
    _lastDuyuruText = key;
    _lastDuyuruShownAt = now;
    _announcementTimer?.cancel();
    _pinnedAnnouncementTimer?.cancel();
    state = state.copyWith(
      moderatorAnnouncement: text.trim(),
      clearPinnedAnnouncement: true,
    );
  }

  void clearModeratorAnnouncement() {
    _announcementTimer?.cancel();
    state = state.copyWith(clearModeratorAnnouncement: true);
  }

  void showModerationToast(String text) {
    _moderationToastTimer?.cancel();
    state = state.copyWith(moderationToast: text);
    _moderationToastTimer = Timer(const Duration(seconds: 5), () {
      if (!_sessionActive) return;
      state = state.copyWith(clearModerationToast: true);
    });
  }

  void _showKickStrikeWarning(int strikeCount, {bool autoBanned = false}) {
    _kickWarningTimer?.cancel();
    state = state.copyWith(
      kickStrikeWarning: KickStrikeUi.messageFor(
        strikeCount,
        autoBanned: autoBanned,
      ),
      kickStrikeCount: strikeCount.clamp(1, 3),
    );
    _kickWarningTimer = Timer(const Duration(seconds: 12), () {
      if (!_sessionActive) return;
      state = state.copyWith(clearKickStrikeWarning: true);
    });
  }

  void _triggerChatClearedBanner() {
    state = state.copyWith(
      chatClearedBannerNonce: state.chatClearedBannerNonce + 1,
    );
  }

  void _startGiftSocket() {
    if (_roomKey.isEmpty) return;
    if (_giftSocketStarted) {
      VoiceRoomDebugLog.log('socket.subscribe.skip', {'roomId': _roomKey});
      return;
    }
    _giftSocketStarted = true;
    final storage = ref.read(tokenStorageProvider);
    final alt = _roomMeta.slug.trim();
    ref.read(voiceRoomGiftSocketProvider).connect(
          roomId: _roomKey,
          alternateRoomId: alt.isNotEmpty ? alt : null,
          accessToken: storage.readAccess,
          onEvent: (ev) {
            ref.read(voiceRoomGiftRealtimeProvider).publishRemote(ev);
            if (!state.sseConnected) {
              ref.read(voiceRoomGiftRealtimeProvider).setSocketPreferred(true);
            }
          },
          onPresenceSnapshot: applyPresenceSnapshot,
          onDjUpdate: (payload) {
            // SSE bağlıyken DJ olayları yalnızca SSE'den işlenir (çift oynatma önlenir).
            if (state.sseConnected || payload.isEmpty) return;
            _applyRoomVideoPayload(payload);
            unawaited(_applyDjRealtimePayload(payload));
          },
          onMessage: (msg) {
            if (state.sseConnected) return;
            final exists = state.messages.any((m) => m.id == msg.id);
            if (exists) return;
            state = state.copyWith(messages: [...state.messages, msg]);
          },
          onConnectionChanged: (connected) {
            ref.read(voiceRoomDiagnosticProvider.notifier).setSocket(connected);
            if (connected && !state.sseConnected) {
              ref.read(voiceRoomGiftRealtimeProvider).setSocketPreferred(true);
            }
          },
        );
    VoiceRoomDebugLog.log('socket.subscribe', {'roomId': _roomKey});
  }

  /// Sunucu presence snapshot diff — koltuk / konuşma / rol (`roomUsers` vb.).
  void applyPresenceSnapshot(
    List<ChatPresenceRow> previous,
    List<ChatPresenceRow> current,
  ) {
    final prevById = {for (final p in previous) p.id: p};
    for (final row in current) {
      final prev = prevById[row.id];
      if (prev == null) continue;
      if (prev.seatIndex != row.seatIndex ||
          prev.isSpeaking != row.isSpeaking ||
          prev.chatRole != row.chatRole) {
        VoiceRoomDebugLog.seatUpdate(
          roomId: _roomKey,
          seatCount: current.where((p) => p.seatIndex != null).length,
          source: 'socket_snapshot',
        );
      }
    }
    for (final prev in previous) {
      if (!current.any((p) => p.id == prev.id)) {
        VoiceRoomDebugLog.log('socket.presence.left', {'userId': prev.id});
      }
    }
    final merged = _mergePresenceStable(current, source: 'socket_snapshot');
    state = state.copyWith(
      presence: merged,
      selfInRoom: true,
    );
    ref
        .read(voiceRoomDiagnosticProvider.notifier)
        .setPresence(joined: true, count: merged.length);
  }

  void _schedulePoll({bool? sseConnected, bool? musicActive}) {
    _poll?.cancel();
    _pollTick = 0;
    final sse = sseConnected ?? state.sseConnected;
    final active = musicActive ??
        (state.dj.playing || state.dj.nowPlaying != null);
    final interval = sse ? (active ? 30 : 60) : 12;
    _poll = Timer.periodic(Duration(seconds: interval), (_) {
      if (_pollPaused) return;
      _pollTick++;
      final djActive = state.dj.playing || state.dj.nowPlaying != null;
      final fullDj = !sse || (djActive && (_pollTick % 3 == 0));
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
        '${effective.nowPlaying?.isVideoRequest == true}|'
        '${effective.musicEnabled}|$muted|'
        '${effective.musicUrl?.trim() ?? ''}';
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
          final needMusicState =
              state.dj.playing || state.dj.nowPlaying != null;
          final djFutures = <Future<Object?>>[
            remote.fetchDj(_roomKey, alternateKey: _musicAlternateKey),
            remote.fetchMusicQueue(
              _roomKey,
              alternateKey: _musicAlternateKey,
            ),
            if (needMusicState)
              remote.fetchMusicState(
                _roomKey,
                alternateKey: _musicAlternateKey,
              ),
          ];
          final djResults = await NetworkPerf.parallel(
            djFutures.map(
              (future) => future.catchError((Object e) {
                refreshError ??= e;
                return null;
              }),
            ),
          );
          final djBase = djResults[0] as ChatRoomDjState?;
          final mq = djResults.length > 1
              ? djResults[1]
              : null;
          if (djBase != null && mq != null) {
            dj = _mergeMusicQueueRecord(
              djBase,
              mq as ({
                List<MusicQueueItem> queue,
                int cost,
                int videoRequestCost,
                int maxMusicQueue,
                bool musicEnabled,
                MusicQueueItem? nowPlaying,
                bool? playing,
                bool? canRequestMusic,
                String? musicUrl,
              }),
            );
          } else if (djBase != null) {
            dj = djBase;
          }
          if (needMusicState && djResults.length > 2) {
            final musicState = djResults[2];
            if (musicState != null) {
              final ms = musicState as ({
                List<MusicQueueItem> queue,
                MusicQueueItem? nowPlaying,
                bool? playing,
                String? musicUrl,
              });
              dj = dj.copyWith(
                musicQueue: ms.queue.isNotEmpty ? ms.queue : dj.musicQueue,
                nowPlaying: ms.nowPlaying ?? dj.nowPlaying,
                playing: ms.playing ?? dj.playing,
                musicUrl: ms.musicUrl ?? dj.musicUrl,
              );
            }
          }
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
      final messages =
          _filterClearedMessages(_mergeMessages(previousMessages, fetchedMsgs));
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
        // Öncelik: DJ arka planı > TAZE oda arka planı (sunucudan) > önceki
        // state. Not: eskiden yapışkan state, taze oda değerini kalıcı
        // gölgeliyordu; arkaplan değişimi ancak yeniden girişte görünüyordu.
        backgroundUrl: (bgFromDj != null && bgFromDj.isNotEmpty)
            ? bgFromDj
            : (room.backgroundImageUrl?.trim().isNotEmpty == true)
            ? room.backgroundImageUrl
            : state.backgroundUrl,
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
      final videoCtrl = ref.read(roomVideoControllerProvider(_roomKey).notifier);
      if (ref.read(roomVideoControllerProvider(_roomKey)).hasActiveVideo) {
        await videoCtrl.dismissAnimated();
      }
      await ref
          .read(chatRoomRemoteProvider)
          .completeMusicQueue(_roomKey, alternateKey: _musicAlternateKey);
      await refresh(includeDj: true);
      var dj = state.dj;
      final hasQueue = dj.musicQueue.isNotEmpty;
      final hasNowPlaying = dj.nowPlaying != null;
      if (!hasQueue && !hasNowPlaying) {
        ref.read(roomVideoControllerProvider(_roomKey).notifier).clear();
        await ref.read(voiceRoomDjPlayerProvider).stop();
        ref.read(voiceRoomMusicSessionProvider.notifier).dismissFromServerStop();
        _lastDjPlaybackSignature = _djPlaybackSignature(
          dj,
          muted: !ref.read(voiceRoomUiProvider).backgroundMusicEnabled,
        );
        return;
      }
      if (hasNowPlaying && dj.playing) {
        ref.read(voiceRoomMusicSessionProvider.notifier).onMusicStartedFromServer();
        _lastDjPlaybackSignature = '';
        await _playDjInBackground(dj);
        return;
      }
      if (hasQueue) {
        await _syncMusicFromServer(optimisticUi: false);
        dj = state.dj;
        if (dj.nowPlaying != null) {
          ref.read(voiceRoomMusicSessionProvider.notifier).onMusicStartedFromServer();
          _lastDjPlaybackSignature = '';
          await _playDjInBackground(dj);
        }
      }
    } catch (e) {
      VoiceRoomDebugLog.log('music.track_complete.fail', {'error': '$e'});
    }
  }

  /// YouTube video modu — parça bittiğinde kuyruğu ilerlet.
  Future<void> notifyVideoTrackEnded() => _onDjTrackComplete();

  Future<void> _warmBackgrounds() async {
    try {
      final roomBg = _roomMeta.backgroundImageUrl?.trim();
      final current = state.backgroundUrl?.trim();
      final pick = (current != null && current.isNotEmpty)
          ? current
          : (roomBg != null && roomBg.isNotEmpty)
          ? roomBg
          : null;
      if (pick != null) {
        state = state.copyWith(backgroundUrl: pick);
      }
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
      int videoRequestCost,
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
    final effectiveQueue = mq.queue.isNotEmpty ||
            !((mq.playing ?? dj.playing) || dj.musicQueue.isNotEmpty)
        ? mq.queue
        : dj.musicQueue;
    final merged = dj.mergeMusicQueue(
      queue: effectiveQueue,
      nowPlaying: mq.nowPlaying,
      playing: mq.playing,
      musicRequestCost: mq.cost,
      videoRequestCost: mq.videoRequestCost,
      maxMusicQueue: mq.maxMusicQueue,
      musicEnabled: mq.musicEnabled,
      canRequestMusic: mq.canRequestMusic,
      musicUrl: mq.musicUrl,
      overwriteNowPlaying: mq.nowPlaying != null,
    );
    final stabilized = _preserveLocalMusicPlayback(merged, previous: dj);
    VoiceRoomMusicPipelineLog.compareDjState(
      stage: 'mergeMusicQueue',
      roomId: _roomKey,
      endpoint: '/api/chat/rooms/$_roomKey/music-queue',
      dj: stabilized,
      shouldPlay: stabilized.playing && stabilized.playbackSource != null,
    );
    _prefetchYoutubePlayback(stabilized);
    return stabilized;
  }

  /// Poll/SSE geçici `playing:false` döndüğünde yerel iframe çalmayı korur.
  ChatRoomDjState _preserveLocalMusicPlayback(
    ChatRoomDjState merged, {
    required ChatRoomDjState previous,
  }) {
    if (merged.playing) return merged;
    if (previous.nowPlaying == null) return merged;
    final sameTrack = merged.nowPlaying?.id == previous.nowPlaying?.id ||
        (merged.nowPlaying?.youtubeUrl.isNotEmpty == true &&
            merged.nowPlaying?.youtubeUrl == previous.nowPlaying?.youtubeUrl);
    if (!sameTrack) return merged;
    final video = ref.read(roomVideoControllerProvider(_roomKey));
    if (!video.hasActiveVideo) return merged;
    if (previous.playing || video.isPlaying) {
      return merged.copyWith(playing: true);
    }
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
      canStopMusic: _canStopMusic(),
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
            if (_canStopMusic()) {
              await stopMusic();
            } else {
              ref
                  .read(voiceRoomMusicSessionProvider.notifier)
                  .markUserDismissed();
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

  /// SSE `dj` — VoiceRoomDjPlayer (just_audio) üzerinden tek oynatıcı.
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

  Future<String?> submitSelectedSong(
    YoutubeSearchHit hit, {
    bool withVideo = false,
    bool skipPayment = false,
  }) async {
    state = state.copyWith(sending: true, clearPendingMusicSearch: true);
    try {
      if (!skipPayment) {
        final balances = ref.read(walletBalancesProvider).valueOrNull;
        final jeton = VoiceMusicAccess.jetonFromBalances(balances);
        if (!VoiceMusicAccess.canAffordRequest(
          dj: state.dj,
          jetonBalance: jeton,
          withVideo: withVideo,
        )) {
          final cost = withVideo
              ? VoiceMusicAccess.videoRequestCost(state.dj)
              : VoiceMusicAccess.audioRequestCost(state.dj);
          state = state.copyWith(sending: false);
          return 'Yetersiz jeton. Gerekli: $cost';
        }
      }
      if (withVideo) {
        final videoState = ref.read(roomVideoControllerProvider(_roomKey));
        if (videoState.hasActiveVideo) {
          await ref
              .read(roomVideoControllerProvider(_roomKey).notifier)
              .dismissAnimated();
        }
        ref.read(voiceRoomMusicSessionProvider.notifier).onMusicStartedFromServer();
      }
      final result = await ref.read(enqueueSongUseCaseProvider)(
            roomId: _roomKey,
            alternateRoomId: _musicAlternateKey,
            videoId: hit.videoId,
            title: hit.title,
            channelTitle: hit.uploader,
            thumbUrl: hit.thumbUrl,
            duration: hit.duration,
            skipPayment: skipPayment,
            withVideo: withVideo,
          );
      if (result.newBalance != null) {
        invalidateWalletCacheFromRef(ref);
      }
      var queue = result.queue;
      var nowPlaying = result.item ?? (queue.isNotEmpty ? queue.first : null);
      if (withVideo && nowPlaying != null) {
        nowPlaying = nowPlaying.asVideoRequest();
        queue = queue
            .map((e) => e.id == nowPlaying!.id ? nowPlaying : e)
            .toList();
      }
      final queuePosition = result.queuePosition ?? 0;
      final player = ref.read(voiceRoomDjPlayerProvider);
      final currentlyPlaying = state.dj.playing ||
          player.playback.value.playing ||
          state.dj.nowPlaying != null;
      final isQueuedOnly = currentlyPlaying;
      final shouldPlay = !currentlyPlaying &&
          (result.playing || queuePosition <= 1);
      var dj = isQueuedOnly
          ? state.dj.copyWith(musicQueue: queue)
          : state.dj.copyWith(
              musicQueue: queue,
              nowPlaying: nowPlaying,
              playing: shouldPlay,
              musicUrl: result.streamUrl ?? nowPlaying?.youtubeUrl,
            );
      if (!isQueuedOnly) {
        dj = _djWithQueuePlaybackFallback(dj);
      }
      _lastDjPlaybackSignature = '';
      state = state.copyWith(dj: dj, sending: false);
      if (shouldPlay && !isQueuedOnly) {
        await _playDjInBackground(dj);
      }
      unawaited(_syncMusicFromServerIfNeeded(force: true));
      _showMusicRequestFlashLine('✅ «${hit.title}» kuyruğa eklendi');
      return null;
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

  /// SSE nowPlaying bazen withVideo düşürür — istemci video modunu korur.
  MusicQueueItem _mergeNowPlayingFromSse(
    Map<String, dynamic> json, {
    MusicQueueItem? previous,
  }) {
    final incoming = MusicQueueItem.fromJson(json);
    if (incoming.isVideoRequest) return incoming;
    if (previous == null || !previous.isVideoRequest) return incoming;
    final sameTrack = incoming.id == previous.id ||
        (incoming.youtubeUrl.isNotEmpty &&
            incoming.youtubeUrl == previous.youtubeUrl);
    if (!sameTrack) return incoming;
    return incoming.asVideoRequest();
  }

  Future<void> _handleMusicStoppedFromSse() async {
    VoiceRoomDebugLog.log('music.sse.stopped', {'room': _roomKey});
    await ref.read(voiceRoomDjPlayerProvider).stop();
    ref.read(voiceRoomMusicSessionProvider.notifier).dismissFromServerStop();
    ref.read(roomVideoControllerProvider(_roomKey).notifier).clear();
    state = state.copyWith(
      dj: state.dj.copyWith(
        playing: false,
        clearNowPlaying: true,
        clearMusicUrl: true,
        musicQueue: const [],
      ),
      musicLikeCount: 0,
    );
    _lastDjPlaybackSignature = '';
  }

  Future<void> _applyDjRealtimePayload(Map<String, dynamic> payload) async {
    final map = unwrapVoiceSseDjPayload(payload);
    final signal = voiceSseMusicSignal(map);
    if (signal == VoiceSseMusicSignal.stopped) {
      await _handleMusicStoppedFromSse();
      return;
    }
    if (signal == VoiceSseMusicSignal.started) {
      ref.read(voiceRoomMusicSessionProvider.notifier).onMusicStartedFromServer();
      ref.read(voiceRoomMusicSessionProvider.notifier).clearUserDismissed();
      VoiceRoomDebugLog.log('music.sse.started', {
        'room': _roomKey,
        'musicUrl': map['musicUrl']?.toString(),
      });
    }
    final likes = voiceSseLikeCount(map);
    final np = map['nowPlaying'];
    String? title;
    String? eventVideoId;
    if (np is Map) {
      title = np['title']?.toString();
      eventVideoId = np['videoId']?.toString() ?? np['youtubeUrl']?.toString();
    }
    eventVideoId ??= map['currentVideoId']?.toString() ?? map['videoId']?.toString();
    VoiceRoomDebugLog.djUpdate(
      roomId: _roomKey,
      playing: voiceSseDjIsPlaying(map),
      musicUrl: map['musicUrl']?.toString(),
      videoId: eventVideoId,
      title: title,
      source: map['type']?.toString() ?? 'realtime',
    );
    VoiceRoomDebugLog.log('music.realtime.recv', {
      'playing': map['playing'],
      'isPlaying': map['isPlaying'],
      'hasUrl': map['musicUrl'] != null,
      'hasQueue': map['queue'] != null,
      'type': map['type'],
    });
    var dj = state.dj;
    final isPlaying = voiceSseDjIsPlaying(map);
    if (map.containsKey('playing') ||
        map.containsKey('isPlaying') ||
        isPlaying) {
      dj = dj.copyWith(playing: isPlaying);
    }
    if (map['musicUrl'] != null) {
      final url = map['musicUrl'].toString().trim();
      if (url.isNotEmpty) dj = dj.copyWith(musicUrl: url);
    }
    if (map['nowPlaying'] is Map) {
      dj = dj.copyWith(
        nowPlaying: _mergeNowPlayingFromSse(
          Map<String, dynamic>.from(map['nowPlaying'] as Map),
          previous: state.dj.nowPlaying,
        ),
        playing: isPlaying || dj.playing,
      );
    } else if (isPlaying && dj.nowPlaying == null) {
      final queueRaw = map['queue'] ?? map['musicQueue'];
      if (queueRaw is List && queueRaw.isNotEmpty && queueRaw.first is Map) {
        dj = dj.copyWith(
          nowPlaying: MusicQueueItem.fromJson(
            Map<String, dynamic>.from(queueRaw.first as Map),
          ),
          playing: true,
        );
      }
    }
    final queueRaw = map['queue'] ?? map['musicQueue'];
    if (queueRaw is List) {
      final queue = queueRaw
          .whereType<Map>()
          .map((e) => MusicQueueItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final player = ref.read(voiceRoomDjPlayerProvider);
      final musicActive =
          dj.playing || state.dj.playing || player.playback.value.playing;
      if (queue.isNotEmpty || !musicActive) {
        dj = dj.copyWith(musicQueue: queue);
      } else if (state.dj.musicQueue.isNotEmpty) {
        dj = dj.copyWith(musicQueue: state.dj.musicQueue);
      }
    }
    if (map['djUserIds'] is List) {
      final ids = (map['djUserIds'] as List)
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
    } else if (map['djUsers'] is List) {
      final users = (map['djUsers'] as List)
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
    } else if (state.dj.djUsers.isNotEmpty) {
      dj = dj.copyWith(djUsers: state.dj.djUsers);
    }
    _commitDjUi(dj);
    if (likes != null) {
      state = state.copyWith(musicLikeCount: likes);
    }
    final sync = RoomPlaybackSync.fromPayload(map);
    _syncRoomVideo(dj, sync: sync);
    final ui = ref.read(voiceRoomUiProvider);
    final sig = _djPlaybackSignature(dj, muted: !ui.backgroundMusicEnabled);
    final player = ref.read(voiceRoomDjPlayerProvider);
    final wantsPlay = (dj.playing || sync.isPlaying) &&
        _hasDjPlayableSource(
          dj,
          sync: sync,
          videoId: eventVideoId,
        );
    final playerIdle = !player.playback.value.playing;
    if (sig != _lastDjPlaybackSignature || (wantsPlay && playerIdle)) {
      unawaited(_playDjInBackground(dj, sync: sync));
      return;
    }
    if (!wantsPlay && (map['queue'] != null || map['musicQueue'] != null)) {
      unawaited(_syncMusicFromServerIfNeeded(force: true));
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
    if (!_hasDjPlayableSource(dj)) return dj;
    return dj.copyWith(playing: true);
  }

  Future<ChatRoomDjState> _applyDjPlayback(
    ChatRoomDjState dj, {
    RoomPlaybackSync? sync,
  }) async {
    final ui = ref.read(voiceRoomUiProvider);
    final muted = !ui.backgroundMusicEnabled;
    final session = ref.read(voiceRoomMusicSessionProvider);
    final player = ref.read(voiceRoomDjPlayerProvider);

    if (session.userDismissedPlayer) {
      await player.stop();
      _syncRoomVideo(const ChatRoomDjState(), sync: sync);
      _lastDjPlaybackSignature = _djPlaybackSignature(dj, muted: muted);
      return dj;
    }

    if (!dj.musicEnabled) {
      await player.stop();
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
        _hasDjPlayableSource(effectiveDj, sync: sync, videoId: videoId);
    final startPos = Duration(
      milliseconds: VoicePlaybackLimits.clampPositionMs(
        sync?.resolvedPositionMs() ?? 0,
      ),
    );
    final sig = _djPlaybackSignature(effectiveDj, muted: muted);
    final sameTrack = sig == _lastDjPlaybackSignature;

    // YouTube kaynağı → in-app IFrame embed (ses/video). Sunucu yt-dlp
    // çözümlemesi gerekmez (Node-only ortam, 429 riski yok). Video isteğinde
    // görünür şerit, aksi halde ses-only gizli iframe (RoomVideoState.audioOnly).
    final hasYoutube = videoId != null && videoId.isNotEmpty;

    if (shouldPlay) {
      await VoiceRoomMusicAudioSession.activateForPlayback();

      if (hasYoutube) {
        // just_audio'yu durdur; müzik iframe embed üzerinden çalar.
        await player.stop();
        _syncRoomVideo(effectiveDj, sync: sync);
        _lastDjPlaybackSignature = sig;
        return effectiveDj;
      }

      // YouTube olmayan direkt ses akışı → just_audio.
      ref.read(roomVideoControllerProvider(_roomKey).notifier).clear();
      if (!sameTrack) {
        await player.stop();
      }
      final resolvedStream = await _resolveDjStreamUrl(effectiveDj, sync: sync);
      var serverUrl = sync?.streamUrl ?? effectiveDj.musicUrl;
      if (serverUrl != null &&
          YoutubeStreamResolver.isYoutubeStreamApiUrl(serverUrl)) {
        serverUrl = resolvedStream;
      }
      await player.sync(
        musicUrl: resolvedStream ?? effectiveDj.musicUrl,
        resolveSeed: effectiveDj.playbackResolveSeed,
        fallbackYoutubeUrl: effectiveDj.youtubeFallbackSource,
        nowPlaying: effectiveDj.nowPlaying,
        playing: true,
        muted: muted,
        serverStreamUrl: resolvedStream ?? serverUrl,
        preResolvedStream: resolvedStream,
        startPosition: sameTrack ? startPos : startPos,
      );
      _lastDjPlaybackSignature = sig;
      if (!player.playback.value.playing &&
          player.diagnostics.value.lastPhase == 'sync_verify_failed') {
        unawaited(_handleUnplayableEmbed());
      }
      return effectiveDj;
    }

    final roomVideo = ref.read(roomVideoControllerProvider(_roomKey));
    if (hasYoutube &&
        roomVideo.hasActiveVideo &&
        roomVideo.isPlaying &&
        videoId != null &&
        roomVideo.videoId == videoId &&
        effectiveDj.nowPlaying != null) {
      _lastDjPlaybackSignature = sig;
      return effectiveDj.copyWith(playing: true);
    }

    await player.stop();
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
              int videoRequestCost,
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
      invalidateWalletCacheFromRef(ref);
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
              withVideo: true,
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

      invalidateWalletCacheFromRef(ref);

      var queue = result.queue;
      var nowPlaying =
          result.item ?? (queue.isNotEmpty ? queue.first : null);
      if (user != null && nowPlaying != null) {
        nowPlaying = _musicItemWithRequester(nowPlaying, user);
        queue = queue
            .map((e) => e.id == nowPlaying!.id ? nowPlaying : e)
            .toList();
      }
      if (skipPayment && nowPlaying != null) {
        nowPlaying = nowPlaying.asVideoRequest();
        queue = queue
            .map((e) => e.id == nowPlaying!.id ? nowPlaying : e)
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
      _lastDjPlaybackSignature = '';
      state = state.copyWith(dj: dj);
      if (shouldPlay) {
        await _playDjInBackground(dj);
      }
      unawaited(_syncMusicFromServerIfNeeded(force: true));
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
      if (VoiceStaffChatStyle.isStaffEntry(
        content: m.content,
        user: m.user,
      )) {
        continue;
      }
      _pushRealtimeEvent(VoiceRoomRealtimeKind.join, m.content.trim());
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
    _enterBannerTimer = Timer(const Duration(seconds: 10), () {
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

  int? _privilegedRolePriority(
    UserEntity user,
    ChatRoomMyPermissions? server,
    ChatRoomPresence? self,
  ) {
    final tier = VoiceRoomSeatPriority.forUser(
      user,
      room: _roomMeta,
      self: self,
      server: server,
    );
    if (!VoiceRoomSeatPriority.shouldAutoSit(tier)) return null;
    return tier;
  }

  int? _pickAutoSeatIndex({
    required int myPriority,
    required List<ChatRoomPresence> presence,
  }) {
    return VoiceRoomSeatPriority.pickAutoSeatIndex(
      myTier: myPriority,
      presence: presence,
      room: _roomMeta,
    );
  }

  Future<void> _tryAutoPrivilegedSeat() async {
    if (_roomKey.isEmpty || !state.selfInRoom) return;
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
    if (_autoSeatAttempted) return;

    final seatIndex = _pickAutoSeatIndex(
      myPriority: priority,
      presence: state.presence,
    );
    if (seatIndex == null) return;

    VoiceRoomDebugLog.log('seat.auto_join', {
      'room': _roomKey,
      'seat': seatIndex,
      'priority': priority,
    });
    // Manuel "Koltuğa Al" ile AYNI çalışan yolu kullan (voiceSeatRestService
    // .takeSeat). Eski joinSeat ucu 200 dönüp koltuğa oturtmuyordu; bu yüzden
    // yetkili otomatik koltuğa geçmiyordu.
    final err = await assignSeat(seatIndex: seatIndex, userId: user.id);
    if (err == null) {
      _autoSeatAttempted = true;
      return;
    }
    for (final p in state.presence) {
      if (p.id == user.id && p.seatIndex != null) {
        _autoSeatAttempted = true;
        break;
      }
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
    // Mevcut en yeni mesaj zamanını işaret al — sunucu poll'de aynı geçmişi
    // döndürse bile bu işaretten eski mesajlar bir daha eklenmez.
    DateTime? wm;
    for (final m in state.messages) {
      if (wm == null || m.createdAt.isAfter(wm)) wm = m.createdAt;
    }
    _chatClearedWatermark = wm ?? DateTime.now();
    state = state.copyWith(
      messages: const [],
      clearMusicRequestFlash: true,
    );
    _triggerChatClearedBanner();
  }

  /// Temizle işaretinden eski mesajları eler (poll geri getirmesin).
  List<ChatRoomMessage> _filterClearedMessages(List<ChatRoomMessage> list) {
    final wm = _chatClearedWatermark;
    if (wm == null) return list;
    return list
        .where((m) => m.createdAt.isAfter(wm) || m.id.startsWith('local-'))
        .toList();
  }

  Future<void> _deliverMentionNotifications({
    required UserEntity? actor,
    required List<String> mentionedUserIds,
    required String preview,
  }) async {
    if (mentionedUserIds.isEmpty) return;
    try {
      await ref.read(chatRoomRemoteProvider).notifyRoomMentions(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            mentionedUserIds: mentionedUserIds,
            preview: preview,
          );
    } catch (_) {}

    ref.invalidate(notificationsListProvider);

    final actorName = actor?.display.trim().isNotEmpty == true
        ? actor!.display.trim()
        : (actor?.username.trim().isNotEmpty == true
            ? actor!.username.trim()
            : 'Biri');
    final selfId = ref.read(authControllerProvider).valueOrNull?.id;
    for (final id in mentionedUserIds) {
      ChatRoomPresence? target;
      for (final p in state.presence) {
        if (p.id == id) {
          target = p;
          break;
        }
      }
      final targetName = target?.displayName.trim().isNotEmpty == true
          ? target!.displayName.trim()
          : (target?.name.trim().isNotEmpty == true
              ? target!.name.trim()
              : 'Kullanıcı');
      _pushRealtimeEvent(
        VoiceRoomRealtimeKind.system,
        '$actorName, $targetName senden bahsetti.',
      );
      if (id == selfId) {
        showModerationToast('$actorName senden bahsetti.');
      }
    }
  }

  Future<void> sendMessage(String text) async {
    final trimmed = VoiceOfficialJoin.normalizeCommandInput(text.trim());
    if (trimmed.isEmpty || _roomKey.isEmpty) return;
    unawaited(_stopTyping());

    if (VoiceMusicSync.isKapatCommand(trimmed)) {
      await closeMusicPlayer();
      return;
    }

    if (VoiceMusicSync.isIstekCommand(trimmed)) {
      final song = VoiceMusicSync.parseIstekSongTitle(trimmed);
      if (song == null && !VoiceMusicSync.isBareIstekCommand(trimmed)) {
        state = state.copyWith(error: 'Kullanım: !istek veya !istek Sanatçı - Şarkı');
        return;
      }
      VoiceRoomDebugLog.log('music.istek.search', {'song': song ?? '', 'room': _roomKey});
      ref.read(voiceRoomMusicSessionProvider.notifier).clearUserDismissed();
      if (song != null && song.isNotEmpty) {
        unawaited(_postChatLineOnly(trimmed));
      }
      state = state.copyWith(
        pendingMusicSearchQuery: song ?? '',
        pendingMusicSearchSkipPayment: true,
        clearError: true,
        clearMusicRequestFlash: true,
      );
      return;
    }

    final duyuruMessage = VoiceRoomDuyuruAccess.parseCommand(trimmed);
    if (duyuruMessage != null) {
      final err = await sendDuyuruAnnouncement(duyuruMessage);
      if (err != null) {
        state = state.copyWith(error: err);
      } else {
        state = state.copyWith(clearError: true);
      }
      return;
    } else if (_looksLikeDuyuruCommand(trimmed)) {
      state = state.copyWith(error: VoiceRoomDuyuruAccess.validateMessage(''));
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
    if (!perms.canModerate &&
        !perms.isRoomOwner &&
        !perms.isSiteAdmin &&
        state.bannedWords.isNotEmpty &&
        VoiceBannedWordFilter.containsBannedWord(trimmed, state.bannedWords)) {
      state = state.copyWith(error: 'Mesajınız yasaklı kelime içeriyor.');
      return;
    }
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
            .clearChatViaModeration(
              roomKey: _roomKey,
              alternateKey: _roomMeta.slug,
            ),
      );
    }

    final mentionedUserIds = VoiceRoomMention.resolveMentionedUserIds(
      trimmed,
      state.presence,
    ).where((id) => id != user?.id).toList();

    try {
      ChatRoomMessage? sent;
      try {
        sent = await ref
            .read(chatRoomRemoteProvider)
            .sendMessage(
              roomKey: _roomKey,
              content: trimmed,
              nickname: _effectiveNickname(user),
              mentionedUserIds: mentionedUserIds,
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
      if (mentionedUserIds.isNotEmpty) {
        unawaited(
          _deliverMentionNotifications(
            actor: user,
            mentionedUserIds: mentionedUserIds,
            preview: trimmed,
          ),
        );
      }
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
          final kickResult = await remote.kickUser(
            roomKey: _roomKey,
            alternateKey: _roomMeta.slug,
            userId: target.id,
            reason: command.reason,
          );
          _showMusicRequestFlashLine(kickResult.feedbackMessage);
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
          final roleErr = await assignRoleToUser(
            targetUserId: target.id,
            roleSymbol: command.roleSymbol!,
          );
          if (roleErr != null) {
            throw StateError(roleErr);
          }
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
            await remote.clearChatViaModeration(
              roomKey: _roomKey,
              alternateKey: _roomMeta.slug,
            );
            _applyLocalChatClear();
          }
          break;
        case 'duyuru':
          final msg = command.reason?.trim();
          if (msg != null && msg.isNotEmpty) {
            final err = await sendDuyuruAnnouncement(msg);
            if (err != null) {
              state = state.copyWith(error: err);
            }
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

  Future<String?> sendDuyuruAnnouncement(String message) async {
    final validation = VoiceRoomDuyuruAccess.validateMessage(message);
    if (validation != null) return validation;

    final text = message.trim();
    final perms = _permissions();
    final isFree = VoiceRoomDuyuruAccess.isAdminFree(perms);
    if (!isFree) {
      final jeton = VoiceMusicAccess.jetonFromBalances(
        ref.read(walletBalancesProvider).valueOrNull,
      );
      if (!VoiceRoomDuyuruAccess.canAfford(perms: perms, jetonBalance: jeton)) {
        return 'Yetersiz jeton. Duyuru için ${VoiceRoomDuyuruAccess.jetonCost} jeton gerekir.';
      }
    }

    try {
      await ref.read(chatRoomRemoteProvider).postAnnouncement(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            message: text,
            ttl: VoiceRoomDuyuruAccess.displayTtl.inSeconds,
            skipPayment: isFree,
            jetonCost: isFree ? null : VoiceRoomDuyuruAccess.jetonCost,
          );
      _showModeratorAnnouncement(text);
      if (!isFree) {
        invalidateWalletCacheFromRef(ref);
      }
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> postModeratorAnnouncement(String message) async =>
      sendDuyuruAnnouncement(message);

  bool _looksLikeDuyuruCommand(String trimmed) {
    final lower = trimmed.toLowerCase();
    return lower.startsWith('!duyuru') || lower.startsWith('/duyuru');
  }

  Future<String?> clearChatAsModerator() async {
    final perms = _permissions();
    if (!perms.canModerate && !perms.isRoomOwner) {
      return 'Sohbet temizleme yetkiniz yok.';
    }
    try {
      await ref.read(chatRoomRemoteProvider).clearChatViaModeration(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
          );
      _applyLocalChatClear();
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<ModerationKickResult?> kickUserModeration({
    required String userId,
    String? reason,
  }) async {
    final perms = _permissions();
    if (!perms.canModerate && !perms.isRoomOwner) return null;
    try {
      return await ref.read(chatRoomRemoteProvider).kickUser(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            userId: userId,
            reason: reason,
          );
    } catch (_) {
      return null;
    }
  }

  Future<String?> banUserModeration({
    required String userId,
    String? reason,
  }) async {
    final perms = _permissions();
    if (!perms.canBanUsers && !perms.isRoomOwner) {
      return 'Ban yetkiniz yok.';
    }
    try {
      await ref.read(chatRoomRemoteProvider).banUser(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            userId: userId,
            reason: reason,
          );
      showModerationToast('Kullanıcı banlandı');
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> unbanUserModeration({required String userId}) async {
    final perms = _permissions();
    if (!perms.canBanUsers && !perms.isRoomOwner) {
      return 'Ban kaldırma yetkiniz yok.';
    }
    try {
      await ref.read(chatRoomRemoteProvider).unbanUser(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            userId: userId,
          );
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> unmuteUserModeration({required String userId}) async {
    final perms = _permissions();
    if (!perms.canMuteUsers && !perms.isRoomOwner && !perms.canModerate) {
      return 'Susturma kaldırma yetkiniz yok.';
    }
    try {
      await ref.read(chatRoomRemoteProvider).unmuteUser(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            userId: userId,
          );
      await refresh();
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<void> _postChatLineOnly(String content) async {
    final user = ref.read(authControllerProvider).valueOrNull;
    try {
      await ref.read(chatRoomRemoteProvider).sendMessage(
            roomKey: _roomKey,
            content: content,
            nickname: _effectiveNickname(user),
          );
    } catch (_) {}
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

  Future<List<String>> fetchSpeakRequests() async {
    try {
      return await ref.read(chatRoomRemoteProvider).fetchSpeakRequests(_roomKey);
    } catch (_) {
      return [];
    }
  }

  Future<String?> approveSpeakRequest(String userId) async {
    try {
      await ref
          .read(chatRoomRemoteProvider)
          .approveSpeakRequest(_roomKey, userId);
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

  bool _canStopMusic() {
    final user = ref.read(authControllerProvider).valueOrNull;
    return VoiceMusicAccess.canStopMusic(
      user: user,
      perms: _permissions(),
      nowPlaying: state.dj.nowPlaying,
    );
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

  Future<String?> stopMusic() async {
    if (!_canStopMusic()) {
      return 'Müziği yalnızca oda sahibi, admin veya şarkıyı isteyen durdurabilir.';
    }
    return clearMusicQueue();
  }

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

  Future<String?> setRoomPassword({String? password}) async {
    final perms = _permissions();
    if (!perms.isRoomOwner && !perms.canManageRoom && !perms.isSiteAdmin) {
      return 'Oda şifresi ayarlama yetkiniz yok.';
    }
    try {
      await ref.read(chatRoomRemoteProvider).updateRoomSettings(
            roomKey: _roomKey.isNotEmpty ? _roomKey : _roomMeta.id,
            alternateKey: _roomMeta.slug,
            password: password,
            removePassword: password == null || password.isEmpty,
          );
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
      int videoRequestCost,
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
    if (!_canControlMusic()) {
      return 'Bu işlemi gerçekleştirme yetkiniz bulunmamaktadır.';
    }
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

  Future<String?> replayMusic() async {
    if (!_canControlMusic()) {
      return 'Bu işlemi gerçekleştirme yetkiniz bulunmamaktadır.';
    }
    if (state.dj.nowPlaying == null) {
      return 'Tekrar çalınacak parça yok.';
    }
    try {
      _lastDjPlaybackSignature = '';
      final dj = state.dj.copyWith(playing: true);
      final applied = await _applyDjPlayback(dj);
      state = state.copyWith(dj: applied);
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> reorderMusicQueue(List<String> orderedItemIds) async {
    if (!_canControlMusic()) {
      return 'Bu işlemi gerçekleştirme yetkiniz bulunmamaktadır.';
    }
    if (orderedItemIds.isEmpty) return null;
    try {
      await ref.read(chatRoomRemoteProvider).reorderMusicQueue(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            orderedItemIds: orderedItemIds,
          );
      await refresh(includeDj: true);
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> removeQueueItem(String itemId) async {
    if (!_canControlMusic()) {
      return 'Bu işlemi gerçekleştirme yetkiniz bulunmamaktadır.';
    }
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
    if (!_canStopMusic()) {
      return 'Müziği yalnızca oda sahibi, admin veya şarkıyı isteyen durdurabilir.';
    }
    try {
      final result = await ref.read(chatRoomRemoteProvider).clearMusicQueue(
        roomKey: _roomKey,
        alternateKey: _musicAlternateKey,
      );
      if (result.autoAdvanced) {
        await refresh();
        return null;
      }
      await ref.read(voiceRoomDjPlayerProvider).stop();
      await refresh();
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  /// X / kapat — yalnızca yetkili kullanıcılar sunucu kuyruğunu durdurur.
  Future<void> closeMusicPlayer() async {
    if (!_canStopMusic()) {
      ref.read(voiceRoomMusicSessionProvider.notifier).markUserDismissed();
      ref.read(voiceRoomMusicSessionProvider.notifier).dismissAfterClose();
      return;
    }
    ref.read(voiceRoomMusicSessionProvider.notifier).markUserDismissed();
    await ref.read(voiceRoomDjPlayerProvider).stop();
    try {
      final result = await ref.read(chatRoomRemoteProvider).clearMusicQueue(
        roomKey: _roomKey,
        alternateKey: _musicAlternateKey,
      );
      if (result.autoAdvanced) {
        await refresh();
        return;
      }
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
    if (_roomKey.isNotEmpty) {
      ref.read(roomVideoControllerProvider(_roomKey).notifier).clear();
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

  Future<String?> assignRoleToUser({
    required String targetUserId,
    required String roleSymbol,
  }) async {
    final perms = _permissions();
    if (!perms.canManageRoom &&
        !perms.canModerate &&
        !perms.isRoomOwner &&
        !perms.isSiteAdmin) {
      return 'Kullanıcıları taşıma yetkiniz yok.';
    }
    final symbol = roleSymbol.trim();
    if (symbol.isEmpty) {
      return 'Geçerli bir rol sembolü gerekli.';
    }
    try {
      await ref.read(chatRoomRemoteProvider).assignRole(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            userId: targetUserId,
            roleSymbol: symbol,
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
          .read(voiceSeatRestServiceProvider)
          .takeSeat(_roomKey, seatIndex, userId: userId);
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

  Future<String?> clearUserSeat({required String userId}) async {
    try {
      await ref.read(chatRoomRemoteProvider).clearSeat(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            userId: userId,
          );
      await refresh();
      return null;
    } catch (e) {
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
    bool withVideo = false,
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
      if (!djMusicControl) {
        final jeton = VoiceMusicAccess.jetonFromBalances(
          ref.read(walletBalancesProvider).valueOrNull,
        );
        final requiredCost = withVideo
            ? state.dj.videoRequestCost
            : state.dj.musicRequestCost;
        if (!VoiceMusicAccess.canRequestSongs(
              dj: state.dj,
              perms: _permissions(),
              jetonBalance: jeton,
            ) ||
            jeton < requiredCost) {
          return 'Şarkı isteği için en az $requiredCost jetona sahip olmalısınız.';
        }
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
            withVideo: withVideo,
          )
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () => throw TimeoutException('Şarkı isteği zaman aşımı'),
          );
      invalidateWalletCacheFromRef(ref);
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
      var queue = result.queue.isNotEmpty
          ? result.queue
          : state.dj.musicQueue;
      var nowPlaying = _resolveNowPlayingFromRequest(
        queue: queue,
        item: result.item,
        queuePosition: result.queuePosition,
        fallback: state.dj.nowPlaying,
      );
      if (withVideo && nowPlaying != null) {
        nowPlaying = nowPlaying.asVideoRequest();
        queue = queue
            .map((e) => e.id == nowPlaying!.id ? nowPlaying : e)
            .toList();
      }
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
      if (!shouldPlay) {
        unawaited(_syncMusicFromServerIfNeeded());
      }
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
      final words =
          await ref.read(chatRoomRemoteProvider).fetchBannedWords(_roomKey);
      state = state.copyWith(bannedWords: words);
      return words;
    } catch (_) {
      return state.bannedWords;
    }
  }

  Future<List<VoiceRoomBanEntry>> fetchModerationBans() async {
    try {
      final snap = await ref.read(chatRoomRemoteProvider).fetchModeration(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
          );
      return snap.bans;
    } catch (_) {
      return const [];
    }
  }

  Future<String?> addBannedWord(String word) async {
    try {
      final words = await ref
          .read(chatRoomRemoteProvider)
          .addBannedWord(roomKey: _roomKey, word: word);
      state = state.copyWith(bannedWords: words);
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> removeBannedWord(String word) async {
    try {
      final words = await ref
          .read(chatRoomRemoteProvider)
          .removeBannedWord(roomKey: _roomKey, word: word);
      state = state.copyWith(bannedWords: words);
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
    if (name == 'duyuru') {
      final message = args.join(' ').trim();
      return _ParsedRoomCommand(
        name: name,
        reason: message.isNotEmpty ? message : null,
      );
    }
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
    this.canStopMusic = false,
  });

  final VoiceRoomEntity? room;
  final ChatRoomDjState dj;
  final bool visible;
  final bool dismissed;
  /// Kullanıcı X ile kapattı — sunucu hâlâ çalsa bile mini player açılmasın.
  final bool userDismissedPlayer;
  final bool canSyncServer;
  final bool canStopMusic;

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
    bool? canStopMusic,
  }) {
    return VoiceRoomMusicSessionState(
      room: clearRoom ? null : (room ?? this.room),
      dj: dj ?? this.dj,
      visible: visible ?? this.visible,
      dismissed: dismissed ?? this.dismissed,
      userDismissedPlayer: userDismissedPlayer ?? this.userDismissedPlayer,
      canSyncServer: canSyncServer ?? this.canSyncServer,
      canStopMusic: canStopMusic ?? this.canStopMusic,
    );
  }
}

class VoiceRoomMusicSessionNotifier extends Notifier<VoiceRoomMusicSessionState> {
  Object? _detachedKeepAlive;
  Timer? _syncTimer;
  bool _syncing = false;

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
    required bool canStopMusic,
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
          canStopMusic: canStopMusic,
        );
      } else {
        state = state.copyWith(
          room: room,
          dj: dj,
          visible: false,
          dismissed: true,
          canSyncServer: canSyncServer,
          canStopMusic: canStopMusic,
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
      canStopMusic: canStopMusic,
      dismissed: dismissed,
    );
    if (!dismissed) {
      _ensureBackgroundSync(room);
    }
  }

  /// Odaya giriş — farklı odadaysa önceki müziği durdur.
  void prepareForRoomEntry(VoiceRoomEntity room) {
    final prev = state.room;
    if (prev != null &&
        prev.liveKey.isNotEmpty &&
        prev.liveKey != room.liveKey) {
      unawaited(ref.read(voiceRoomDjPlayerProvider).stop());
      ref.read(roomVideoControllerProvider(prev.liveKey).notifier).clear();
      _closeDetachedKeepAlive();
      state = const VoiceRoomMusicSessionState();
    }
    state = state.copyWith(
      dismissed: false,
      userDismissedPlayer: false,
      visible: false,
    );
  }

  void clearUserDismissed() {
    if (!state.userDismissedPlayer) return;
    state = state.copyWith(userDismissedPlayer: false, dismissed: false);
  }

  void onRoomDetached({
    required VoiceRoomEntity room,
    required ChatRoomDjState dj,
    required bool canSyncServer,
    required bool canStopMusic,
    required Object keepAliveLink,
  }) {
    final player = ref.read(voiceRoomDjPlayerProvider);
    final stillPlaying =
        player.playback.value.playing ||
        dj.playing ||
        dj.nowPlaying != null ||
        dj.musicQueue.isNotEmpty;
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
      canStopMusic: canStopMusic,
    );
    _ensureBackgroundSync(room);
  }

  void _ensureBackgroundSync(VoiceRoomEntity room) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 18), (_) async {
      if (_syncing || state.dismissed || state.room?.id != room.id) return;
      _syncing = true;
      try {
        await ref
            .read(voiceRoomLiveProvider(room.liveKey).notifier)
            .refresh(includeDj: true);
        final live = ref.read(voiceRoomLiveProvider(room.liveKey));
        state = state.copyWith(dj: live.dj);
      } catch (_) {} finally {
        _syncing = false;
      }
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

  void onMusicStartedFromServer() {
    state = state.copyWith(
      dismissed: false,
      userDismissedPlayer: false,
      visible: true,
    );
  }

  void dismissFromServerStop() {
    _syncTimer?.cancel();
    _syncTimer = null;
    state = state.copyWith(
      visible: false,
      dismissed: true,
      userDismissedPlayer: false,
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
