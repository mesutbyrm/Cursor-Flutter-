/// Sesli oda kategorileri — keşfet filtresi ve `PATCH /settings` ile uyumlu.
class VoiceRoomCategoryOption {
  const VoiceRoomCategoryOption({required this.id, required this.label});

  final String id;
  final String label;
}

/// Oda oluşturma / düzenlemede seçilebilir kategoriler (`all` / `popular` hariç).
const kVoiceRoomAssignableCategories = <VoiceRoomCategoryOption>[
  VoiceRoomCategoryOption(id: 'chat', label: 'Sohbet'),
  VoiceRoomCategoryOption(id: 'music', label: 'Müzik'),
  VoiceRoomCategoryOption(id: 'love', label: 'Aşk'),
  VoiceRoomCategoryOption(id: 'game', label: 'Oyun'),
  VoiceRoomCategoryOption(id: 'night', label: 'Gece'),
];

const kDefaultVoiceRoomCategory = 'chat';

String voiceRoomCategoryLabel(String? id) {
  final needle = id?.trim().toLowerCase() ?? '';
  if (needle.isEmpty) return 'Belirtilmemiş';
  for (final c in kVoiceRoomAssignableCategories) {
    if (c.id == needle) return c.label;
  }
  return needle;
}

String normalizeVoiceRoomCategory(String? raw) {
  final needle = raw?.trim().toLowerCase() ?? '';
  if (needle.isEmpty) return kDefaultVoiceRoomCategory;
  for (final c in kVoiceRoomAssignableCategories) {
    if (c.id == needle) return c.id;
  }
  return kDefaultVoiceRoomCategory;
}
