import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
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
  });

  final List<ChatRoomMessage> messages;
  final List<ChatRoomPresence> presence;
  final ChatRoomDjState dj;
  final bool loading;
  final String? error;
  final bool sending;
  final String? enterBanner;
  final String? backgroundUrl;

  int get onlineCount => presence.isNotEmpty ? presence.length : 0;

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
  }) {
    return VoiceRoomLiveState(
      messages: messages ?? this.messages,
      presence: presence ?? this.presence,
      dj: dj ?? this.dj,
      loading: loading ?? this.loading,
      error: error,
      sending: sending ?? this.sending,
      enterBanner: clearEnterBanner ? null : (enterBanner ?? this.enterBanner),
      backgroundUrl: backgroundUrl ?? this.backgroundUrl,
    );
  }
}

class VoiceRoomLiveController extends AutoDisposeFamilyNotifier<
    VoiceRoomLiveState, VoiceRoomEntity> {
  Timer? _poll;

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
      _startSocket(room.id);
    });
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => refresh());
    return VoiceRoomLiveState(backgroundUrl: room.backgroundImageUrl);
  }

  Future<void> _joinPresence() async {
    try {
      await ref.read(chatRoomRemoteProvider).joinPresence(arg.id);
    } on Object catch (e) {
      final msg = ApiException.userMessage(e);
      if (msg.toLowerCase().contains('yasak') ||
          msg.contains('403') ||
          msg.toLowerCase().contains('forbidden')) {
        state = state.copyWith(
          loading: false,
          error: 'Bu odadan yasaklandınız',
        );
      }
    }
  }

  Future<void> _leavePresence() async {
    try {
      await ref.read(chatRoomRemoteProvider).leavePresence(arg.id);
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
    final room = arg;
    final remote = ref.read(chatRoomRemoteProvider);
    try {
      final results = await Future.wait([
        remote.fetchMessages(room.id),
        remote.fetchPresence(room.id),
        remote.fetchDj(room.id),
      ]);
      final dj = results[2] as ChatRoomDjState;
      final ui = ref.read(voiceRoomUiProvider);
      if (ui.backgroundMusicEnabled && dj.playing) {
        await ref.read(voiceRoomDjPlayerProvider).sync(
              musicUrl: dj.musicUrl,
              playing: true,
            );
      }
      state = state.copyWith(
        messages: results[0] as List<ChatRoomMessage>,
        presence: results[1] as List<ChatRoomPresence>,
        dj: dj,
        loading: false,
        error: null,
        backgroundUrl: state.backgroundUrl ?? room.backgroundImageUrl,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;
    state = state.copyWith(sending: true);
    try {
      final sent = await ref.read(chatRoomRemoteProvider).sendMessage(
            roomId: arg.id,
            content: trimmed,
          );
      if (sent != null && !state.messages.any((m) => m.id == sent.id)) {
        state = state.copyWith(messages: [...state.messages, sent]);
      }
      await refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(sending: false);
    }
  }

  Future<void> requestSpeak() async {
    await ref.read(chatRoomRemoteProvider).requestSpeak(arg.id);
    ref.read(voiceRoomUiProvider.notifier).setRequestSpeakPending(true);
  }

  Future<void> cancelSpeakRequest() async {
    await ref.read(chatRoomRemoteProvider).cancelSpeakRequest(arg.id);
    ref.read(voiceRoomUiProvider.notifier).setRequestSpeakPending(false);
  }

  Future<void> toggleBackgroundMusic(bool enabled) async {
    final dj = state.dj;
    if (enabled && dj.canPlayMusic) {
      await ref.read(chatRoomRemoteProvider).updateDj(
            roomId: arg.id,
            musicUrl: dj.musicUrl ??
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
            playing: true,
          );
    } else {
      await ref.read(chatRoomRemoteProvider).updateDj(
            roomId: arg.id,
            musicUrl: dj.musicUrl,
            playing: false,
          );
      await ref.read(voiceRoomDjPlayerProvider).stop();
    }
    await refresh();
  }

  Future<void> setRoomBackground(String url) async {
    await ref.read(chatRoomRemoteProvider).setRoomBackground(
          roomId: arg.id,
          backgroundImage: url,
        );
    state = state.copyWith(backgroundUrl: url);
    ref.invalidate(voiceRoomsProvider);
  }

  Future<List<String>> fetchBackgrounds() =>
      ref.read(chatRoomRemoteProvider).fetchBackgrounds();
}

final voiceRoomLiveProvider = NotifierProvider.autoDispose
    .family<VoiceRoomLiveController, VoiceRoomLiveState, VoiceRoomEntity>(
  VoiceRoomLiveController.new,
);
