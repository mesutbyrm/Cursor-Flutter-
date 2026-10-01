/// PK sırasında görünen hediye kartı verisi.
class PkGiftToast {
  const PkGiftToast({
    required this.id,
    required this.senderName,
    required this.giftName,
    required this.amount,
    this.senderAvatarUrl,
    this.giftImageUrl,
    this.side = 0,
    this.quantity = 1,
  });

  final String id;
  final String senderName;
  final String giftName;

  /// Jeton tutarı (toplam).
  final int amount;
  final String? senderAvatarUrl;
  final String? giftImageUrl;

  /// 1/2 = hediyeyi alan takım, 0 = bilinmiyor.
  final int side;
  final int quantity;
}

/// Son N hediye kuyruğu (saf mantık; zamanlayıcı dışarıdan sürülür).
///
/// Kural: ekranda aynı anda TEK kart; bekleyenler sıradadır. Toplam
/// (görünen + bekleyen) [capacity]'yi aşarsa **en eski bekleyen** düşer
/// ("son 3 hediye").
class PkGiftQueueCore {
  PkGiftQueueCore({this.capacity = 3});

  final int capacity;
  PkGiftToast? _current;
  final List<PkGiftToast> _pending = [];
  final Set<String> _seen = {};

  PkGiftToast? get current => _current;
  List<PkGiftToast> get pending => List.unmodifiable(_pending);
  int get length => (_current == null ? 0 : 1) + _pending.length;

  /// Aynı `id` iki kez eklenmez (SSE + REST çift teslim). `true`: eklendi.
  bool add(PkGiftToast toast) {
    if (toast.id.isNotEmpty && !_seen.add(toast.id)) return false;
    if (_seen.length > 64) {
      _seen.remove(_seen.first);
    }
    _pending.add(toast);
    while (length > capacity && _pending.isNotEmpty) {
      // Görünen kart kesilmez; en eski BEKLEYEN düşer.
      _pending.removeAt(0);
    }
    _promote();
    return true;
  }

  void _promote() {
    if (_current == null && _pending.isNotEmpty) {
      _current = _pending.removeAt(0);
    }
  }

  /// Görünen kartın süresi doldu: sıradakine geç. Yeni görünen kartı döner.
  PkGiftToast? advance() {
    _current = null;
    _promote();
    return _current;
  }

  void clear() {
    _current = null;
    _pending.clear();
    _seen.clear();
  }
}
