import 'package:flutter_riverpod/flutter_riverpod.dart';

/// El kaldırma / konuşma isteği — SSE room_event uyandırma.
class VoiceSpeakRequestSignalNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final voiceSpeakRequestSignalProvider =
    NotifierProvider<VoiceSpeakRequestSignalNotifier, int>(
  VoiceSpeakRequestSignalNotifier.new,
);
