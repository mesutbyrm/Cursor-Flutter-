import 'package:socket_io_client/socket_io_client.dart' as io;

/// Socket.IO — JWT + web/ mobil aynı oda kanalları.
abstract final class VoiceRoomSocketHelper {
  static io.OptionBuilder baseOptions({String? bearerToken}) {
    final builder = io.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .disableAutoConnect()
        .setTimeout(10000);
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      builder
        ..setAuth({'token': token})
        ..setExtraHeaders({'Authorization': 'Bearer $token'});
    }
    return builder;
  }

  static List<String> joinKeys({
    required String primary,
    String? alternate,
  }) {
    final out = <String>[];
    void add(String raw) {
      final t = raw.trim();
      if (t.isNotEmpty && !out.contains(t)) out.add(t);
    }

    add(primary);
    if (alternate != null) add(alternate);
    return out;
  }

  static void emitJoinRooms(io.Socket? socket, List<String> keys) {
    if (socket == null || keys.isEmpty) return;
    for (final roomId in keys) {
      socket.emit('joinRoom', {'roomId': roomId});
    }
  }
}
