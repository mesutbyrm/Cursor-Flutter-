import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../live/domain/entities/voice_room_entity.dart';
import 'voice_room_session_utils.dart';

/// Sesli odaya geçiş — önce eski oda tamamen kapatılır (presence/SSE).
Future<void> navigateToVoiceRoom(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  String source = 'navigate',
}) async {
  final key =
      room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id.trim();
  if (key.isEmpty) return;
  await prepareVoiceRoomSwitch(ref, nextLiveKey: key, source: source);
  if (!context.mounted) return;
  context.go('/voice-room/$key', extra: room);
}

/// Entity yüklenemediğinde ID ile geçiş — teardown önce, oda sayfası sonra yükler.
Future<void> navigateToVoiceRoomById(
  BuildContext context,
  WidgetRef ref, {
  required String roomId,
  String source = 'navigate',
}) async {
  final key = roomId.trim();
  if (key.isEmpty) return;
  await prepareVoiceRoomSwitch(ref, nextLiveKey: key, source: source);
  if (!context.mounted) return;
  context.push('/voice-room/$key');
}
