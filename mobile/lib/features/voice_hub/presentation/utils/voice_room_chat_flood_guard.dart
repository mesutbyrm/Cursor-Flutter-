/// Oda sohbeti flood / spam koruması (istemci tarafı).
class VoiceRoomChatFloodGuard {
  VoiceRoomChatFloodGuard({
    this.minIntervalMs = 1200,
    this.windowSeconds = 10,
    this.maxMessagesInWindow = 8,
    this.duplicateWindowSeconds = 30,
  });

  final int minIntervalMs;
  final int windowSeconds;
  final int maxMessagesInWindow;
  final int duplicateWindowSeconds;

  DateTime? _lastSendAt;
  final List<DateTime> _recentSends = [];

  static const floodFastMessage = 'Çok hızlı gönderiyorsunuz. Biraz bekleyin.';
  static const floodWindowMessage =
      'Mesaj limiti aşıldı. Lütfen biraz bekleyin.';
  static const duplicateMessage = 'Aynı mesajı tekrar gönderemezsiniz.';

  static bool isFloodMessage(String? message) {
    if (message == null || message.trim().isEmpty) return false;
    return message == floodFastMessage ||
        message == floodWindowMessage ||
        message == duplicateMessage;
  }

  /// Flood banner geri sayım süresi.
  Duration cooldownForMessage(String message) {
    if (message == floodWindowMessage) {
      return Duration(seconds: windowSeconds);
    }
    return Duration(milliseconds: minIntervalMs);
  }

  /// `null` = gönderime izin ver; aksi halde kullanıcıya gösterilecek hata metni.
  String? tryAcquire() {
    final now = DateTime.now();
    if (_lastSendAt != null) {
      final gap = now.difference(_lastSendAt!).inMilliseconds;
      if (gap < minIntervalMs) {
        return floodFastMessage;
      }
    }
    final window = Duration(seconds: windowSeconds);
    _recentSends.removeWhere((t) => now.difference(t) > window);
    if (_recentSends.length >= maxMessagesInWindow) {
      return floodWindowMessage;
    }
    _lastSendAt = now;
    _recentSends.add(now);
    return null;
  }

  /// Son mesajlarla aynı içerik tekrarını engelle.
  bool isDuplicateContent({
    required String content,
    required String? userId,
    required Iterable<({String content, String? userId, DateTime createdAt})> recent,
  }) {
    if (userId == null || userId.isEmpty) return false;
    final normalized = content.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    final cutoff = DateTime.now().subtract(Duration(seconds: duplicateWindowSeconds));
    for (final m in recent) {
      if (m.userId != userId) continue;
      if (m.createdAt.isBefore(cutoff)) continue;
      if (m.content.trim().toLowerCase() == normalized) return true;
    }
    return false;
  }

  void reset() {
    _lastSendAt = null;
    _recentSends.clear();
  }
}
