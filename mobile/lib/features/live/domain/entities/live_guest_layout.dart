/// Misafir modu — yayın grid düzeni (2 / 4 / 6 / 9 kişi).
enum LiveGuestLayout {
  solo(1, 'Tek kişi', 1),
  duo(2, '2 kişi', 1),
  quad(4, '4\'lü yayın', 2),
  sextet(6, '6\'lı yayın', 2),
  nonet(9, '9\'lu yayın', 3);

  const LiveGuestLayout(this.seats, this.label, this.crossAxisCount);

  final int seats;
  final String label;
  final int crossAxisCount;

  /// Eski trio uyumluluğu → quad.
  static LiveGuestLayout fromLegacy(String? raw) {
    if (raw == null) return solo;
    return switch (raw.toLowerCase()) {
      'duo' || '2' => duo,
      'quad' || '4' || 'trio' || '3' => quad,
      'sextet' || '6' => sextet,
      'nonet' || '9' => nonet,
      _ => solo,
    };
  }
}
