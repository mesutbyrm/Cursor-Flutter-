import 'package:livekit_client/livekit_client.dart' as livekit;

class LiveRtcService {
  livekit.Room? _room;

  Future<void> connect({required String url, required String token}) async {
    if (url.isEmpty || token.isEmpty) {
      return;
    }
    final livekit.Room room = livekit.Room();
    await room.connect(url, token);
    _room = room;
  }

  Future<void> disconnect() async {
    await _room?.disconnect();
    _room = null;
  }
}
