import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/speak_request_status.dart';
import '../providers/chat_room_providers.dart';
import '../providers/voice_room_session_registry.dart';
import '../providers/voice_speak_request_signal_provider.dart';
import '../utils/voice_room_permissions.dart';

/// Sesli oda konuşma isteği — SSE `voice_request` / `hand_raised` host popup.
Future<void> showVoiceSpeakRequestDialog(
  BuildContext context,
  WidgetRef ref, {
  required VoiceSpeakRequestIncoming request,
  required VoiceRoomEntity room,
}) async {
  if (request.requestId.isEmpty) return;

  final seen = ref.read(voiceSpeakRequestSeenIdsProvider);
  if (seen.contains(request.dedupeKey)) return;
  ref.read(voiceSpeakRequestSeenIdsProvider.notifier).state = {
    ...seen,
    request.dedupeKey,
  };

  final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
  final ctrl = ref.read(voiceRoomLiveProvider(key).notifier);

  final action = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A0F2E),
      title: const Text(
        'Konuşma isteği',
        style: TextStyle(color: Colors.white),
      ),
      content: Text(
        '${request.userName} konuşmak istiyor.${request.message != null && request.message!.trim().isNotEmpty ? '\n\n"${request.message!.trim()}"' : ''}',
        style: const TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'block'),
          child: const Text('Engelle', style: TextStyle(color: Colors.redAccent)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'reject'),
          child: const Text('Hayır'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, 'approve'),
          child: const Text('Evet'),
        ),
      ],
    ),
  ).timeout(
    const Duration(seconds: 45),
    onTimeout: () => null,
  );

  ref.read(voiceSpeakRequestQueueProvider.notifier).removeForRequest(
        key,
        request.requestId,
      );

  if (!context.mounted || action == null) return;

  try {
    switch (action) {
      case 'approve':
        final err = await ctrl.approveSpeakRequest(request.userId);
        if (context.mounted && err != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err)),
          );
        }
        break;
      case 'reject':
        final err = await ctrl.rejectSpeakRequest(request.userId);
        if (context.mounted && err != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err)),
          );
        }
        break;
      case 'block':
        final err = await ctrl.blockSpeakRequest(request.userId);
        if (context.mounted && err != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err)),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${request.userName} engellendi')),
          );
        }
        break;
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }
}

VoiceRoomPermissions _permsForRoom(WidgetRef ref, String roomKey) {
  final live = ref.read(voiceRoomLiveProvider(roomKey));
  final user = ref.read(authControllerProvider).valueOrNull;
  final room = resolveSpeakRequestRoom(ref, roomKey);
  if (user == null || room == null) {
    return const VoiceRoomPermissions(
      isSiteAdmin: false,
      isRoomOwner: false,
      canModerate: false,
      canManageDj: false,
      canChangeBackground: false,
    );
  }
  ChatRoomPresence? self;
  for (final p in live.presence) {
    if (p.id == user.id) {
      self = p;
      break;
    }
  }
  return VoiceRoomPermissions.forUser(
    user: user,
    room: room,
    selfPresence: self,
    server: live.serverPermissions,
  );
}

bool canModerateSpeakRequests(WidgetRef ref, String roomKey) {
  final perms = _permsForRoom(ref, roomKey);
  return perms.canAssignSeats || perms.isRoomOwner || perms.isSiteAdmin;
}

VoiceRoomEntity? resolveSpeakRequestRoom(WidgetRef ref, String roomKey) {
  final trimmed = roomKey.trim();
  if (trimmed.isEmpty) return null;
  final direct = ref.read(voiceRoomByIdProvider(trimmed)).valueOrNull;
  if (direct != null) return direct;
  final rooms = ref.read(voiceRoomsProvider).valueOrNull ?? const [];
  for (final room in rooms) {
    if (room.liveKey == trimmed ||
        room.id == trimmed ||
        room.apiRoomKey == trimmed ||
        room.slug == trimmed) {
      return room;
    }
  }
  return null;
}
