import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/voice_staff_rank.dart';
import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/performance/network_perf.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../../../vip_gold/presentation/providers/pending_room_password_provider.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../live_psychics/presentation/providers/psychic_live_event_bus.dart';
import '../../data/datasources/chat_room_remote_datasource.dart';
import '../../data/services/voice_room_debug_log.dart';
import '../../data/services/voice_room_music_pipeline_log.dart';
import '../../data/services/chat_room_sse_service.dart';
import '../../data/services/voice_room_gift_socket.dart';
import '../../data/services/voice_seat_rest_service.dart';
import 'voice_gift_providers.dart';
import 'voice_room_audio_providers.dart';
import 'pk_battle_provider.dart';
import 'pk_battle_remote_provider.dart';
import '../../../../core/network/sse/sse_hub_provider.dart';
import '../../data/youtube_music_search_cache.dart';
import '../../../live/presentation/gifts/providers/live_gift_providers.dart';
import '../../music/domain/entities/room_playback_sync.dart';
import '../../music/presentation/providers/room_music_providers.dart';
import '../../music/presentation/bloc/room_song_bloc.dart';
import '../../music/presentation/bloc/room_song_event.dart';
import '../../domain/entities/chat_room_dj_state.dart';
import '../../domain/entities/music_queue_item.dart';
import '../../../live/domain/entities/live_gift_event.dart';
import '../../domain/entities/chat_room_message.dart';
import '../../domain/voice_playback_limits.dart';
import '../../domain/voice_music_sync.dart';
import '../../domain/utils/voice_banned_word_filter.dart';
import '../../domain/voice_official_join.dart';
import 'voice_room_session_registry.dart';
import '../audio/voice_room_music_audio_session.dart';
import '../utils/voice_room_permissions.dart';
import '../utils/kick_strike_ui.dart';
import '../utils/voice_sse_dj_payload.dart';
import '../utils/voice_music_access.dart';
import '../utils/voice_room_duyuru_access.dart';
import '../utils/voice_room_mention.dart';
import '../utils/voice_room_seat_priority.dart';
import '../utils/voice_staff_chat_style.dart';
import 'staff_entrance_marquee_provider.dart';
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
import '../../domain/entities/voice_room_state_snapshot.dart';
import '../../domain/entities/voice_room_seat_slot.dart';
import '../../../trtc/domain/entities/trtc_credentials.dart';
import '../../domain/entities/popular_music_suggestion.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/youtube_stream_resolver.dart';
import '../audio/voice_room_dj_stream_loader.dart';
import '../services/voice_room_dj_player.dart';
import '../services/voice_room_sse_audio_player.dart';
import '../services/voice_room_music_control_delegate.dart';
import '../../video/domain/youtube_video_id.dart';
import '../../video/presentation/room_video_controller.dart';
import '../../../gifts/presentation/providers/gift_providers.dart';
import '../../../gifts/presentation/providers/gift_catalog_index_provider.dart';
import '../../../gifts/presentation/sync/gift_session_controller.dart';
import '../../../gifts/domain/gift_system_message.dart';
import '../../../gifts/domain/gift_payload_util.dart';
import '../../../gifts/presentation/sync/gift_sse_dispatch.dart';
import '../../../gifts/presentation/sync/gift_sync_log.dart';
import 'voice_gift_providers.dart';
import 'voice_gift_leaderboard_provider.dart';
import 'voice_recent_gifts_provider.dart';
import 'voice_seat_gift_totals_provider.dart';
import 'voice_room_diagnostic_provider.dart';
import 'voice_room_ui_provider.dart';
part 'chat_room_providers_music.dart';
part 'chat_room_providers_moderation.dart';
part 'chat_room_providers_seat.dart';
part 'chat_room_providers_gift.dart';
part 'chat_room_providers_room_sync.dart';
part 'chat_room_providers_presence.dart';
part 'chat_room_providers_dj_sync.dart';

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
    this.seatSlots = const [],
    this.ownerId,
    this.roomTrtc,
    this.backendSyncReady = false,
    this.hubOnlineCount,
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
  /// Backend `GET /seats` — 15 koltuk (sıra korunur).
  final List<VoiceRoomSeatSlot> seatSlots;
  final String? ownerId;
  final TrtcCredentials? roomTrtc;
  /// Join → state → seats tamamlandı; TRTC bağlanabilir.
  final bool backendSyncReady;
  /// Backend/SSE `onlineCount` — presence listesinden bağımsız.
  final int? hubOnlineCount;

  bool get isAnyoneTyping => typingUsers.isNotEmpty;

  int onlineCountFor(VoiceRoomEntity room) {
    final local = presence.length;
    final backend = hubOnlineCount ??
        (room.displayOnline > 0 ? room.displayOnline : null);
    if (backend != null && backend > local) return backend;
    if (local > 0) return local;
    if (selfInRoom) return backend ?? 1;
    if (backendSyncReady) return backend ?? 0;
    return backend ?? 0;
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
    List<VoiceRoomSeatSlot>? seatSlots,
    String? ownerId,
    bool clearOwnerId = false,
    TrtcCredentials? roomTrtc,
    bool clearRoomTrtc = false,
    bool? backendSyncReady,
    int? hubOnlineCount,
    bool clearHubOnlineCount = false,
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
      seatSlots: seatSlots ?? this.seatSlots,
      ownerId: clearOwnerId ? null : (ownerId ?? this.ownerId),
      roomTrtc: clearRoomTrtc ? null : (roomTrtc ?? this.roomTrtc),
      backendSyncReady: backendSyncReady ?? this.backendSyncReady,
      hubOnlineCount: clearHubOnlineCount
          ? null
          : (hubOnlineCount ?? this.hubOnlineCount),
    );
  }
}

