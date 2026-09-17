import 'package:flutter_riverpod/flutter_riverpod.dart';

class LivePkScoreBurstState {
  const LivePkScoreBurstState({
    this.token = 0,
    this.delta = 0,
    this.toLeft = true,
  });

  final int token;
  final int delta;
  final bool toLeft;
}

class LivePkScoreBurstNotifier
    extends AutoDisposeFamilyNotifier<LivePkScoreBurstState, String> {
  int _prevLeft = 0;
  int _prevRight = 0;
  var _primed = false;

  @override
  LivePkScoreBurstState build(String streamId) => const LivePkScoreBurstState();

  void observeScores({required int left, required int right}) {
    if (!_primed) {
      _prevLeft = left;
      _prevRight = right;
      _primed = true;
      return;
    }
    final dLeft = left - _prevLeft;
    final dRight = right - _prevRight;
    _prevLeft = left;
    _prevRight = right;
    if (dLeft > 0 && dLeft >= dRight) {
      state = LivePkScoreBurstState(
        token: state.token + 1,
        delta: dLeft,
        toLeft: true,
      );
    } else if (dRight > 0) {
      state = LivePkScoreBurstState(
        token: state.token + 1,
        delta: dRight,
        toLeft: false,
      );
    }
  }

  void reset() {
    _primed = false;
    _prevLeft = 0;
    _prevRight = 0;
    state = const LivePkScoreBurstState();
  }
}

final livePkScoreBurstProvider = NotifierProvider.autoDispose
    .family<LivePkScoreBurstNotifier, LivePkScoreBurstState, String>(
  LivePkScoreBurstNotifier.new,
);
