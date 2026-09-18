import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/pk_event_log.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../pk/presentation/providers/pk_providers.dart';
import '../../../pk/presentation/providers/pk_session_notifier.dart';
import '../../../pk/presentation/widgets/pk_invite_dialog.dart';
import '../../../pk/data/pk_models.dart';
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
    final sessionArgs = PkSessionArgs(contextId: sid, kind: PkContextKind.live);
    if (accept) {
      PkEventLog.acceptStart(inviteId: id);
      try {
        await ref.read(pkServiceProvider).accept(id);
      } catch (_) {
        await ref.read(pkBattleRemoteProvider.notifier).accept(id, streamId: sid);
      }
      await ref.read(liveVideoPkProvider(sid).notifier).refresh();
      await ref.read(pkSessionProvider(sessionArgs).notifier).loadState();
      PkEventLog.acceptSuccess(battleId: id);
    } else {
      PkEventLog.reject(inviteId: id);
      try {
        await ref.read(pkServiceProvider).reject(id);
      } catch (_) {
        await ref.read(pkBattleRemoteProvider.notifier).reject(id, streamId: sid);
      }
      await ref.read(liveVideoPkProvider(sid).notifier).refresh();
      await ref.read(pkSessionProvider(sessionArgs).notifier).loadState();
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
      battle['challenger']?.toString() ??
      'Yayıncı';
  final image = battle['challengerImage']?.toString() ??
      battle['leftImage']?.toString() ??
      (battle['user1'] is Map
          ? (battle['user1'] as Map)['image']?.toString()
          : null) ??
      '';

  var normalized = Map<String, dynamic>.from(battle);
  if ((normalized['id']?.toString() ?? '').isEmpty) {
    normalized['id'] = battleId;
  }
  final pkBattle = PkBattle.fromJson(normalized);
  final skew = ref.read(pkServiceProvider).clockSkew;
  const maxInvite = Duration(seconds: 60);
  final rawInvite = pkBattle.remainingInvite(skew) ?? maxInvite;
  final inviteTimeout = rawInvite > maxInvite
      ? maxInvite
      : (rawInvite.isNegative ? Duration.zero : rawInvite);

  final accept = await showPkInviteDialog(
    context,
    challengerName: challenger,
    challengerImageUrl: image,
    inviteTimeout: inviteTimeout,
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
      if (!context.mounted) return;
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
