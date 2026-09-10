import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/voice_gift_revenue.dart';
import '../providers/voice_gift_providers.dart';
import '../providers/pk_battle_remote_provider.dart';

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

  // Tek UI yolu: [GiftEventListener] → orchestrator (SSE ile aynı dedupe).
  ref.read(voiceRoomGiftRealtimeProvider).publishRemote(event);
}
