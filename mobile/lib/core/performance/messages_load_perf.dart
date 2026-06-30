/// Görev 16 — mesajlar cache-first açılış + arka plan güncelleme.
abstract final class MessagesLoadPerf {
  static const conversationsMaxAge = Duration(minutes: 5);
  static const threadMaxAge = Duration(seconds: 45);

  static String conversationsKey(String userId) =>
      'messages_conversations_v1_${userId.trim().isEmpty ? 'anon' : userId}';

  static String threadKey(String userId, String conversationId) =>
      'messages_thread_v1_${userId.trim().isEmpty ? 'anon' : userId}_$conversationId';
}
