import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/pk/live_pk_broadcast_stage.dart';
import '../../domain/pk/pk_status_helper.dart';

/// Ana Sayfa → Canlı → PK için sunum geçiş altyapısı (§33-P).
///
/// PK RTC / battle mantığına dokunmaz; yalnızca ileride VS / glow / countdown
/// animasyonlarının tek giriş noktası.
enum LivePkHomeTransitionPhase {
  idle,
  enteringLive,
  enteringPkShell,
  pkActive,
}

class LivePkHomeTransitionState {
  const LivePkHomeTransitionState({
    this.phase = LivePkHomeTransitionPhase.idle,
    this.streamId,
    this.battleId,
  });

  final LivePkHomeTransitionPhase phase;
  final String? streamId;
  final String? battleId;

  LivePkHomeTransitionState copyWith({
    LivePkHomeTransitionPhase? phase,
    String? streamId,
    String? battleId,
  }) {
    return LivePkHomeTransitionState(
      phase: phase ?? this.phase,
      streamId: streamId ?? this.streamId,
      battleId: battleId ?? this.battleId,
    );
  }
}

class LivePkHomeTransitionNotifier extends Notifier<LivePkHomeTransitionState> {
  @override
  LivePkHomeTransitionState build() => const LivePkHomeTransitionState();

  void noteEnteringLive({String? streamId}) {
    state = state.copyWith(
      phase: LivePkHomeTransitionPhase.enteringLive,
      streamId: streamId,
    );
  }

  void noteEnteringPkShell({String? battleId}) {
    state = state.copyWith(
      phase: LivePkHomeTransitionPhase.enteringPkShell,
      battleId: battleId,
    );
  }

  void notePkActive() {
    state = state.copyWith(phase: LivePkHomeTransitionPhase.pkActive);
  }

  void reset() {
    state = const LivePkHomeTransitionState();
  }
}

final livePkHomeTransitionProvider =
    NotifierProvider<LivePkHomeTransitionNotifier, LivePkHomeTransitionState>(
  LivePkHomeTransitionNotifier.new,
);

/// PK battle haritasından sunum fazını günceller (RTC / token yok).
void syncLivePkHomeTransitionFromBattle(
  Ref ref, {
  Map<String, dynamic>? battle,
  String? streamId,
}) {
  syncLivePkHomeTransitionState(
    ref.read(livePkHomeTransitionProvider.notifier),
    battle: battle,
    streamId: streamId,
  );
}

void syncLivePkHomeTransitionState(
  LivePkHomeTransitionNotifier bridge, {
  Map<String, dynamic>? battle,
  String? streamId,
}) {
  if (battle == null || battle.isEmpty) {
    bridge.reset();
    return;
  }
  final status = battle['status']?.toString() ?? '';
  final battleId =
      battle['id']?.toString() ?? battle['battleId']?.toString();
  if (streamId != null && streamId.trim().isNotEmpty) {
    bridge.noteEnteringLive(streamId: streamId.trim());
  }
  if (isLivePkEndedStatus(status) ||
      (status.isEmpty && (battleId == null || battleId.isEmpty))) {
    bridge.reset();
    return;
  }
  if (isPkInvitePendingStatus(status)) {
    bridge.noteEnteringPkShell(battleId: battleId);
    return;
  }
  if (isLivePkActiveStatus(status)) {
    bridge.noteEnteringPkShell(battleId: battleId);
    bridge.notePkActive();
  }
}
