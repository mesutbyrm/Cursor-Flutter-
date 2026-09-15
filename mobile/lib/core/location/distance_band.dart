/// Yaklaşık mesafe — kesin koordinat veya adres istemciye gönderilmez (§26–28, §48).
abstract final class DistanceBand {
  static const List<(double minKm, double maxKm, String labelTr)> bands = [
    (0, 1, '0–1 km'),
    (1, 5, '1–5 km'),
    (5, 10, '5–10 km'),
    (10, 25, '10–25 km'),
    (25, 50, '25–50 km'),
    (50, double.infinity, '50+ km'),
  ];

  /// Sunucudan gelen km değerini bant etiketine çevirir.
  static String? labelFromKm(num? km, {bool hidden = false}) {
    if (hidden) return null;
    if (km == null) return null;
    final v = km.toDouble();
    if (v.isNaN || v < 0) return null;
    for (final (min, max, label) in bands) {
      if (v >= min && v < max) return label;
    }
    return bands.last.$3;
  }

  /// Kullanıcıya gösterilecek tam cümle.
  static String? displayLabel(num? km, {bool hidden = false}) {
    if (hidden) return 'Mesafe bilgisi gizli';
    final band = labelFromKm(km, hidden: false);
    if (band == null) return null;
    if (band == '0–1 km') return 'Yaklaşık 1 km uzakta';
    return 'Yaklaşık $band uzakta';
  }

  /// Ham km yerine sunucunun gönderdiği bant anahtarı (ör. `band_5_10`).
  static String? labelFromBandKey(String? key, {bool hidden = false}) {
    if (hidden) return 'Mesafe bilgisi gizli';
    if (key == null || key.trim().isEmpty) return null;
    final k = key.trim().toLowerCase();
    for (final (_, _, label) in bands) {
      final normalized = label.replaceAll(' ', '').replaceAll('–', '_');
      if (k.contains(normalized.toLowerCase())) return 'Yaklaşık $label uzakta';
    }
    switch (k) {
      case 'hidden':
      case 'private':
        return 'Mesafe bilgisi gizli';
      default:
        return null;
    }
  }
}
