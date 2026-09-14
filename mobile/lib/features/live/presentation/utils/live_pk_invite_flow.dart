import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/pk_event_log.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../voice_hub/presentation/providers/pk_battle_remote_provider.dart';
import '../../domain/pk/live_pk_invite_helper.dart';
import '../../domain/pk/pk_status_helper.dart';
import '../providers/live_invite_dedup_provider.dart';
import '../providers/live_pk_action_lock_provider.dart';
import '../providers/live_video_pk_provider.dart';
import '../providers/pk_session_phase_provider.dart';
import 'open_host_broadcast_room.dart';
import '../providers/live_active_broadcast_provider.dart';

/// Gelen canlı PK daveti — kabul / red (oda içi, ayarlar, global dinleyici).
Future<bool> respondLivePkInvite(
  WidgetRef ref, {
  required String streamId,
  required String battleId,
  required bool accept,
}) async {
  final id = battleId.trim();
  final sid = streamId.trim();
  if (id.isEmpty || sid.isEmpty) return false;

  final lock = ref.read(livePkActionLockProvider.notifier);
  if (!lock.tryAcquire(id, 'respond')) return false;
  try {
    if (accept) {
      PkEventLog.acceptStart(inviteId: id);
      await ref.read(pkBattleRemoteProvider.notifier).accept(id, streamId: sid);
      await ref.read(liveVideoPkProvider(sid).notifier).refresh();
      PkEventLog.acceptSuccess(battleId: id);
    } else {
      PkEventLog.reject(inviteId: id);
      await ref.read(pkBattleRemoteProvider.notifier).reject(id, streamId: sid);
      await ref.read(liveVideoPkProvider(sid).notifier).refresh();
    }
    return true;
  } catch (e) {
    ref.read(pkSessionPhaseProvider.notifier).reset();
    await ref.read(liveVideoPkProvider(sid).notifier).refresh();
    rethrow;
  } finally {
    lock.release(id, 'respond');
  }
}

Future<void> showLiveStreamPkInviteDialog(
  BuildContext context,
  WidgetRef ref, {
  required String streamId,
  required Map<String, dynamic> battle,
}) async {
  final battleId = (battle['id'] ?? battle['battleId'] ?? battle['pkBattleId'])
      ?.toString()
      .trim() ??
      '';
  if (battleId.isEmpty) return;

  final challenger = battle['leftName']?.toString() ??
      battle['challengerName']?.toString() ??
      'Yayıncı';

  final accept = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A0F2E),
      title: const Row(
        children: [
          Text('🔥 ', style: TextStyle(fontSize: 22)),
          Text('PK Daveti', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: Text(
        '$challenger seninle PK yapmak istiyor.',
        style: const TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Reddet'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Kabul Et'),
        ),
      ],
    ),
  ).timeout(
    const Duration(seconds: 45),
    onTimeout: () => null,
  );

  if (!context.mounted || accept == null) {
    ref.read(liveInviteDedupProvider.notifier).unmark(livePkInviteDedupKey(battleId));
    return;
  }

  try {
    await respondLivePkInvite(
      ref,
      streamId: streamId,
      battleId: battleId,
      accept: accept,
    );
    if (!context.mounted) return;
    if (accept) {
      if (!isLiveBroadcastRoomActiveForStream(ref, streamId)) {
        await openHostBroadcastRoomIfNeeded(
          ref: ref,
          context: context,
          streamId: streamId,
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PK kabul edildi — başlıyor')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PK daveti reddedildi')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }
}

bool isLivePkIncomingInviteForHost(
  Map<String, dynamic>? battle,
  String streamId,
  String? userId,
) {
  if (battle == null) return false;
  final status = battle['status']?.toString() ?? '';
  if (!isPkInvitePendingStatus(status)) return false;
  return isLivePkInviteRecipientMap(
    battle,
    myStreamId: streamId,
    myUserId: userId,
  );
}

bool isLivePkOutgoingInvite(
  Map<String, dynamic>? battle,
  String? userId,
) {
  if (battle == null || userId == null) return false;
  final status = battle['status']?.toString() ?? '';
  if (!isPkInvitePendingStatus(status)) return false;
  final uid = userId.trim();
  final challenger = battle['challengerId']?.toString().trim() ?? '';
  return challenger.isNotEmpty && challenger == uid;
}
