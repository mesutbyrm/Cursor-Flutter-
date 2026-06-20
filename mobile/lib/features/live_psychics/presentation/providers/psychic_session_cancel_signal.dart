import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Oturum iptal/red — bekleme ekranı ve falcı dialog'unu anında kapatır.
class PsychicSessionCancelSignal extends Notifier<String?> {
  var _seq = 0;

  @override
  String? build() => null;

  int get seq => _seq;

  void signal(String sessionId) {
    final id = sessionId.trim();
    if (id.isEmpty) return;
    _seq++;
    state = id;
  }

  void clear() => state = null;
}

final psychicSessionCancelSignalProvider =
    NotifierProvider<PsychicSessionCancelSignal, String?>(
  PsychicSessionCancelSignal.new,
);
