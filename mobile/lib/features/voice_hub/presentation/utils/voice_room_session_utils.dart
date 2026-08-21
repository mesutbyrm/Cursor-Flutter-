import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_room_providers.dart';
import '../providers/pk_battle_remote_provider.dart';
import '../providers/voice_gift_providers.dart';
import '../providers/voice_recent_gifts_provider.dart';
import '../providers/voice_room_audio_providers.dart';
import '../providers/voice_room_session_registry.dart';

/// Oda değiştirmeden önce aktif oturumu güvenle kapat.
Future<void> teardownVoiceRoomBeforeSwitch(
  WidgetRef ref, {
  required String liveKey,
  String source = 'room_switch',
}) async {
  final key = liveKey.trim();
  if (key.isEmpty) return;

  final active = ref.read(voiceRoomActiveLiveKeyProvider);
  if (active == key) {
    ref.read(voiceRoomActiveLiveKeyProvider.notifier).state = null;
    ref.read(voiceRoomActiveKeyAliasesProvider.notifier).state = const {};
  }

  ref.read(pkBattleRemoteProvider.notifier).clear();
  ref.read(voiceRoomGiftRealtimeProvider).stop();
  ref.read(voiceRecentGiftsProvider.notifier).clear();
  ref.read(voiceRoomAudioCoordinatorProvider).setReconnectSuspended(true);

  try {
    await ref
        .read(voiceRoomLiveProvider(key).notifier)
        .leaveRoomSession(
          source: source,
          awaitBackend: true,
          force: true,
        )
        .timeout(const Duration(seconds: 8));
  } catch (_) {
    unawaited(
      ref.read(voiceRoomLiveProvider(key).notifier).leaveRoomSession(
            source: '$source:retry',
            awaitBackend: false,
            force: true,
          ),
    );
  }
}

/// Önceki oda (varsa) tamamen kapatılır, ardından yeni oda kaydedilir.
Future<void> prepareVoiceRoomSwitch(
  WidgetRef ref, {
  required String nextLiveKey,
  String source = 'room_switch',
}) async {
  final next = nextLiveKey.trim();
  if (next.isEmpty) return;
  final active = ref.read(voiceRoomActiveLiveKeyProvider);
  if (active != null && active.isNotEmpty && active != next) {
    await teardownVoiceRoomBeforeSwitch(ref, liveKey: active, source: source);
  }
  ref.read(voiceRoomActiveLiveKeyProvider.notifier).state = next;
  ref.read(voiceRoomActiveKeyAliasesProvider.notifier).state = {next};
}
