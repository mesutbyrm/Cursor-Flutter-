import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/voice_official_join.dart';

/// Yetkili giriş duyurusu — sayfa üstünde geçici kayan şerit (kalıcı banner değil).
class StaffEntranceMarqueeState {
  const StaffEntranceMarqueeState({this.message});

  final String? message;

  StaffEntranceMarqueeState copyWith({String? message, bool clear = false}) {
    return StaffEntranceMarqueeState(
      message: clear ? null : (message ?? this.message),
    );
  }
}

class StaffEntranceMarqueeNotifier extends Notifier<StaffEntranceMarqueeState> {
  final _seen = <String>{};
  Timer? _clearTimer;

  @override
  StaffEntranceMarqueeState build() {
    ref.onDispose(() => _clearTimer?.cancel());
    return const StaffEntranceMarqueeState();
  }

  /// Sağdan sola kayan şerit — aynı metin oturumda bir kez.
  void enqueue(String raw, {String? roomName}) {
    final line = VoiceOfficialJoin.formatEntranceBanner(raw, roomName: roomName);
    if (line.isEmpty) return;
    final key = VoiceOfficialJoin.entranceDedupeKey(line, roomName: roomName);
    if (!_seen.add(key)) return;
    _clearTimer?.cancel();
    state = StaffEntranceMarqueeState(message: line);
    _clearTimer = Timer(const Duration(seconds: 12), () {
      if (!ref.mounted) return;
      state = const StaffEntranceMarqueeState();
    });
  }

  void clear() {
    _clearTimer?.cancel();
    state = const StaffEntranceMarqueeState();
  }
}

final staffEntranceMarqueeProvider =
    NotifierProvider<StaffEntranceMarqueeNotifier, StaffEntranceMarqueeState>(
  StaffEntranceMarqueeNotifier.new,
);
