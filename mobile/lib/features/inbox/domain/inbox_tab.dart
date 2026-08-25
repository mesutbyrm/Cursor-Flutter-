/// Gelen kutusu sekmeleri — TikTok tarzı birleşik mesaj + sistem bildirimi.
enum InboxTab {
  all,
  messages,
  system;

  String get label => switch (this) {
        InboxTab.all => 'Tümü',
        InboxTab.messages => 'Mesajlar',
        InboxTab.system => 'Sistem',
      };

  static InboxTab fromQuery(String? raw) {
    final v = raw?.trim().toLowerCase() ?? '';
    return switch (v) {
      'messages' || 'mesajlar' || 'dm' => InboxTab.messages,
      'system' || 'sistem' || 'notifications' || 'bildirimler' =>
        InboxTab.system,
      _ => InboxTab.all,
    };
  }

  String get queryValue => switch (this) {
        InboxTab.all => 'all',
        InboxTab.messages => 'messages',
        InboxTab.system => 'system',
      };
}
