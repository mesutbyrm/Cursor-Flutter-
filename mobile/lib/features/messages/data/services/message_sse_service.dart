import 'dart:async';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/sse/base_sse_service.dart';
import '../../../../core/network/sse/sse_reconnect_policy.dart';

/// Mesajlaşma SSE — üretim uç noktası yoksa 404'te poll-only kalır.
class MessageSseService extends BaseSseService {
  MessageSseService()
      : _events = StreamController<MessageSseEvent>.broadcast();

  final StreamController<MessageSseEvent> _events;
  Stream<MessageSseEvent> get events => _events.stream;

  String? _conversationId;

  void Function(MessageSseEvent event)? _onEvent;

  @override
  bool shouldReconnectOnHttpError(int? statusCode) => statusCode != 404;

  @override
  String streamPath() {
    final id = _conversationId ?? '';
    return ApiEndpoints.conversationStream(id);
  }

  Future<bool> connectToConversation({
    required String conversationId,
    required Future<String?> Function() accessToken,
    Future<bool> Function()? refreshTokens,
    void Function(MessageSseEvent event)? onEvent,
  }) async {
    final id = conversationId.trim();
    if (id.isEmpty) return false;
    _conversationId = id;
    _onEvent = onEvent;
    try {
      await super.openConnection(
        accessToken: accessToken,
        refreshTokens: refreshTokens,
      );
      return status.value.phase == SseConnectionPhase.connected;
    } catch (_) {
      return false;
    }
  }

  @override
  void onSseBlock(String block) {
    final map = BaseSseService.parseSseJsonBlock(block);
    if (map == null) return;
    final event = MessageSseEvent.fromJson(map);
    if (!_events.isClosed) _events.add(event);
    _onEvent?.call(event);
  }

  @override
  Future<void> disconnect() async {
    _conversationId = null;
    _onEvent = null;
    await super.disconnect();
  }

  @override
  void dispose() {
    unawaited(disconnect());
    _events.close();
    super.dispose();
  }
}

class MessageSseEvent {
  const MessageSseEvent({
    required this.type,
    this.conversationId,
    this.messageId,
    this.senderId,
    this.content,
    this.raw = const {},
  });

  final String type;
  final String? conversationId;
  final String? messageId;
  final String? senderId;
  final String? content;
  final Map<String, dynamic> raw;

  factory MessageSseEvent.fromJson(Map<String, dynamic> json) {
    return MessageSseEvent(
      type: (json['type'] ?? 'message').toString(),
      conversationId: json['conversationId']?.toString(),
      messageId: json['messageId']?.toString() ?? json['id']?.toString(),
      senderId: json['senderId']?.toString(),
      content: json['content']?.toString() ?? json['text']?.toString(),
      raw: json,
    );
  }
}
