import '../../live/domain/entities/voice_room_entity.dart';

/// Oda erişim meta — VIP / şifreli oda algılama.
extension VoiceRoomAccess on VoiceRoomEntity {
  String get _haystack =>
      '${nameTr.toLowerCase()} ${slug.toLowerCase()} ${descTr?.toLowerCase() ?? ''}';

  bool get isVipGoldRoom {
    final t = _haystack;
    return t.contains('vip') ||
        t.contains('gold') ||
        t.contains('elit') ||
        t.contains('premium oda');
  }

  bool get isPasswordLockedRoom {
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
