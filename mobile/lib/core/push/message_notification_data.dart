/// FCM/OneSignal `data` alanından direkt mesaj bildirimi verisi.
///
/// Backend şu an mesaj push'unda yalnızca `type`, `targetPath` (`/chat/{id}`),
/// `targetId` ve başlık/gövde ("Ad size bir mesaj gönderdi") yollar; mesaj metni
/// ve avatar isteğe bağlı alanlardır (`senderName`, `senderAvatar`, `message`).
/// Eksikler [MessageNotificationData] içinde null kalır — uydurulmaz.
class MessageNotificationData {
  const MessageNotificationData({
    required this.senderId,
    required this.senderName,
    this.avatarUrl,
    this.text,
    required this.targetPath,
  });

  final String senderId;
  final String senderName;
  final String? avatarUrl;

  /// Mesaj metni — yoksa null (genel "yeni mesaj" metni gösterilir).
  final String? text;

  /// Dokununca gidilecek yol — `/chat/{senderId}`.
  final String targetPath;

  static String? _s(Object? v) {
    final t = v?.toString().trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  /// Mesaj bildirimi mi? (tür veya sohbet alanlarından)
  static bool isMessageData(Map<String, dynamic> data) {
    final type = (data['type']?.toString() ?? '').toLowerCase();
    if (type.contains('message') || type.contains('chat') || type == 'dm') {
      return true;
    }
    final path = _s(data['targetPath']) ?? '';
    return path.startsWith('/chat/') ||
        data['conversationId'] != null ||
        (data['senderId'] != null && type.isEmpty);
  }

  /// [fallbackTitle]/[fallbackBody] bildirimin başlığı/gövdesidir
  /// (`"Ahmet size bir mesaj gönderdi"` → gönderen adı gövdeden çıkarılır).
  static MessageNotificationData? tryParse(
    Map<String, dynamic> data, {
    String? fallbackTitle,
    String? fallbackBody,
  }) {
    if (!isMessageData(data)) return null;

    final path = _s(data['targetPath']);
    var senderId = _s(data['senderId']) ??
        _s(data['fromUserId']) ??
        _s(data['targetId']);
    if (senderId == null && path != null && path.startsWith('/chat/')) {
      senderId = path.substring('/chat/'.length).split(RegExp(r'[/?#]')).first;
    }
    if (senderId == null || senderId.isEmpty) return null;

    var name = _s(data['senderName']) ??
        _s(data['fromUserName']) ??
        _s(data['fromName']);
    final body = _s(data['message']) ?? _s(data['body']) ?? fallbackBody;
    String? text = _s(data['text']) ?? _s(data['content']);

    // "<Ad> size bir mesaj gönderdi" kalıbından ad çıkar (backend gövdesi).
    const suffix = ' size bir mesaj gönderdi';
    if (name == null && body != null && body.contains(suffix)) {
      name = body.split(suffix).first.trim();
    }
    if (text == null &&
        body != null &&
        !body.contains(suffix) &&
        _s(data['message']) != null) {
      text = body;
    }

    return MessageNotificationData(
      senderId: senderId,
      senderName: name ?? fallbackTitle?.trim() ?? 'Yeni mesaj',
      avatarUrl: _s(data['senderAvatar']) ??
          _s(data['fromUserImage']) ??
          _s(data['avatar']) ??
          _s(data['image']),
      text: text,
      targetPath: path ?? '/chat/$senderId',
    );
  }

  /// Aynı kişiden gelen bildirimler tek bildirimde birleşsin.
  int get notificationId => 71000 + (senderId.hashCode & 0x0FFFFF);
}
