/// `GET /api/chat/rooms/{id}/moderation/violations` — GirLive Bot kaydı.
class VoiceRoomViolation {
  const VoiceRoomViolation({
    required this.id,
    required this.userId,
    required this.userLabel,
    required this.severity,
    required this.action,
    required this.createdAt,
    this.imageUrl,
    this.word,
    this.expiresAt,
  });

  final String id;
  final String userId;
  final String userLabel;
  final String? imageUrl;

  /// LOW | MEDIUM | HIGH | CRITICAL (tekrar ihlalde yükseltilmiş etkin seviye).
  final String severity;

  /// warn | mute | kick | ban
  final String action;
  final String? word;
  final DateTime createdAt;
  final DateTime? expiresAt;

  bool get isWarning => action == 'warn';

  String get actionLabel => switch (action) {
        'warn' => 'Uyarı',
        'mute' => 'Sessize alındı',
        'kick' => 'Odadan atıldı',
        'ban' => 'Banlandı',
        _ => action,
      };

  factory VoiceRoomViolation.fromJson(Map<String, dynamic> json) {
    final u = json['user'];
    final user = u is Map ? Map<String, dynamic>.from(u) : const <String, dynamic>{};
    final username = user['username']?.toString().trim() ?? '';
    final name = user['name']?.toString().trim() ?? '';
    return VoiceRoomViolation(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? user['id']?.toString() ?? '',
      userLabel: username.isNotEmpty ? '@$username' : (name.isNotEmpty ? name : 'Kullanıcı'),
      imageUrl: user['image']?.toString(),
      severity: json['severity']?.toString() ?? 'LOW',
      action: json['action']?.toString() ?? 'warn',
      word: json['word']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '')?.toLocal(),
    );
  }
}
