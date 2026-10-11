import '../domain/entities/chat_room_message.dart';
import '../../live/domain/entities/live_stream_chat_message.dart';

/// PR #36–37 — `girlive_bot` SSE sohbet satırı.
abstract final class GirLiveBotSse {
  static const botUserId = 'girlive-bot';
  static const botDisplayName = 'GirLive Bot';

  static bool isBotEventType(String? type) {
    final t = type?.toLowerCase().trim() ?? '';
    return t == 'girlive_bot' || t == 'girlivebot';
  }

  /// SSE sarmalayıcı (`room_event`, `stream_signal`) içindeki bot yükü.
  static Map<String, dynamic>? unwrapPayload(Map<String, dynamic> outer) {
    if (isBotEventType(outer['type']?.toString()) &&
        extractText(outer).isNotEmpty) {
      return outer;
    }
    if (isBotEventType(outer['event']?.toString()) &&
        extractText(outer).isNotEmpty) {
      return outer;
    }
    for (final key in ['payload', 'data', 'signal', 'message']) {
      final inner = outer[key];
      if (inner is! Map) continue;
      final m = Map<String, dynamic>.from(inner);
      if (isBotEventType(m['type']?.toString()) ||
          isBotEventType(m['event']?.toString())) {
        if (extractText(m).isNotEmpty) return m;
      }
    }
    return null;
  }

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
