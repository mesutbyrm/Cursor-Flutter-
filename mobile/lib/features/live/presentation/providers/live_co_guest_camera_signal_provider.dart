import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Yayıncı → misafir kamera komutu (SSE veya signal poll).
class LiveCoGuestCameraSignalEvent {
  const LiveCoGuestCameraSignalEvent({
    required this.payload,
    required this.seq,
  });

  final Map<String, dynamic> payload;
  final int seq;
}

class LiveCoGuestCameraSignalNotifier
    extends Notifier<LiveCoGuestCameraSignalEvent?> {
  @override
  LiveCoGuestCameraSignalEvent? build() => null;

  void push(Map<String, dynamic> payload) {
    state = LiveCoGuestCameraSignalEvent(
      payload: Map<String, dynamic>.from(payload),
      seq: (state?.seq ?? 0) + 1,
    );
  }
}

final liveCoGuestCameraSignalProvider = NotifierProvider<
    LiveCoGuestCameraSignalNotifier, LiveCoGuestCameraSignalEvent?>(
  LiveCoGuestCameraSignalNotifier.new,
);
