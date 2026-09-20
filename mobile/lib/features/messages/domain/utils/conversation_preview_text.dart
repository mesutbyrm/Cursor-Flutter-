import 'dm_message_codec.dart';

/// Gelen kutusu önizleme metni — sohbet balonu ile aynı decode.
String? conversationPreviewText(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  if (DmMessageCodec.parseCallSignal(trimmed) != null) {
    return 'Sesli arama';
  }
  if (DmMessageCodec.isSystemPayload(trimmed)) {
    final parsed = DmMessageCodec.parseDisplay(trimmed);
    if (parsed.displayText.isNotEmpty) return parsed.displayText;
    if (parsed.forwardedFrom != null) return 'İletilen mesaj';
    if (parsed.reply != null) return 'Yanıt';
  }
  final parsed = DmMessageCodec.parseDisplay(trimmed);
  final text = parsed.displayText.trim();
  return text.isNotEmpty ? text : trimmed;
}
