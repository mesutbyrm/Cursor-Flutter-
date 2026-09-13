import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../vip_gold/domain/entrance_theme.dart';
import '../../../vip_gold/domain/vip_tier.dart';

class VoiceRoomGoldEntranceEvent {
  const VoiceRoomGoldEntranceEvent({
    required this.userName,
    required this.tier,
    required this.theme,
    this.avatarUrl,
  });

  final String userName;
  final VipTier tier;
  final EntranceTheme theme;
  final String? avatarUrl;
}

class VoiceRoomGoldEntranceNotifier
    extends FamilyNotifier<VoiceRoomGoldEntranceEvent?, String> {
  final _seen = <String>{};
  Timer? _clear;

  @override
  VoiceRoomGoldEntranceEvent? build(String arg) {
    ref.onDispose(() => _clear?.cancel());
    return null;
  }

  void show(VoiceRoomGoldEntranceEvent event, {String? dedupeKey}) {
    final key = dedupeKey ?? '${event.userName}:${event.tier.name}';
    if (!_seen.add(key)) return;
    _clear?.cancel();
    state = event;
    _clear = Timer(const Duration(seconds: 8), () {
      state = null;
    });
  }

  void clear() {
    _clear?.cancel();
    state = null;
  }
}

final voiceRoomGoldEntranceProvider = NotifierProvider.family<
    VoiceRoomGoldEntranceNotifier,
    VoiceRoomGoldEntranceEvent?,
    String>(VoiceRoomGoldEntranceNotifier.new);
