import 'voice_room_permissions.dart';

/// Faz 10 — `!duyuru` komutu: admin ücretsiz, diğerleri 5 jeton, max 100 karakter.
abstract final class VoiceRoomDuyuruAccess {
  static const int maxLength = 100;
  static const int jetonCost = 5;
  /// 0 = otomatik gizleme yok (Faz 10).
  static const Duration displayTtl = Duration.zero;
  static const int scrollPasses = 2;

  static bool isAdminFree(VoiceRoomPermissions perms) =>
      perms.isSiteAdmin || perms.canModerate || perms.isRoomOwner;

  static bool canAfford({
    required VoiceRoomPermissions perms,
    required int jetonBalance,
  }) =>
      isAdminFree(perms) || jetonBalance >= jetonCost;

  static String? parseCommand(String trimmed) {
    final t = trimmed.trim();
    if (t.length < 2) return null;
    if (!t.toLowerCase().startsWith('!duyuru') &&
        !t.toLowerCase().startsWith('/duyuru')) {
      return null;
    }
    return t
        .replaceFirst(RegExp(r'^[!/]duyuru\s*', caseSensitive: false), '')
        .trim();
  }

  static String? validateMessage(String message) {
    final text = message.trim();
    if (text.isEmpty) return 'Kullanım: !duyuru mesajınız';
    if (text.length > maxLength) {
      return 'Duyuru en fazla $maxLength karakter olabilir.';
    }
    return null;
  }

  static String costLabel(VoiceRoomPermissions perms) =>
      isAdminFree(perms) ? 'Ücretsiz (yetkili)' : '$jetonCost jeton';
}
