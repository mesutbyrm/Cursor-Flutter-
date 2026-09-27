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

  /// Üretimde yalnızca `/api/messages/conversations/{id}/stream` var;
  /// `/api/messages/{userId}/stream` 404 dönüyordu ve 404'te yeniden
  /// bağlanma kapalı olduğu için DM'ler gerçek zamanlı gelmiyordu.
  /// Önce konuşma yolu denenir, 404 alınırsa diğerine bir kez düşülür.
  bool _useUserScopedPath = false;
  bool _triedUserScopedPath = false;

  @override
  bool shouldReconnectOnHttpError(int? statusCode) {
    if (statusCode != 404) return true;
    if (!_useUserScopedPath && !_triedUserScopedPath) {
      _useUserScopedPath = true;
      _triedUserScopedPath = true;
      return true; // alternatif yolla yeniden dene
    }
    return false;
  }

  @override
  String streamPath() {
    final id = _conversationId ?? '';
    if (_useUserScopedPath) {
      return ApiEndpoints.messagesStreamWithUser(id);
    }
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
    _useUserScopedPath = false;
    _triedUserScopedPath = false;
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
