import 'package:flutter_riverpod/flutter_riverpod.dart';

class PsychicPeerLeftEvent {
  const PsychicPeerLeftEvent({
    required this.sessionId,
    required this.message,
    required this.seq,
  });

  final String sessionId;
  final String message;
  final int seq;
}

class PsychicPeerLeftNotifier extends Notifier<PsychicPeerLeftEvent?> {
  var _seq = 0;

  @override
  PsychicPeerLeftEvent? build() => null;

  void notifyPeerLeft({
    required String sessionId,
    required String message,
  }) {
    final id = sessionId.trim();
    if (id.isEmpty) return;
    _seq++;
    state = PsychicPeerLeftEvent(
      sessionId: id,
      message: message,
      seq: _seq,
    );
  }

  void clear() => state = null;
}

final psychicPeerLeftProvider =
    NotifierProvider<PsychicPeerLeftNotifier, PsychicPeerLeftEvent?>(
  PsychicPeerLeftNotifier.new,
);
