import 'dart:async';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/sse/base_sse_service.dart';

/// Mesajlaşma SSE hazırlığı — üretim uç noktası eklendiğinde etkinleştirilir.
///
/// Şu an `BaseSseService` yaşam döngüsünü sağlar; event işleme hazır.
class MessageSseService extends BaseSseService {
  MessageSseService()
      : _events = StreamController<MessageSseEvent>.broadcast();

  final StreamController<MessageSseEvent> _events;
  Stream<MessageSseEvent> get events => _events.stream;

  String? _conversationId;

  void Function(MessageSseEvent event)? _onEvent;

  @override
  String streamPath() {
    final id = _conversationId ?? '';
    return ApiEndpoints.conversationStream(id);
  }

  Future<void> connectToConversation({
    required String conversationId,
    required Future<String?> Function() accessToken,
    Future<bool> Function()? refreshTokens,
    void Function(MessageSseEvent event)? onEvent,
  }) async {
    final id = conversationId.trim();
    if (id.isEmpty) return;
    _conversationId = id;
    _onEvent = onEvent;
    await super.openConnection(
      accessToken: accessToken,
      refreshTokens: refreshTokens,
    );
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
