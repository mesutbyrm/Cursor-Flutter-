/// Android geri tuşu politikası (saf mantık — test edilebilir).
///
/// Amaç: geri tuşu hiçbir yerde uygulamayı doğrudan kapatmasın. Navigator
/// yığınında önceki sayfa varsa ona döner; yığın boşsa (`context.go()` ile
/// gelinmiş sayfa) mantıklı bir üst sayfaya, ana sayfada ise çıkış onayına gider.
abstract final class AppBackPolicy {
  /// Alt navigasyondaki sekme kökleri (bunlar kendi geri mantığını kullanır).
  static const tabRoots = <String>[
    '/feed',
    '/social',
    '/live',
    '/fortune',
    '/profile',
    '/voice-rooms',
  ];

  /// Geri tuşunu KENDİ yöneten sayfalar (PopScope + onay diyaloğu vb.).
  /// [AppBackScope] bunlara karışmaz.
  static const selfHandledPrefixes = <String>[
    '/voice-room/', // sesli oda: "çıkmak istiyor musunuz?"
    '/live/room', // canlı yayın izle/yayınla
    '/live/broadcast',
    '/canli-falcilar/', // falcı oturumu/bekleme/reklam
    '/admin-web',
  ];

  static String _path(String location) {
    final uri = Uri.tryParse(location);
    final p = uri?.path ?? location;
    if (p.length > 1 && p.endsWith('/')) return p.substring(0, p.length - 1);
    return p;
  }

  static bool isTabRoot(String location) {
    final p = _path(location);
    return tabRoots.contains(p);
  }

  /// Sekme köküne ait (alt) yol mu? (`/profile/edit` gibi — shell içi dallar.)
  static bool isUnderTabRoot(String location) {
    final p = _path(location);
    for (final r in tabRoots) {
      if (p == r || p.startsWith('$r/')) return true;
    }
    return false;
  }

  static bool selfHandlesBack(String location) {
    final p = _path(location);
    if (isTabRoot(p)) return true;
    for (final prefix in selfHandledPrefixes) {
      if (p == prefix.replaceAll(RegExp(r'/$'), '') || p.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }

  /// Yığın boşken geri tuşunun gideceği yer.
  /// `null` → ana sayfadayız: çıkış onayı göster.
  static String? fallbackFor(String location) {
    final p = _path(location);
    if (p.isEmpty || p == '/' || p == '/feed') return null;
    // Sekme kökü → ana sayfa.
    if (isTabRoot(p)) return '/feed';
    // Derin yol → ilk segmentin sekme/bölüm kökü (varsa), yoksa ana sayfa.
    final segs = p.split('/').where((s) => s.isNotEmpty).toList();
    if (segs.length >= 2) {
      final parent = '/${segs.first}';
      if (tabRoots.contains(parent)) return parent;
    }
    return '/feed';
  }
}
