import '../domain/entities/chat_room_message.dart';
import '../../live/domain/entities/live_stream_chat_message.dart';

/// PR #36–37 — `girlive_bot` SSE sohbet satırı.
abstract final class GirLiveBotSse {
  static const botUserId = 'girlive-bot';
  static const botDisplayName = 'GirLive Bot';

  static String messageIdFromPayload(Map<String, dynamic> payload) {
    final eid = payload['eventId'];
    if (eid != null && eid.toString().trim().isNotEmpty) {
      return 'girlive-bot-${eid.toString().trim()}';
    }
    final text = extractText(payload);
    return 'girlive-bot-${text.hashCode}';
  }

  static String extractText(Map<String, dynamic> payload) {
    return (payload['text'] ?? payload['message'] ?? payload['content'] ?? '')
        .toString()
        .trim();
  }

  static ChatRoomMessage toVoiceMessage(Map<String, dynamic> payload) {
    final text = extractText(payload);
    return ChatRoomMessage(
      id: messageIdFromPayload(payload),
      content: text,
      createdAt: DateTime.now(),
      user: const ChatRoomUserRef(id: botUserId, name: botDisplayName),
    );
  }

  static LiveStreamChatMessage toLiveMessage(Map<String, dynamic> payload) {
    final text = extractText(payload);
    return LiveStreamChatMessage(
      id: messageIdFromPayload(payload),
      content: text,
      createdAt: DateTime.now(),
      userId: botUserId,
      userName: botDisplayName,
      isSystem: false,
    );
  }
}
