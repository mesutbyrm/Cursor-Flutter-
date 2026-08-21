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
    final dialogContext = rootNavigatorKey.currentContext ?? context;
    if (!dialogContext.mounted) return false;
    final leave = await showDialog<bool>(
      context: dialogContext,
      barrierDismissible: true,
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

  static bool shouldLeaveVoiceRoomRoute(String location) {
    if (location == '/voice-rooms') return false;
    return location.startsWith('/voice-room/') || location == '/voice-room';
  }

  static void navigateAwayFromRoom({BuildContext? context}) {
    try {
      final nav = rootNavigatorKey.currentContext ?? context;
      if (nav != null && nav.mounted) {
        final router = GoRouter.of(nav);
        final location = router.state.matchedLocation;
        if (shouldLeaveVoiceRoomRoute(location)) {
          router.go('/voice-rooms');
          return;
        }
        if (nav.canPop()) {
          nav.pop();
          return;
        }
        router.go('/voice-rooms');
        return;
      }
    } catch (_) {}
    try {
      rootNavigatorKey.currentContext?.go('/voice-rooms');
    } catch (_) {}
  }

  /// Onay diyalogu olmadan doğrudan odadan çık.
  static Future<void> leaveDirect({
    required BuildContext context,
    required WidgetRef ref,
    required String liveKey,
    required VoiceRoomEntity room,
    required String source,
    Future<void> Function()? prepareLeave,
  }) {
    return leaveWithSummary(
      context: context,
      ref: ref,
      liveKey: liveKey,
      room: room,
      source: source,
      prepareLeave: prepareLeave,
    );
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
    var navigated = false;

    try {
      try {
        await prepareLeave?.call();
      } catch (_) {}

      SessionGiftSummary? leaveSummary;
      final user = ref.read(authControllerProvider).valueOrNull;
      if (key.isNotEmpty && user != null) {
        final live = ref.read(voiceRoomLiveProvider(key));
        leaveSummary = SessionGiftSummaryBuilder.forVoiceRoom(
          ref: ref,
          roomTitle: room.displayTitle,
          ownerUserId: live.ownerId ?? room.ownerId,
          ownerDisplayName: room.ownerName,
          myUserId: user.id,
          myDisplayName: user.display,
        );
      }

      if (key.isNotEmpty) {
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
      }

      navigateAwayFromRoom(context: context);
      navigated = true;

      if (leaveSummary != null && leaveSummary.hasData) {
        unawaited(
          Future<void>.delayed(const Duration(milliseconds: 350), () async {
            final rootCtx = rootNavigatorKey.currentContext;
            if (rootCtx != null && rootCtx.mounted) {
              await showSessionGiftSummarySheet(
                rootCtx,
                summary: leaveSummary!,
              );
            }
          }),
        );
      }
    } catch (_) {
      if (!navigated) {
        navigateAwayFromRoom(context: context);
      }
    } finally {
      if (!navigated) {
        navigateAwayFromRoom(context: context);
      }
    }
  }
}
