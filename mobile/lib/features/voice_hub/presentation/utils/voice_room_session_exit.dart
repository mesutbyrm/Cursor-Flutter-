import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/voice_room_realtime_event.dart';
import '../providers/chat_room_providers.dart';
import 'voice_room_leave_flow.dart';

/// Oda kapatma / yasak gibi zorunlu oturum sonları — liste ekranına yönlendirme.
abstract final class VoiceRoomSessionExit {
  static bool isBanEvent(VoiceRoomRealtimeEvent event) {
    return event.kind == VoiceRoomRealtimeKind.moderation &&
        event.message.toLowerCase().contains('yasaklandınız');
  }

  static bool isTerminalError(String? error) {
    if (error == null || error.trim().isEmpty) return false;
    final lower = error.toLowerCase();
    return lower.contains('kapatıldı') ||
        lower.contains('yasakland') ||
        lower.contains('room closed') ||
        lower.contains('banned');
  }

  static String? detectExitMessage({
    VoiceRoomLiveState? prev,
    required VoiceRoomLiveState next,
  }) {
    if (next.realtimeEvents.length > (prev?.realtimeEvents.length ?? 0)) {
      final latest = next.realtimeEvents.first;
      if (isBanEvent(latest)) return latest.message;
    }
    if (next.error != null &&
        next.error != prev?.error &&
        isTerminalError(next.error)) {
      return next.error;
    }
    if ((prev?.selfInRoom ?? false) &&
        !next.selfInRoom &&
        next.presence.isEmpty &&
        next.error != null) {
      return next.error;
    }
    return null;
  }

  static Future<void> handleForcedExit({
    required BuildContext context,
    required WidgetRef ref,
    required String liveKey,
    required String message,
  }) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Oda sonlandı'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );

    final live = ref.read(voiceRoomLiveProvider(liveKey));
    if (live.selfInRoom || live.presence.isNotEmpty || live.sseConnected) {
      try {
        await ref
            .read(voiceRoomLiveProvider(liveKey).notifier)
            .leaveRoomSession(
              source: 'forced_session_exit',
              awaitBackend: true,
              force: true,
            )
            .timeout(const Duration(seconds: 8));
      } catch (_) {}
    }

    VoiceRoomLeaveFlow.navigateAwayFromRoom(context: context);
  }
}
