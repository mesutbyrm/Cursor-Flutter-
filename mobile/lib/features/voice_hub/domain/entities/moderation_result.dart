/// `POST /api/chat/rooms/{roomId}/moderation` — kick yanıtı.
class ModerationKickResult {
  const ModerationKickResult({
    this.kickCount = 0,
    this.autoBanned = false,
  });

  factory ModerationKickResult.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const ModerationKickResult();
    final rawCount = json['kickCount'] ?? json['kicks'] ?? json['strikeCount'];
    final count = rawCount is int
        ? rawCount
        : int.tryParse(rawCount?.toString() ?? '') ?? 0;
    return ModerationKickResult(
      kickCount: count,
      autoBanned: json['autoBanned'] == true || json['banned'] == true,
    );
  }

  final int kickCount;
  final bool autoBanned;

  String get feedbackMessage {
    if (autoBanned) {
      return kickCount > 0
          ? 'Kullanıcı atıldı ($kickCount. uyarı) — 30 dk içinde otomatik banlandı'
          : 'Kullanıcı otomatik banlandı';
    }
    if (kickCount > 0) {
      return 'Kullanıcı atıldı ($kickCount/3 uyarı)';
    }
    return 'Kullanıcı odadan atıldı';
  }
}

/// `DELETE /api/chat/rooms/{roomId}/music` — auto-advance yanıtı.
class MusicClearResult {
  const MusicClearResult({this.autoAdvanced = false});

  factory MusicClearResult.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MusicClearResult();
    return MusicClearResult(autoAdvanced: json['autoAdvanced'] == true);
  }

  final bool autoAdvanced;
}
