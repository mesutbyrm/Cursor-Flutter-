import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../gifts/domain/session_gift_summary.dart';
import '../../../gifts/domain/session_gift_summary_builder.dart';
import '../../../gifts/presentation/widgets/session_gift_summary_sheet.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../providers/chat_room_providers.dart';

/// Sesli oda çıkış — onay diyalogu ve hediye özeti (Basic + RTC ortak).
abstract final class VoiceRoomLeaveFlow {
  static Future<bool> confirmLeave(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0F2E),
        title: const Text(
          'Odadan çık',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Sesli sohbetten ayrılmak istiyor musunuz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çık'),
          ),
        ],
      ),
    );
    return leave == true;
  }

  static void navigateAwayFromRoom({BuildContext? context}) {
    final nav = rootNavigatorKey.currentContext ?? context;
    if (nav == null || !nav.mounted) return;
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.go('/voice-rooms');
    }
  }

  static Future<void> leaveWithSummary({
    required BuildContext context,
    required WidgetRef ref,
    required String liveKey,
    required VoiceRoomEntity room,
    required String source,
    Future<void> Function()? prepareLeave,
  }) async {
    final key = liveKey.trim();
    if (key.isEmpty) return;

    await prepareLeave?.call();

    final live = ref.read(voiceRoomLiveProvider(key));
    final user = ref.read(authControllerProvider).valueOrNull;
    SessionGiftSummary? leaveSummary;
    if (user != null) {
      leaveSummary = SessionGiftSummaryBuilder.forVoiceRoom(
        ref: ref,
        roomTitle: room.displayTitle,
        ownerUserId: live.ownerId ?? room.ownerId,
        ownerDisplayName: room.ownerName,
        myUserId: user.id,
        myDisplayName: user.display,
      );
    }

    try {
      await ref
          .read(voiceRoomLiveProvider(key).notifier)
          .leaveRoomSession(
            source: source,
            awaitBackend: true,
            force: true,
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {}

    navigateAwayFromRoom();

    if (leaveSummary != null && leaveSummary.hasData) {
      final rootCtx = rootNavigatorKey.currentContext;
      if (rootCtx != null && rootCtx.mounted) {
        await showSessionGiftSummarySheet(rootCtx, summary: leaveSummary);
      }
    }
  }
}
