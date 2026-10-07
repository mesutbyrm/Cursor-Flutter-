/// Premium+ geçici mesaj sabitleme — `POST /api/chat/rooms/{id}/pin-message`
/// sonrası sunucu `system` SSE olayı `{event: VIP_PIN, text, ttl}` yayınlar.
class VoiceVipPin {
  const VoiceVipPin({required this.text, required this.ttl});

  final String text;
  final Duration ttl;

  static const defaultTtl = Duration(seconds: 60);
  static const maxTtl = Duration(seconds: 600);

  static VoiceVipPin? fromPayload(Map<String, dynamic> payload) {
    final text = payload['text']?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    final raw = payload['ttl'];
    final secs = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}');
    var ttl = secs != null && secs > 0 ? Duration(seconds: secs) : defaultTtl;
    if (ttl > maxTtl) ttl = maxTtl;
    return VoiceVipPin(text: text, ttl: ttl);
  }
}
