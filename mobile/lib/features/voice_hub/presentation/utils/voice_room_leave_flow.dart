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
import '../../../live/domain/pk/live_pk_broadcast_stage.dart';
import '../providers/pk_battle_remote_provider.dart';
import '../../data/services/voice_room_debug_log.dart';
import '../pages/voice_room_owner_summary_page.dart';
import '../providers/chat_room_providers.dart';
import '../providers/voice_session_visitors_provider.dart';

/// Sesli oda çıkış — onay diyalogu ve hediye özeti (Basic + RTC ortak).
abstract final class VoiceRoomLeaveFlow {
  static String? pkOutcomeForRoom(WidgetRef ref, String roomId) {
    final battle = ref.read(pkBattleRemoteProvider);
    if (battle == null) return null;
    final id = roomId.trim();
    final hostRoom = battle.voiceRoomId?.trim() ?? '';
    final guestRoom = battle.opponentVoiceRoomId?.trim() ?? '';
    if (id.isEmpty || (hostRoom != id && guestRoom != id)) return null;
    final battleMap = <String, dynamic>{
      if (battle.endsAt != null)
        'endsAt': battle.endsAt!.toUtc().toIso8601String(),
      if (battle.startedAt != null)
        'startedAt': battle.startedAt!.toUtc().toIso8601String(),
      'durationSeconds': battle.durationSeconds,
    };
    if (!livePkBattleFinished(status: battle.status, battle: battleMap)) {
      return null;
    }
    final left = battle.challengerScore;
    final right = battle.opponentScore;
    if (left == right) return 'Berabere';
    final myRoomIsChallenger = hostRoom == id;
    final myScore = myRoomIsChallenger ? left : right;
    final theirScore = myRoomIsChallenger ? right : left;
    return myScore > theirScore ? 'Kazandınız' : 'Kaybettiniz';
  }

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
          final sessionDuration = visitors != null
              ? DateTime.now().difference(visitors.startedAt)
              : null;
          leaveSummary = SessionGiftSummaryBuilder.forVoiceRoom(
            ref: ref,
            roomTitle: room.displayTitle,
            ownerUserId: live.ownerId ?? room.ownerId,
            ownerDisplayName: room.ownerName,
            myUserId: user.id,
            myDisplayName: user.display,
            duration: sessionDuration,
            pkOutcomeLabel: pkOutcomeForRoom(ref, key),
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

      final rootCtx = rootNavigatorKey.currentContext ?? context;
      if (leaveSummary != null && rootCtx.mounted) {
        final showSummary = leaveSummary.hasData ||
            leaveSummary.isHostOrOwner ||
            (leaveSummary.duration != null && leaveSummary.duration! > Duration.zero);
        if (showSummary) {
          await showSessionGiftSummarySheet(rootCtx, summary: leaveSummary);
          await SessionGiftSummaryBuilder.refreshWalletIfRecipient(
            ref,
            leaveSummary,
          );
        }
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
          Future<void>.delayed(const Duration(milliseconds: 250), () async {
            final navCtx = rootNavigatorKey.currentContext;
            if (navCtx != null && navCtx.mounted) {
              await showVoiceRoomOwnerSummaryPage(navCtx, data);
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
