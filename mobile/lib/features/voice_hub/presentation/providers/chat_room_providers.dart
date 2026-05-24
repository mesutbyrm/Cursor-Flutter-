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

  String? get _altRoomKey {
    final id = arg.id.trim();
    final slug = arg.slug.trim();
    if (id.isNotEmpty && slug.isNotEmpty && id != slug) return slug;
    return null;
  }

  @override
  VoiceRoomLiveState build(VoiceRoomEntity room) {
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
    });
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => refresh());
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
        refresh();
      },
    );
  }

  Future<void> refresh() async {
    if (_roomKey.isEmpty) return;
    final room = arg;
    final remote = ref.read(chatRoomRemoteProvider);
    try {
      final results = await Future.wait([
        remote.fetchMessages(_roomKey, alternateKey: _altRoomKey),
        remote.fetchPresence(_roomKey, alternateKey: _altRoomKey),
        remote.fetchDj(_roomKey, alternateKey: _altRoomKey),
      ]);
      final dj = results[2] as ChatRoomDjState;
      final ui = ref.read(voiceRoomUiProvider);
      if (ui.backgroundMusicEnabled && dj.playing && dj.musicUrl != null) {
        await ref.read(voiceRoomDjPlayerProvider).sync(
              musicUrl: dj.musicUrl,
              playing: true,
            );
      }
      final presence = _mergeSelf(results[1] as List<ChatRoomPresence>);
      state = state.copyWith(
        messages: results[0] as List<ChatRoomMessage>,
        presence: presence,
        dj: dj,
        loading: false,
        clearError: true,
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

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending || _roomKey.isEmpty) return;
    state = state.copyWith(sending: true);
    try {
      final sent = await ref.read(chatRoomRemoteProvider).sendMessage(
            roomKey: _roomKey,
            alternateKey: _altRoomKey,
            content: trimmed,
          );
      if (sent != null && !state.messages.any((m) => m.id == sent.id)) {
        state = state.copyWith(messages: [...state.messages, sent]);
      }
      await refresh();
    } catch (e) {
      state = state.copyWith(error: ApiException.userMessage(e));
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
}

final voiceRoomLiveProvider = NotifierProvider.autoDispose
    .family<VoiceRoomLiveController, VoiceRoomLiveState, VoiceRoomEntity>(
  VoiceRoomLiveController.new,
);
