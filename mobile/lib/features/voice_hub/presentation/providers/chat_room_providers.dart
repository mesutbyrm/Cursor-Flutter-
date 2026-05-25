import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../data/datasources/chat_room_remote_datasource.dart';
import '../../data/services/voice_room_chat_socket.dart';
import '../../domain/entities/chat_room_dj_state.dart';
import '../../domain/entities/chat_room_message.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/music_queue_item.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../services/voice_room_dj_player.dart';
import 'voice_room_ui_provider.dart';

final chatRoomRemoteProvider = Provider<ChatRoomRemoteDataSource>((ref) {
  return ChatRoomRemoteDataSource(ref.watch(dioProvider));
});

final voiceRoomChatSocketProvider = Provider<VoiceRoomChatSocket>((ref) {
  final s = VoiceRoomChatSocket();
  ref.onDispose(s.disconnect);
  return s;
});

final voiceRoomDjPlayerProvider = Provider<VoiceRoomDjPlayer>((ref) {
  final p = VoiceRoomDjPlayer();
  ref.onDispose(p.dispose);
  return p;
});

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
      _leavePresence();
      ref.read(voiceRoomChatSocketProvider).disconnect();
      ref.read(voiceRoomDjPlayerProvider).stop();
    });
    Future.microtask(() async {
      await _joinPresence();
      await refresh();
      _startSocket(_roomKey);
      _warmBackgrounds();
    });
    _poll = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!state.sending) refresh();
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
        chatRole: 'listener',
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
      state = state.copyWith(loading: false, error: msg);
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
        var banner = state.enterBanner;
        if (msg.kind == ChatMessageKind.systemJoin) {
          final raw = msg.content;
          if (raw.contains('STAFF') || raw.contains('VIP')) {
            banner = raw;
          }
        }
        state = state.copyWith(messages: list, enterBanner: banner);
        if (msg.kind == ChatMessageKind.systemJoin) {
          Future.delayed(const Duration(seconds: 4), () {
            state = state.copyWith(clearEnterBanner: true);
          });
        }
      },
    );
  }

  Future<void> refresh() async {
    if (_roomKey.isEmpty) return;
    final room = arg;
    final remote = ref.read(chatRoomRemoteProvider);
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
      if (ui.backgroundMusicEnabled && dj.playing && dj.musicUrl != null) {
        await ref.read(voiceRoomDjPlayerProvider).sync(
              musicUrl: dj.musicUrl,
              playing: true,
            );
      }
      final prevPresence = state.presence;
      presence = _mergeSelf(presence);
      var messages = _mergeMessages(state.messages, fetchedMsgs);
      final joins = _joinMessagesForNewPresence(prevPresence, presence);
      if (joins.isNotEmpty) {
        messages = _mergeMessages(messages, joins);
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
        backgroundUrl: (state.backgroundUrl?.isNotEmpty == true)
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

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _roomKey.isEmpty) return;
    if (state.sending) return;

    final user = ref.read(authControllerProvider).valueOrNull;
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
      sending: true,
      clearError: true,
    );

    Future<ChatRoomMessage?> post(String key, {String? alt}) => ref
        .read(chatRoomRemoteProvider)
        .sendMessage(
          roomKey: key,
          alternateKey: alt,
          content: trimmed,
        )
        .timeout(const Duration(seconds: 25));

    try {
      await () async {
        ChatRoomMessage? sent;
        try {
          sent = await post(_roomKey, alt: _altRoomKey);
        } on TimeoutException {
          final alt = _altRoomKey;
          if (alt != null && alt.isNotEmpty && alt != _roomKey) {
            sent = await post(alt, alt: _roomKey);
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
                (m.id.startsWith('local-') && m.content == delivered.content),
          );
          if (idx >= 0) {
            list[idx] = sent;
          } else {
            list.add(sent);
          }
        } else if (optimistic != null) {
          list.add(optimistic);
        }
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        state = state.copyWith(messages: list, clearError: true);
      }().timeout(const Duration(seconds: 22));
    } on TimeoutException {
      state = state.copyWith(
        error: 'Mesaj gönderimi zaman aşımına uğradı. Tekrar deneyin.',
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

  Future<String?> requestSpeak() async {
    try {
      await ref.read(chatRoomRemoteProvider).requestSpeak(
            _roomKey,
            alternateKey: _altRoomKey,
          );
      ref.read(voiceRoomUiProvider.notifier).setRequestSpeakPending(true);
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
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

  Future<List<YoutubeSearchHit>> searchYoutube(String query) => ref
      .read(chatRoomRemoteProvider)
      .searchYoutube(query)
      .timeout(
        const Duration(seconds: 18),
        onTimeout: () => throw TimeoutException('YouTube araması zaman aşımı'),
      );

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
      return ApiException.userMessage(e);
    }
  }

  Future<String?> requestMusic({
    required String title,
    required String youtubeUrl,
    String? thumbUrl,
    String? videoId,
  }) async {
    try {
      final result = await ref
          .read(chatRoomRemoteProvider)
          .requestMusic(
            roomKey: _roomKey,
            alternateKey: _altRoomKey,
            title: title,
            youtubeUrl: youtubeUrl,
            thumbUrl: thumbUrl,
            videoId: videoId,
          )
          .timeout(
            const Duration(seconds: 22),
            onTimeout: () => throw TimeoutException('Şarkı isteği zaman aşımı'),
          );
      if (result.newBalance != null) {
        ref.invalidate(coinBalanceProvider);
      }
      state = state.copyWith(
        dj: ChatRoomDjState(
          djUsers: state.dj.djUsers,
          activeDjId: state.dj.activeDjId,
          ownerPresent: state.dj.ownerPresent,
          canPlayMusic: state.dj.canPlayMusic,
          isOwner: state.dj.isOwner,
          musicUrl: state.dj.musicUrl,
          playing: state.dj.playing,
          musicQueue: result.queue,
          musicRequestCost: state.dj.musicRequestCost,
          maxDj: state.dj.maxDj,
        ),
      );
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
}

final voiceRoomLiveProvider = NotifierProvider.autoDispose
    .family<VoiceRoomLiveController, VoiceRoomLiveState, VoiceRoomEntity>(
  VoiceRoomLiveController.new,
);
