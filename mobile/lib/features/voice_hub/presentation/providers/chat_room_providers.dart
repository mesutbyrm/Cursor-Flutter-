import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/voice_staff_rank.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../data/datasources/chat_room_remote_datasource.dart';
import '../../data/services/voice_room_chat_socket.dart';
import '../../domain/entities/chat_room_dj_state.dart';
import '../../domain/entities/chat_room_message.dart';
import '../../domain/voice_official_join.dart';
import '../utils/voice_room_permissions.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/music_queue_item.dart';
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

final voiceRoomChatSocketProvider = Provider<VoiceRoomChatSocket>((ref) {
  final s = VoiceRoomChatSocket();
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
    this.backgroundUrl,
    this.selfInRoom = false,
  });

  final List<ChatRoomMessage> messages;
  final List<ChatRoomPresence> presence;
  final ChatRoomDjState dj;
  final bool loading;
  final String? error;
  final bool sending;
  final String? enterBanner;
  final String? backgroundUrl;
  final bool selfInRoom;

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
    String? backgroundUrl,
    bool? selfInRoom,
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
      backgroundUrl: backgroundUrl ?? this.backgroundUrl,
      selfInRoom: selfInRoom ?? this.selfInRoom,
    );
  }
}

class VoiceRoomLiveController extends AutoDisposeFamilyNotifier<
    VoiceRoomLiveState, VoiceRoomEntity> {
  Timer? _poll;
  Timer? _enterBannerTimer;
  var _pollPaused = false;

  String get _roomKey => arg.apiRoomKey;

  String? get _altRoomKey => arg.apiRoomAlternateKey;

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

  List<ChatRoomMessage> _joinMessagesForNewPresence(
    List<ChatRoomPresence> previous,
    List<ChatRoomPresence> next,
  ) {
    if (previous.isEmpty) return const [];
    final known = previous.map((p) => p.id).toSet();
    final out = <ChatRoomMessage>[];
    for (final p in next) {
      if (known.contains(p.id)) continue;
      out.add(
        ChatRoomMessage(
          id: 'join-${p.id}-${DateTime.now().microsecondsSinceEpoch}',
          content: '${p.displayName} odaya katıldı',
          createdAt: DateTime.now(),
          user: ChatRoomUserRef(
            id: p.id,
            name: p.name,
            nickname: p.nickname,
            image: p.image,
            chatRole: p.chatRole,
            roleSymbol: p.roleSymbol,
            membership: p.membership,
          ),
          kind: ChatMessageKind.systemJoin,
        ),
      );
    }
    return out;
  }

  @override
  VoiceRoomLiveState build(VoiceRoomEntity room) {
    ref.keepAlive();
    ref.onDispose(() {
      _poll?.cancel();
      _enterBannerTimer?.cancel();
      _leavePresence();
      ref.read(voiceRoomChatSocketProvider).disconnect();
      ref.read(voiceRoomDjPlayerProvider).stop();
    });
    Future.microtask(() async {
      ref.invalidate(coinBalanceProvider);
      ref.invalidate(walletBalancesProvider);
      await _joinPresence();
      await refresh();
      _startSocket(_roomKey);
      _warmBackgrounds();
      final player = ref.read(voiceRoomDjPlayerProvider);
      player.onTrackComplete = () => unawaited(_onDjTrackComplete());
    });
    _poll = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pollPaused) refresh();
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
      final joined = await ref.read(chatRoomRemoteProvider).joinPresence(
            _roomKey,
            alternateKey: _altRoomKey,
          );
      final merged = _mergeSelf(joined);
      state = state.copyWith(
        presence: merged,
        selfInRoom: true,
        loading: false,
        clearError: true,
      );
    } on Object catch (e) {
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
      await ref.read(chatRoomRemoteProvider).leavePresence(
            _roomKey,
            alternateKey: _altRoomKey,
          );
    } catch (_) {}
  }

  void _startSocket(String roomId) {
    ref.read(voiceRoomChatSocketProvider).connect(
      roomId: roomId,
      onMessage: (msg) {
        final exists = state.messages.any((m) => m.id == msg.id);
        if (exists) return;
        final list = [...state.messages, msg];
        state = state.copyWith(messages: list);
        if (msg.kind == ChatMessageKind.systemJoin &&
            VoiceOfficialJoin.isOfficialEntrance(msg.content)) {
          _showEnterBanner(msg.content);
        }
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
          alternateKey: _altRoomKey,
          since: since,
        );
      } catch (e) {
        refreshError ??= e;
      }
      try {
        presence = await remote.fetchPresence(
          _roomKey,
          alternateKey: _altRoomKey,
        );
      } catch (e) {
        refreshError ??= e;
      }
      try {
        dj = await remote.fetchDj(_roomKey, alternateKey: _altRoomKey);
      } catch (_) {}
      final ui = ref.read(voiceRoomUiProvider);
      await ref.read(voiceRoomDjPlayerProvider).sync(
        musicUrl: dj.musicUrl,
        playing: dj.playing,
        muted: !ui.backgroundMusicEnabled,
      );
      final bgFromDj = dj.backgroundImage?.trim();
      presence = _mergeSelf(presence);
      var messages = _mergeMessages(state.messages, fetchedMsgs);
      final latestOfficial = VoiceOfficialJoin.latestEntranceBanner(
        messages
            .where((m) => m.kind == ChatMessageKind.systemJoin)
            .map((m) => m.content),
      );
      if (latestOfficial != null) {
        final formatted = VoiceOfficialJoin.formatEntranceBanner(
          latestOfficial,
          roomName: arg.nameTr,
        );
        if (state.enterBanner != formatted) {
          _showEnterBanner(latestOfficial);
        }
      }
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
            alternateKey: _altRoomKey,
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

  void _showEnterBanner(String raw) {
    final formatted = VoiceOfficialJoin.formatEntranceBanner(
      raw,
      roomName: arg.nameTr,
    );
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
              alternateKey: _altRoomKey,
            ),
      );
    }

    try {
      ChatRoomMessage? sent;
      try {
        sent = await ref.read(chatRoomRemoteProvider).sendMessage(
              roomKey: _roomKey,
              alternateKey: _altRoomKey,
              content: trimmed,
            ).timeout(const Duration(seconds: 22));
      } on TimeoutException {
        final alt = _altRoomKey;
        if (alt != null && alt.isNotEmpty && alt != _roomKey) {
          sent = await ref
              .read(chatRoomRemoteProvider)
              .sendMessage(
                roomKey: alt,
                alternateKey: _roomKey,
                content: trimmed,
              )
              .timeout(const Duration(seconds: 22));
        } else {
          rethrow;
        }
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
      if (VoiceOfficialJoin.looksLikeRoomCommand(trimmed)) {
        unawaited(refresh());
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
            alternateKey: _altRoomKey,
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
            alternateKey: _altRoomKey,
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
              alternateKey: _altRoomKey,
              musicUrl: dj.musicUrl ??
                  'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
              playing: true,
            );
      } else {
        await ref.read(chatRoomRemoteProvider).updateDj(
              roomKey: _roomKey,
              alternateKey: _altRoomKey,
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
            alternateKey: _altRoomKey,
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

  Future<({List<MusicQueueItem> queue, int cost})> fetchMusicQueue() =>
      ref.read(chatRoomRemoteProvider).fetchMusicQueue(
            _roomKey,
            alternateKey: _altRoomKey,
          );

  Future<String?> assignSeat({
    required int seatIndex,
    String? userId,
  }) async {
    try {
      await ref.read(chatRoomRemoteProvider).assignSeat(
            roomKey: _roomKey,
            alternateKey: _altRoomKey,
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
      await ref
          .read(chatRoomRemoteProvider)
          .requestMusic(
            roomKey: _roomKey,
            alternateKey: _altRoomKey,
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
      await refresh();
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> addRoomDj(String targetUserId) async {
    try {
      await ref.read(chatRoomRemoteProvider).addRoomDj(
            roomKey: _roomKey,
            alternateKey: _altRoomKey,
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
            alternateKey: _altRoomKey,
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
            alternateKey: _altRoomKey,
          );
    } catch (_) {
      return const [];
    }
  }

  Future<String?> addBannedWord(String word) async {
    try {
      await ref.read(chatRoomRemoteProvider).addBannedWord(
            roomKey: _roomKey,
            alternateKey: _altRoomKey,
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
            alternateKey: _altRoomKey,
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
