import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/config/app_config.dart';

class RealtimeClient {
  RealtimeClient(this._config);

  final AppConfig _config;
  WebSocketChannel? _channel;

  Stream<dynamic> connect(String channel) {
    final Uri uri = Uri.parse('${_config.webSocketUrl}/$channel');
    _channel = WebSocketChannel.connect(uri);
    return _channel!.stream;
  }

  void send(Map<String, dynamic> payload) {
    _channel?.sink.add(jsonEncode(payload));
  }

  Future<void> dispose() async {
    await _channel?.sink.close();
  }
}
