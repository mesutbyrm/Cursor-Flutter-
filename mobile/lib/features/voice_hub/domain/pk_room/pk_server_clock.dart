/// Sunucu saatine göre "şimdi" — PK sayacının TEK zaman kaynağı.
///
/// Cihaz saati iki telefonda farklı olabilir. Her API/SSE yanıtındaki
/// `serverNow` ile `offset = serverNow - cihazSaati` hesaplanır ve
/// `now() = DateTime.now() + offset` kullanılır → iki cihaz aynı `endsAt`'a
/// aynı kalanı görür.
///
/// Gecikme (ağ) `serverNow`'ı "eski" gösterir (offset olduğundan küçük çıkar).
/// Bu yüzden son [window] içindeki örneklerin **en büyük** offset'i seçilir
/// (en düşük gecikmeli örnek).
class PkServerClock {
  PkServerClock({
    DateTime Function()? deviceNow,
    this.window = const Duration(minutes: 2),
  }) : _deviceNow = deviceNow ?? DateTime.now;

  final DateTime Function() _deviceNow;
  final Duration window;
  final List<({DateTime at, Duration offset})> _samples = [];

  /// Henüz örnek yoksa true (offset 0 varsayılır).
  bool get isSynced => _samples.isNotEmpty;

  Duration get offset {
    if (_samples.isEmpty) return Duration.zero;
    var best = _samples.first.offset;
    for (final s in _samples) {
      if (s.offset > best) best = s.offset;
    }
    return best;
  }

  /// [serverNow] sunucunun yanıtta bildirdiği an; [receivedAt] yanıtın cihaza
  /// ulaştığı an (varsayılan: şimdi).
  void observe(DateTime serverNow, {DateTime? receivedAt}) {
    final recv = (receivedAt ?? _deviceNow()).toUtc();
    final sample = serverNow.toUtc().difference(recv);
    _samples.add((at: recv, offset: sample));
    final cutoff = recv.subtract(window);
    _samples.removeWhere((s) => s.at.isBefore(cutoff));
    // Sınırsız büyümeyi engelle.
    if (_samples.length > 64) {
      _samples.removeRange(0, _samples.length - 64);
    }
  }

  /// `serverNow` metni (ISO-8601). Geçersizse yok sayılır.
  bool observeIso(String? iso, {DateTime? receivedAt}) {
    final s = iso?.trim() ?? '';
    if (s.isEmpty) return false;
    final parsed = DateTime.tryParse(s);
    if (parsed == null) return false;
    observe(parsed, receivedAt: receivedAt);
    return true;
  }

  /// Sunucu zamanında "şimdi" (UTC).
  DateTime now() => _deviceNow().toUtc().add(offset);

  void reset() => _samples.clear();
}
