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
import '../../data/services/voice_room_debug_log.dart';
import '../pages/voice_room_owner_summary_page.dart';
import '../providers/chat_room_providers.dart';
import '../providers/voice_session_visitors_provider.dart';

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
          'Sesli sohbet odasından çıkmak istiyor musunuz?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hayır'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Evet'),
          ),
        ],
      ),
    );
    return leave == true;
  }

  /// Gezinme yığınında (push edilmiş sayfalar dahil) hâlâ bir oda sayfası var mı?
  /// Odanın üstüne profil vb. açıldığında oturum kapatılmamalı.
  static bool voiceRoomInStack(Iterable<String> matchedLocations) =>
      matchedLocations.any(shouldLeaveVoiceRoomRoute);

  static bool shouldLeaveVoiceRoomRoute(String location) {
    if (location == '/voice-rooms') return false;
    return location.startsWith('/voice-room/') || location == '/voice-room';
  }

  static void navigateAwayFromRoom({BuildContext? context}) {
    try {
      final nav = rootNavigatorKey.currentContext ?? context;
      if (nav != null && nav.mounted) {
        final router = GoRouter.of(nav);
        // Önceki sayfa varsa ona dön (liste, sosyal, bildirim…); yoksa liste.
        if (router.canPop()) {
          router.pop();
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
    VoiceRoomDebugLog.log('LEAVE_UI', {'roomId': key, 'source': source});

    try {
      try {
        await prepareLeave?.call();
      } catch (_) {}

      SessionGiftSummary? leaveSummary;
      VoiceRoomOwnerSummaryData? ownerSummary;
      // Özet yalnız gösterim içindir; hata atarsa sunucu leave'i ATLANMAMALI.
      // Önceden buradaki istisna dış `catch`'e düşüyor, `leaveRoomSession` hiç
      // çağrılmadan sayfadan çıkılıyordu (logda LEAVE_START yok) ve sayfa
      // dispose'u da `_leaveSessionStarted` yüzünden leave atlıyordu.
      try {
        final user = ref.read(authControllerProvider).valueOrNull;
        final visitors = key.isNotEmpty
            ? ref.read(voiceSessionVisitorsProvider.notifier).takeAndReset(key)
            : null;
        if (key.isNotEmpty && user != null) {
          final live = ref.read(voiceRoomLiveProvider(key));
          final ownerId = (live.ownerId ?? room.ownerId)?.trim() ?? '';
          leaveSummary = SessionGiftSummaryBuilder.forVoiceRoom(
            ref: ref,
            roomTitle: room.displayTitle,
            ownerUserId: live.ownerId ?? room.ownerId,
            ownerDisplayName: room.ownerName,
            myUserId: user.id,
            myDisplayName: user.display,
          );
          if (ownerId.isNotEmpty && ownerId == user.id) {
            ownerSummary = VoiceRoomOwnerSummaryData(
              roomTitle: room.displayTitle,
              startedAt: visitors?.startedAt ?? DateTime.now(),
              endedAt: DateTime.now(),
              visitors: visitors?.visitors.values.toList() ?? const [],
              senders: leaveSummary.senders,
              totalGrossJeton: leaveSummary.totalGrossJeton,
              estimatedOwnerNetJeton: leaveSummary.myNetJeton,
            );
          }
        }
      } catch (e) {
        leaveSummary = null;
        ownerSummary = null;
        VoiceRoomDebugLog.log('LEAVE_SUMMARY_SKIPPED', {
          'roomId': key,
          'error': e.runtimeType.toString(),
        });
      }

      if (key.isNotEmpty) {
        try {
          await ref
              .read(voiceRoomLiveProvider(key).notifier)
              .leaveRoomSession(source: source, awaitBackend: true, force: true)
              .timeout(const Duration(seconds: 8));
        } catch (e) {
          VoiceRoomDebugLog.log('LEAVE_FAILED', {
            'roomId': key,
            'source': source,
            'error': e.runtimeType.toString(),
          });
        }
      }

      if (context.mounted) {
        navigateAwayFromRoom(context: context);
        navigated = true;
      }

      if (ownerSummary != null) {
        final data = ownerSummary;
        unawaited(
          Future<void>.delayed(const Duration(milliseconds: 350), () async {
            final rootCtx = rootNavigatorKey.currentContext;
            if (rootCtx != null && rootCtx.mounted) {
              await showVoiceRoomOwnerSummaryPage(rootCtx, data);
            }
          }),
        );
      } else if (leaveSummary != null && leaveSummary.hasData) {
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
      if (!navigated && context.mounted) {
        navigateAwayFromRoom(context: context);
        navigated = true;
      }
    } finally {
      if (!navigated && context.mounted) {
        navigateAwayFromRoom(context: context);
      }
    }
  }
}
