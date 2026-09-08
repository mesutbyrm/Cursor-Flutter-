import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global ortak yayın kabulü — yayın sayfası TRTC co-host senkronu için.
class PendingCoBroadcastJoinNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setPending(String streamId) {
    final id = streamId.trim();
    state = id.isEmpty ? null : id;
  }

  /// Eşleşen bekleyen stream id'sini tüketir.
  String? consumeFor(String streamId) {
    final id = streamId.trim();
    if (id.isEmpty || state != id) return null;
    state = null;
    return id;
  }

  void clear() => state = null;
}

final pendingCoBroadcastJoinProvider =
    NotifierProvider<PendingCoBroadcastJoinNotifier, String?>(
  PendingCoBroadcastJoinNotifier.new,
);
