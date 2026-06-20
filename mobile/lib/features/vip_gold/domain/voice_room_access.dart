import '../../live/domain/entities/voice_room_entity.dart';

/// Oda erişim meta — VIP / şifreli oda algılama.
extension VoiceRoomAccess on VoiceRoomEntity {
  String get _haystack =>
      '${nameTr.toLowerCase()} ${slug.toLowerCase()} ${descTr?.toLowerCase() ?? ''}';

  bool get isVipGoldRoom {
    if (isFreeRoom) return false;
    if (isVip == true) return true;
    final type = roomType?.toLowerCase().trim();
    if (type == 'vip' || type == 'gold' || type == 'premium') return true;
    final t = _haystack;
    return t.contains('vip') ||
        t.contains('gold') ||
        t.contains('elit') ||
        t.contains('premium oda');
  }

  /// Ücretsiz oda — hediye/müzik geliri oda sahibine gitmez.
  bool get isFreeRoom {
    final type = roomType?.toUpperCase().trim();
    return type == 'FREE' || type == 'ÜCRETSİZ' || type == 'UCRETSIZ';
  }

  /// NORMAL | FREE | VIP
  String get resolvedRoomType {
    if (isFreeRoom) return 'FREE';
    if (isVipGoldRoom) return 'VIP';
    return 'NORMAL';
  }

  bool get isPasswordLockedRoom {
    if (isFreeRoom) return false;
    final t = _haystack;
    return t.contains('şifre') ||
        t.contains('sifre') ||
        t.contains('password') ||
        t.contains('kilitli') ||
        t.contains('locked') ||
        t.contains('private');
  }

  /// Demo şifre — API yokken yerel doğrulama.
  String get demoPassword => 'gold2026';
}
