/// Türkçe yayın türü etiketini API `category` alanına çevirir.
String liveStreamApiCategory({
  required String label,
  bool isFortune = false,
}) {
  if (isFortune) return 'fortune';
  final lower = label.trim().toLowerCase();
  if (lower == 'sohbet' ||
      lower == 'müzik' ||
      lower == 'muhabbet' ||
      lower.contains('chat')) {
    return 'chat';
  }
  return 'general';
}
