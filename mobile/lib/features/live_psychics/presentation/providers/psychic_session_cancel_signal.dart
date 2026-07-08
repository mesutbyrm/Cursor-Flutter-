import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Oturum iptal/red — bekleme ekranı ve falcı dialog'unu anında kapatır.
class PsychicSessionCancelEvent {
  const PsychicSessionCancelEvent({
    required this.sessionId,
    required this.seq,
  });

  final String sessionId;
  final int seq;
}

class PsychicSessionCancelSignal extends Notifier<PsychicSessionCancelEvent?> {
  var _seq = 0;

  @override
  PsychicSessionCancelEvent? build() => null;

  void signal(String sessionId) {
    final id = sessionId.trim();
    if (id.isEmpty) return;
    _seq++;
    state = PsychicSessionCancelEvent(sessionId: id, seq: _seq);
  }

  void clear() => state = null;
}

final psychicSessionCancelSignalProvider =
    NotifierProvider<PsychicSessionCancelSignal, PsychicSessionCancelEvent?>(
  PsychicSessionCancelSignal.new,
);