class VoiceRoomLiveController
    extends AutoDisposeFamilyNotifier<VoiceRoomLiveState, String>
    with VoiceRoomDjSyncMixin {
  Timer? _poll;
  Timer? _presenceHeartbeat;
  Timer? _typingStopTimer;
  Timer? _enterBannerTimer;
  Timer? _musicRequestFlashTimer;
  Timer? _announcementTimer;
  Timer? _pinnedAnnouncementTimer;
  Timer? _moderationToastTimer;
  Timer? _kickWarningTimer;
  Timer? _seatRefreshDebounce;
  Timer? _sseRoomRefreshDebounce;
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
  var _sessionActive = false;
  var _entryBegun = false;
  var _autoSeatAttempted = false;
  /// Odaya girince eski giriş/çıkış mesajları duyurulmasın.
  var _entrancesArmed = false;
  DateTime? _lastSseEventAt;

  String? _effectiveNickname(UserEntity? user) {
    final server = state.myNickname?.trim();
    if (server != null && server.isNotEmpty) return server;
    final saved = _presenceNickname?.trim();
    if (saved != null && saved.isNotEmpty) return saved;
    final display = user?.display.trim();
    if (display != null && display.isNotEmpty) return display;
    final nick = user?.username.trim();
    if (nick != null && nick.isNotEmpty) return nick;
    return null;
  }

  /// SSE / moderation payload — isim önce, kullanıcı adı yedek.
  String _displayNameFromPayload(Map<String, dynamic> payload) {
    final user = payload['user'];
    if (user is Map) {
      final fromUser = (user['displayName'] ??
              user['name'] ??
              user['nickname'] ??
              user['userName'] ??
              user['username'])
          ?.toString()
          .trim();
      if (fromUser != null && fromUser.isNotEmpty) return fromUser;
    }
    final direct = (payload['displayName'] ??
            payload['name'] ??
            payload['userNickname'] ??
            payload['nickname'] ??
            payload['userName'] ??
            payload['username'])
        ?.toString()
        .trim();
    if (direct != null && direct.isNotEmpty) return direct;
    return 'Kullanıcı';
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
      _cancelSessionTimers();
      if (_sessionActive) {
        clearVoiceRoomLiveSession(ref, _roomKey);
        _removeSelfFromPresenceOptimistic();
        unawaited(_leaveVoiceSession());
        unawaited(_leavePresenceWithSeatClear());
        unawaited(_stopTyping());
        ref.read(sseConnectionHubProvider).releaseVoiceRoom(_roomKey);
        ref.read(voiceRoomGiftSocketProvider).disconnect();
        ref.read(voiceRoomGiftRealtimeProvider).stop();
        ref.read(pkBattleRemoteProvider.notifier).clear();
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
    return VoiceRoomLiveState(
      backgroundUrl: room.backgroundImageUrl?.trim().isNotEmpty == true
          ? room.backgroundImageUrl
          : null,
      loading: false,
    );
  }

  /// Odaya giriş — sıra: presence join → GET state → GET seats → SSE → UI.
  /// TRTC sayfa tarafında `backendSyncReady` + `roomTrtc` ile bağlanır.
  Future<void> _beginRoomSession() async {
    if (_entryBegun) return;
    _entryBegun = true;
    _autoSeatAttempted = false;
    _sseStarted = false;
    _sessionActive = true;
    registerVoiceRoomLiveSession(ref, _roomKey);
    ref
        .read(voiceRoomMusicSessionProvider.notifier)
        .prepareForRoomEntry(_roomMeta);
    unawaited(VoiceRoomMusicAudioSession.ensureConfigured());
    state = state.copyWith(
      loading: true,
      presence: const [],
      seatSlots: const [],
      clearOwnerId: true,
      clearRoomTrtc: true,
      backendSyncReady: false,
    );
    _seedOptimisticSelfPresence();
    _presenceHeartbeat?.cancel();
    _presenceHeartbeat = Timer.periodic(
      ChatRoomRemoteDataSource.presenceHeartbeatInterval,
      (_) {
        if (_sessionActive && state.selfInRoom) {
          unawaited(_presenceHeartbeatTick());
        }
      },
    );

    try {
      await _joinPresence();
      unawaited(_tryAutoPrivilegedSeat());
      _startSse();
      _schedulePoll(sseConnected: false);

      ref.read(pkBattleRemoteProvider.notifier).connectSocket(
            roomId: _roomKey,
            alternateRoomId: _musicAlternateKey,
          );

      await _loadBackendSnapshot();
      await Future.wait<void>([
        _loadInitialMessages(),
        _preloadPkStatus(),
        _preloadGiftCatalog(),
      ], eagerError: false);
      await _bootstrapRoomData();
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> _parallelEntryLoad({bool skipPresence = false}) async {
    if (_roomKey.isEmpty) return;
    try {
      if (!skipPresence) {
        await _joinPresence();
      }
      await Future.wait<void>([
        _loadInitialMessages(),
        _preloadPkStatus(),
        _preloadGiftCatalog(),
      ], eagerError: false);
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> _preloadPkStatus() async {
    try {
      await ref.read(pkBattleRemoteProvider.notifier).loadRoomBattle(
            _roomKey,
            alternateRoomId: _musicAlternateKey,
          );
    } catch (_) {}
  }

  Future<void> _preloadGiftCatalog() async {
    try {
      if (ref.read(allGiftCatalogByIdProvider).isNotEmpty) return;
      final voiceCached = ref.read(voiceRoomGiftCatalogProvider).valueOrNull;
      if (voiceCached != null && voiceCached.isNotEmpty) return;
      final liveCached = ref.read(liveStreamGiftCatalogProvider).valueOrNull;
      if (liveCached != null && liveCached.isNotEmpty) return;
      await ref.read(chatRoomGiftsRemoteProvider).fetchGiftTypes();
    } catch (_) {}
  }

  Future<void> _preloadPresenceMembers() async {
    try {
      final members = await ref
          .read(chatRoomRemoteProvider)
          .fetchPresence(_roomKey, alternateKey: _musicAlternateKey);
      if (members.isEmpty) return;
      state = state.copyWith(
        presence: _mergePresenceStable(members, source: 'preload'),
      );
      _patchHubPresenceCount(members.length);
    } catch (_) {}
  }

  void _seedOptimisticSelfPresence() {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null || _roomKey.isEmpty) return;
    if (state.presence.any((p) => p.id == user.id)) {
      state = state.copyWith(selfInRoom: true, loading: false);
      return;
    }
    final self = ChatRoomPresence(
      id: user.id,
      name: user.display,
      nickname: user.username,
      image: user.avatarUrl,
      chatRole: user.role ?? 'listener',
      roleSymbol: _roleSymbolForUser(user),
    );
    final merged = [...state.presence, self];
    state = state.copyWith(
      presence: merged,
      selfInRoom: true,
      loading: false,
    );
  }

  void _markSseActivity() => _lastSseEventAt = DateTime.now();

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
      _entrancesArmed = true;
    } catch (_) {}
  }

  Future<void> _bootstrapRoomData() async {
    unawaited(_loadBannedWords());
    unawaited(
      _warmBackgrounds().catchError((_) {
        state = state.copyWith(loading: false);
      }),
    );

    final includeDj = VoiceRoomBasicMode.enabled
        ? VoiceRoomBasicMode.musicEnabled
        : true;
    if (state.backendSyncReady) {
      if (includeDj && VoiceRoomBasicMode.musicEnabled) {
        unawaited(refresh(includeDj: true, skipPresenceAndMessages: true));
      }
    } else {
      try {
        await refresh(includeDj: includeDj);
      } catch (_) {}
    }

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

  /// Boş presence güncellemelerinde koltuk/avatar kaybını önler; dolu listede sunucu otoriter.
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

  void _appendSyntheticSystemMessage(
    String content, {
    required ChatMessageKind kind,
    ChatRoomUserRef? user,
  }) {
    final line = content.trim();
    if (line.isEmpty) return;
    final key = '${kind.name}:${user?.id ?? ''}:$line';
    if (_shownEntranceKeys.contains(key)) return;
    _shownEntranceKeys.add(key);
    final id = 'system-${kind.name}-${DateTime.now().microsecondsSinceEpoch}';
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatRoomMessage(
          id: id,
          content: line,
          createdAt: DateTime.now(),
          kind: kind,
          user: user ?? const ChatRoomUserRef(id: 'system', name: 'Sistem'),
        ),
      ],
    );
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

    _scheduleSseRoomRefresh();
  }

  void _scheduleSseRoomRefresh() {
    _sseRoomRefreshDebounce?.cancel();
    _sseRoomRefreshDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!_sessionActive) return;
      unawaited(refresh(includeDj: true, skipPresenceAndMessages: true));
    });
  }

  void _cancelSessionTimers() {
    _poll?.cancel();
    _presenceHeartbeat?.cancel();
    _typingStopTimer?.cancel();
    _enterBannerTimer?.cancel();
    _musicRequestFlashTimer?.cancel();
    _announcementTimer?.cancel();
    _pinnedAnnouncementTimer?.cancel();
    _moderationToastTimer?.cancel();
    _kickWarningTimer?.cancel();
    _seatRefreshDebounce?.cancel();
    _sseRoomRefreshDebounce?.cancel();
  }

  /// Odadan çıkış — önce yerel/TRTC temizliği, backend isteği arka planda.
  Future<void> leaveRoomSession({
    String source = 'ui_leave',
    bool awaitBackend = true,
  }) async {
    if (!_sessionActive) return;
    _sessionActive = false;
    _entryBegun = false;
    VoiceRoomDebugLog.roomLeave(roomId: _roomKey, source: source);
    _cancelSessionTimers();

    // 1) UI/state hemen sıfırla — tekrar girişte eski presence görünmesin.
    clearVoiceRoomLiveSession(ref, _roomKey);
    _removeSelfFromPresenceOptimistic();
    _knownPresenceIds.clear();
    _sseStarted = false;
    _giftSocketStarted = false;
    _presenceJoined = false;
    _voiceJoined = false;
    state = state.copyWith(
      presence: const [],
      seatSlots: const [],
      typingUsers: const [],
      clearOwnerId: true,
      clearRoomTrtc: true,
      backendSyncReady: false,
      selfInRoom: false,
      sseConnected: false,
      loading: false,
    );

    // 2) SSE, hediye, PK — anında kes.
    ref.read(sseConnectionHubProvider).releaseVoiceRoom(_roomKey);
    ref.read(voiceRoomGiftSocketProvider).disconnect();
    ref.read(voiceRoomGiftRealtimeProvider).stop();
    ref.read(voiceRoomGiftRealtimeProvider).setSseActive(false);
    ref.read(voiceRoomGiftRealtimeProvider).resetDedupeState();
    ref.read(pkBattleRemoteProvider.notifier).clear();
    ref.read(pkBattleRemoteProvider.notifier).disconnectSocket();
    ref.read(voiceRoomDiagnosticProvider.notifier).resetForRoom(_roomKey);
    unawaited(_stopTyping());

    // 3) TRTC / ses motoru — öncelikli (≤500ms).
    try {
      await ref
          .read(voiceRoomAudioCoordinatorProvider)
          .leave()
          .timeout(const Duration(milliseconds: 600));
    } catch (_) {}

    // 4) Müzik — oda dışı PiP veya tam kapatma.
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

    // 5) Backend leave — arka plan veya await.
    final backend = _leaveRoomBackend();
    if (awaitBackend) {
      await backend;
    } else {
      unawaited(backend);
    }
  }

  /// Müzik PiP sonrası aynı odaya dönüş — oturumu yeniden başlat.
  void ensureActiveSession() {
    if (_sessionActive) return;
    _entryBegun = false;
    _sessionActive = false;
    unawaited(_beginRoomSession());
  }

  Future<void> _leaveRoomBackend() async {
    try {
      await _leavePresenceWithSeatClear()
          .timeout(const Duration(seconds: 5))
          .catchError((_) {});
    } catch (_) {}
    unawaited(_leaveVoiceSession());
  }

  bool _hasDjPlayableSource(
    ChatRoomDjState dj, {
    RoomPlaybackSync? sync,
    String? videoId,
  }) {
    if (videoId != null && videoId.isNotEmpty) return true;
    if (sync?.currentVideoId?.trim().isNotEmpty == true) return true;
    if (dj.nowPlaying?.resolvedVideoId?.trim().isNotEmpty == true) return true;
    if (dj.nowPlaying?.youtubeUrl.trim().isNotEmpty == true) return true;
    if (sync?.streamUrl?.trim().isNotEmpty == true) return true;
    if (dj.musicUrl?.trim().isNotEmpty == true) return true;
    return false;
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
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    sse
        .connect(
          roomId: _roomKey,
          accessToken: storage.readAccess,
          refreshTokens: () => tryRefreshAccessToken(refreshDio, storage),
          onConnected: () {
            _markSseActivity();
            GiftSyncLog.sseConnected(_roomKey);
            if (!state.sseConnected) {
              state = state.copyWith(sseConnected: true, clearError: true);
            }
            ref.read(voiceRoomGiftRealtimeProvider).setSseActive(true);
            ref.read(voiceRoomGiftSocketProvider).disconnect();
            _giftSocketStarted = false;
            if (!state.selfInRoom || !_presenceJoined) {
              unawaited(_joinPresence());
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
          onSongQueue: (payload) {
            final ev = RoomSongBloc.eventFromSse(payload);
            if (ev != null) {
              ref.read(roomSongBlocProvider(_roomKey)).add(ev);
            }
          },
          onGift: (payload) {
            dispatchGiftSsePayloadRef(
              ref: ref,
              sessionKey: _roomKey,
              payload: payload,
              giftsRemote: giftsRemote,
              voiceRealtime: true,
            );
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
              clearError: true,
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
          onRoomEvent: _handleRoomEvent,
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
        final name = _displayNameFromPayload(payload);
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
        // Hedef kullanıcıda yetkilerin anında uygulanması için yenile.
        unawaited(refresh(includeDj: false));
        return;
      }
      case 'ENTRY_ANNOUNCEMENT': {
        final name = _displayNameFromPayload(payload);
        final entry = payload['entryType']?.toString() ?? '';
        final userRef = ChatRoomUserRef(
          id: payload['userId']?.toString() ?? '',
          name: name,
          nickname: payload['userNickname']?.toString() ??
              payload['username']?.toString(),
          chatRole: entry.isNotEmpty ? entry.toLowerCase() : null,
        );
        final staffLine = VoiceStaffChatStyle.formatStaffEntryLine(
          name,
          user: userRef,
          roomName: _roomMeta.nameTr,
        );
        _pushRealtimeEvent(VoiceRoomRealtimeKind.join, staffLine);
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
    _markSseActivity();
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
    _markSseActivity();
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
      '$name çıkış yaptı',
    );
    final remaining = state.presence.where((p) => p.id != userId).toList();
    if (remaining.length == state.presence.length) return;
    _knownPresenceIds.remove(userId);
    _lastKnownPresenceNames.remove(userId);
    state = state.copyWith(presence: remaining);
    _patchHubPresenceCount(remaining.length);
    ref
        .read(voiceRoomDiagnosticProvider.notifier)
        .setPresence(joined: true, count: remaining.length);
    VoiceRoomDebugLog.log('sse.user_left', {'userId': userId});
    _clearSeatForUser(userId);
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
    // SSE varken mesaj poll zaten kapalı; DJ yokken daha seyrek yenile.
    final interval = sse
        ? (active ? 60 : 120)
        : 8;
    _poll = Timer.periodic(Duration(seconds: interval), (_) {
      if (_pollPaused) return;
      _pollTick++;
      final djActive = state.dj.playing || state.dj.nowPlaying != null;
      if (sse && !djActive && _pollTick % 2 != 0) return;
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

  Future<void> refresh({
    bool includeDj = true,
    bool skipPresenceAndMessages = false,
  }) async {
    if (_roomKey.isEmpty) return;
    final room = _roomMeta;
    final remote = ref.read(chatRoomRemoteProvider);
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user != null && (!_presenceJoined || !state.selfInRoom)) {
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

      if (!skipPresenceAndMessages) {
        final skipMessagePoll = state.sseConnected;
        final results = await Future.wait<Object?>([
          if (skipMessagePoll)
            remote
                .fetchMyPermissions(
                  _roomKey,
                  alternateKey: _musicAlternateKey,
                )
                .then((p) => (
                      messages: state.messages,
                      myPermissions: p ?? state.serverPermissions,
                      myNickname: state.myNickname,
                      roomMuted: state.roomMuted,
                    ))
                .catchError((Object e) {
              refreshError ??= e;
              return (
                messages: state.messages,
                myPermissions: state.serverPermissions,
                myNickname: state.myNickname,
                roomMuted: state.roomMuted,
              );
            })
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
        if ((serverPerms == null || !serverPerms.hasAnyServerFlag) &&
            _isClientRoomOwnerForRefresh(user)) {
          serverPerms = const ChatRoomMyPermissions(
            isRoomOwner: true,
            canGiveVoice: true,
            canGiveOp: true,
            canGiveSop: true,
            canGiveFounder: true,
            canManageRoom: true,
            canMuteUsers: true,
            canKickUsers: true,
            canBanUsers: true,
            canMuteRoom: true,
            role: '~',
          );
        }
        myNickname = msgResult.myNickname ?? myNickname;
        if (msgResult.roomMuted != null) roomMuted = msgResult.roomMuted!;
        presence = _mergePresenceStable(
          results[1]! as List<ChatRoomPresence>,
          source: 'refresh',
        );
      } else if (state.sseConnected) {
        try {
          final perms = await remote.fetchMyPermissions(
            _roomKey,
            alternateKey: _musicAlternateKey,
          );
          if (perms != null) serverPerms = perms;
        } catch (e) {
          refreshError ??= e;
        }
      }

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
        bgFromDj = dj.backgroundImage?.trim();
        final ui = ref.read(voiceRoomUiProvider);
        final sig = _djPlaybackSignature(dj, muted: ui.effectiveMusicMuted);
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
      final msg = ApiException.userMessage(e);
      final lower = msg.toLowerCase();
      if ((state.selfInRoom || state.presence.isNotEmpty || state.sseConnected) &&
          (lower.contains('invalid type') ||
              lower.contains('geçersiz alan') ||
              lower.contains('zaman aşımı') ||
              lower.contains('timeout') ||
              lower.contains('sunucu yanıt vermedi'))) {
        state = state.copyWith(loading: false, clearError: true);
        return;
      }
      state = state.copyWith(
        loading: false,
        error: msg,
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
          muted: ref.read(voiceRoomUiProvider).effectiveMusicMuted,
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
      endpoint: ApiEndpoints.chatRoomMusicQueue(_roomKey),
      dj: stabilized,
      shouldPlay: stabilized.playing && stabilized.playbackSource != null,
    );
    return stabilized;
  }

  /// Poll/SSE geçici `playing:false` döndüğünde yerel IFrame çalmayı korur.
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
    if (_roomKey.isEmpty) return merged;
    final songActive = ref.read(roomSongBlocProvider(_roomKey)).state.hasTrack;
    if (!songActive) return merged;
    if (previous.playing) {
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
      } else {
        nowPlaying = nowPlaying?.asAudioRequest();
        queue = queue.map((e) => e.asAudioRequest()).toList();
      }
      final queuePosition = result.queuePosition ?? 0;
      final songActive = _roomKey.isNotEmpty
          ? ref.read(roomSongBlocProvider(_roomKey)).state.hasTrack
          : false;
      final currentlyPlaying = state.dj.playing ||
          songActive ||
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

  /// SSE nowPlaying — video isteği bayrağını koru.
  MusicQueueItem _mergeNowPlayingFromSse(
    Map<String, dynamic> json, {
    MusicQueueItem? previous,
  }) {
    return MusicQueueItem.fromJson(json);
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
      staffSiteAdmin: ref.read(staffAccessProvider).isFounder,
      walletRole: ref.read(staffAccessProvider).siteRole ??
          ref.read(walletBalancesProvider).valueOrNull?.role,
    );
  }

  bool _isClientRoomOwnerForRefresh(UserEntity? user) {
    if (user == null) return false;
    final room = _roomMeta;
    final uname = user.username.trim().toLowerCase();
    final oid = room.ownerId?.trim() ?? '';
    return (oid.isNotEmpty && oid == user.id) ||
        (uname.isNotEmpty && room.slug.trim().toLowerCase() == uname);
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
      if (!_canStopMusic()) {
        state = state.copyWith(
          error:
              'Müziği yalnızca oda sahibi, admin veya şarkıyı isteyen kapatabilir.',
        );
        return;
      }
      final err = await skipMusic();
      if (err != null) {
        state = state.copyWith(error: err);
      }
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
        pendingMusicSearchSkipPayment: false,
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
          final isDj = state.dj.djUsers.any((d) => d.id == target.id) ||
              _roomMeta.djUserIds.contains(target.id);
          if (isDj) {
            await remote.removeRoomDj(
              roomKey: _roomKey,
              alternateKey: _roomMeta.slug,
              targetUserId: target.id,
              targetLabel: target.displayName,
            );
          } else {
            await remote.addRoomDj(
              roomKey: _roomKey,
              alternateKey: _roomMeta.slug,
              targetUserId: target.id,
              targetLabel: target.displayName,
            );
          }
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
      if (_roomKey.isNotEmpty) {
        ref.read(roomSongBlocProvider(_roomKey)).add(const RoomSongUserPause());
      }
      await ref
          .read(chatRoomRemoteProvider)
          .updateDj(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            musicUrl: state.dj.musicUrl,
            playing: false,
          );
      await ref.read(voiceRoomDjPlayerProvider).stop();
      state = state.copyWith(dj: state.dj.copyWith(playing: false));
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
      if (_roomKey.isNotEmpty) {
        ref.read(roomSongBlocProvider(_roomKey)).add(const RoomSongUserResume());
      }
      await ref
          .read(chatRoomRemoteProvider)
          .updateDj(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            musicUrl: state.dj.musicUrl,
            videoId: state.dj.nowPlaying?.videoIdField ??
                ChatRoomDjState.videoIdFromLoose(
                  state.dj.nowPlaying?.youtubeUrl ?? state.dj.musicUrl ?? '',
                ),
            title: state.dj.nowPlaying?.title,
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
      if (enabled) {
        await _applyDjPlayback(state.dj);
      } else if (_roomKey.isNotEmpty) {
        ref.read(roomSongBlocProvider(_roomKey)).add(const RoomSongUserPause());
      }
      await ref.read(voiceRoomDjPlayerProvider).stop();
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

  Future<String?> assignRoleToUser({
    required String targetUserId,
    required String roleSymbol,
  }) async {
    final perms = _permissions();
    if (!perms.canManageRoom &&
        !perms.canModerate &&
        !perms.canGiveVoice &&
        !perms.isRoomOwner &&
        !perms.isSiteAdmin) {
      return 'Yetki verme izniniz yok.';
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
      if (VoiceRoomSeatPriority.shouldAutoSitForSymbol(symbol)) {
        unawaited(_autoSeatAfterRoleGrant(targetUserId));
      }
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
          requestEndpoint: ApiEndpoints.chatRoomSongRequest(_roomKey),
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
    final liveKey = room.liveKey.trim();
    final songActive = liveKey.isNotEmpty &&
        ref.read(roomSongBlocProvider(liveKey)).state.hasTrack;
    final playing = dj.playing || songActive;
    final hasTrack =
        dj.nowPlaying != null || dj.musicQueue.isNotEmpty || songActive;

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
