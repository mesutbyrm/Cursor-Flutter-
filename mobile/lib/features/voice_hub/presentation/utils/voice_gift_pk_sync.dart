import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../gifts/presentation/sync/gift_sse_dispatch.dart';
import '../../../live/presentation/gifts/providers/live_gift_providers.dart';
import '../../domain/entities/voice_gift_revenue.dart';
import '../../domain/pk/pk_battle_remote_models.dart';
import '../providers/pk_battle_remote_provider.dart';
import '../providers/voice_gift_leaderboard_provider.dart';

/// Hediye POST yanıtı — SSE beklemeden PK skoru + hediye animasyonu senkronu.
void applyVoiceGiftSendSideEffects({
  required WidgetRef ref,
  required String roomKey,
  required VoiceGiftSendResult result,
}) {
  final pk = result.pkBattle;
  if (pk != null && pk.effectiveId.isNotEmpty) {
    ref.read(pkBattleRemoteProvider.notifier).ingestSseBattle(pk);
  }

  final event = result.giftEvent;
  if (event == null) return;

  final payload = <String, dynamic>{
    'id': event.id,
    'giftId': event.giftId,
    'giftName': event.giftName,
    'senderId': event.senderId,
    'senderName': event.senderName,
    'receiverId': event.receiverId,
    'receiverName': event.receiverName,
    'quantity': event.quantity,
    'jetonAmount': event.jetonAmount,
    'coinCost': event.jetonAmount,
    'roomId': roomKey,
    if (pk != null) 'pkBattle': _pkToMap(pk),
  };

  dispatchGiftSsePayload(
    ref: ref,
    sessionKey: roomKey,
    payload: payload,
    giftsRemote: ref.read(liveGiftsRemoteProvider),
    voiceRealtime: true,
  );
  ref.read(voiceSessionGiftLeaderboardProvider.notifier).record(event);
}

Map<String, dynamic> _pkToMap(PkBattleRemote pk) => {
      'id': pk.id,
      'inviteId': pk.inviteId,
      'status': pk.status,
      'challengerScore': pk.challengerScore,
      'opponentScore': pk.opponentScore,
      'voiceRoomId': pk.voiceRoomId,
      'opponentVoiceRoomId': pk.opponentVoiceRoomId,
    };
