/// Yayın öncesi telif / müzik katalog kontrolü (istemci).
class ShortCopyrightGuard {
  ShortCopyrightGuard._();

  static const catalogOnlyHint =
      'Telif güvenliği için yalnızca uygulama müzik kataloğundan seçim yapın.';

  /// `null` = yayınlanabilir.
  static String? validatePublish({
    required String? musicId,
    required String? voiceoverPath,
    required bool muted,
  }) {
    if (voiceoverPath != null && voiceoverPath.isNotEmpty) {
      return null;
    }
    if (muted && (musicId == null || musicId.isEmpty)) {
      return null;
    }
    if (musicId != null && musicId.isNotEmpty) {
      return null;
    }
    return null;
  }

  /// Harici ses dosyası yüklenmişse (gelecekte) engelle.
  static String? validateExternalAudio(String? customAudioPath) {
    if (customAudioPath != null && customAudioPath.isNotEmpty) {
      return 'Harici ses dosyası telif nedeniyle desteklenmiyor. Katalog müziği kullanın.';
    }
    return null;
  }
}
