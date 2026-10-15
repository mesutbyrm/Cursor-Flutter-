import 'package:intl/intl.dart';

/// Sunucudan gelen ham (çoğu İngilizce) değerlerin Türkçe karşılıkları.
/// Cüzdan, para çekme, jeton/işlem geçmişi, hediye geçmişi ve Sakladıklarım
/// ekranları ham `type` / `status` / ISO tarih / hediye adını doğrudan
/// gösteriyordu.
abstract final class TrLabels {
  static String _norm(String? raw) =>
      (raw ?? '').trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

  /// Cüzdan / jeton işlem türü.
  static String transactionType(String? raw) {
    final t = _norm(raw);
    return switch (t) {
      'spend' || 'spent' => 'Harcama',
      'daily_bonus' || 'daily_reward' || 'daily_login' => 'Günlük bonus',
      'streak_bonus' || 'streak' => 'Seri bonusu',
      'task' || 'task_reward' || 'mission' => 'Görev ödülü',
      'purchase' || 'topup' || 'top_up' || 'deposit' => 'Jeton yükleme',
      'welcome' || 'welcome_bonus' || 'signup_bonus' => 'Hoş geldin bonusu',
      'gift_sent' || 'gift_send' || 'gift' => 'Gönderilen hediye',
      'gift_received' || 'gift_receive' => 'Alınan hediye',
      'gift_commission' || 'commission' => 'Hediye komisyonu',
      'lucky_gift_bet' || 'lucky_gift' => 'Şans hediyesi',
      'lucky_gift_win' => 'Şans hediyesi kazancı',
      'fortune' || 'fortune_payment' => 'Fal ücreti',
      'stream' || 'stream_earning' || 'live' => 'Yayın kazancı',
      'reward' || 'bonus' => 'Ödül',
      'referral' || 'referral_bonus' || 'invite' => 'Davet ödülü',
      'withdrawal' || 'withdraw' || 'payout' => 'Para çekme',
      'refund' => 'İade',
      'transfer_in' => 'Gelen transfer',
      'transfer_out' => 'Giden transfer',
      'transfer' => 'Transfer',
      'admin_adjust' || 'admin' || 'adjustment' => 'Yönetici düzeltmesi',
      'ad_reward' || 'ad' => 'Reklam ödülü',
      'membership' || 'subscription' => 'Üyelik',
      'tip' => 'Bahşiş',
      'call' || 'video_call' => 'Görüntülü görüşme',
      '' => 'İşlem',
      _ => _humanize(raw!),
    };
  }

  /// Ödeme / talep / işlem durumu.
  static String status(String? raw) {
    final s = _norm(raw);
    return switch (s) {
      'pending' || 'beklemede' || 'waiting' => 'Onay bekliyor',
      'approved' || 'onaylandi' || 'onaylandı' || 'accepted' => 'Onaylandı',
      'rejected' || 'reddedildi' || 'declined' => 'Reddedildi',
      'cancelled' || 'canceled' => 'İptal edildi',
      'expired' => 'Süresi doldu',
      'completed' || 'complete' || 'success' || 'succeeded' => 'Tamamlandı',
      'paid' || 'odendi' || 'ödendi' => 'Ödendi',
      'processing' => 'İşleniyor',
      'in_review' || 'under_review' || 'reviewing' => 'İnceleniyor',
      'agency_approved' => 'Ajans onayladı · yönetici onayı bekleniyor',
      'agency_rejected' => 'Ajans reddetti',
      'failed' || 'error' => 'Başarısız',
      'on_hold' => 'Beklemeye alındı',
      'refunded' => 'İade edildi',
      'read' => 'Okundu',
      'unread' => 'Yeni',
      '' => '',
      _ => _humanize(raw!),
    };
  }

  /// Ödeme yöntemi.
  static String paymentMethod(String? raw) {
    final m = _norm(raw);
    return switch (m) {
      'credit_card' || 'card' || 'kredi_karti' => 'Kredi kartı',
      'bank_transfer' || 'havale' || 'eft' || 'bank' => 'Havale / EFT',
      'iyzico' => 'iyzico',
      'paytr' => 'PayTR',
      'shopier' => 'Shopier',
      'google_play' || 'play' => 'Google Play',
      'app_store' || 'apple' => 'App Store',
      '' => 'Diğer',
      _ => _humanize(raw!),
    };
  }

  /// Sakladıklarım içerik türü.
  static String contentType(String? raw) {
    final t = _norm(raw);
    return switch (t) {
      'fortune' || 'fal' => 'Fal',
      'user' || 'profile' => 'Kullanıcı',
      'post' || 'social_post' => 'Gönderi',
      'room' || 'voice_room' || 'chatroom' => 'Sesli oda',
      'video' || 'short' || 'shorts' => 'Video',
      'blog' || 'article' => 'Yazı',
      'dream' || 'dream_dictionary' => 'Rüya tabiri',
      'teller' || 'psychic' => 'Falcı',
      _ => 'İçerik',
    };
  }

  /// ISO tarih → «15 Eki 2026, 14:30» (yerel saat).
  static String dateTime(String? iso, {bool withTime = true}) {
    if (iso == null || iso.trim().isEmpty) return '';
    final d = DateTime.tryParse(iso.trim());
    if (d == null) return iso;
    try {
      return DateFormat(withTime ? 'd MMM yyyy, HH:mm' : 'd MMM yyyy', 'tr')
          .format(d.toLocal());
    } catch (_) {
      final l = d.toLocal();
      String two(int v) => v.toString().padLeft(2, '0');
      return withTime
          ? '${two(l.day)}.${two(l.month)}.${l.year} ${two(l.hour)}:${two(l.minute)}'
          : '${two(l.day)}.${two(l.month)}.${l.year}';
    }
  }

  static const Map<String, String> _giftEn = {
    'rose': 'Gül',
    'red rose': 'Kırmızı Gül',
    'star': 'Yıldız',
    'kiss': 'Öpücük',
    'teddy bear': 'Ayıcık',
    'teddy': 'Ayıcık',
    'ring': 'Yüzük',
    'cake': 'Pasta',
    'fire': 'Ateş',
    'unicorn': 'Tek Boynuzlu At',
    'castle': 'Şato',
    'diamond': 'Elmas',
    'crown': 'Taç',
    'heart': 'Kalp',
    'lion': 'Aslan',
    'rocket': 'Roket',
    'galaxy': 'Galaksi',
    'yacht': 'Yat',
    'sports car': 'Spor Araba',
    'sportscar': 'Spor Araba',
    'car': 'Araba',
    'crystal': 'Fal Kristali',
    'crystal ball': 'Kristal Küre',
    'diamond rain': 'Elmas Yağmuru',
    'coffee': 'Kahve',
    'turkish coffee': 'Türk Kahvesi',
    'flower': 'Çiçek',
    'bouquet': 'Buket',
    'balloon': 'Balon',
    'chocolate': 'Çikolata',
    'gift': 'Hediye',
    'gift box': 'Hediye Kutusu',
    'love': 'Aşk',
    'angel': 'Melek',
    'butterfly': 'Kelebek',
    'moon': 'Ay',
    'sun': 'Güneş',
    'rainbow': 'Gökkuşağı',
    'fireworks': 'Havai Fişek',
    'champagne': 'Şampanya',
    'trophy': 'Kupa',
    'plane': 'Uçak',
    'airplane': 'Uçak',
    'private jet': 'Özel Jet',
    'dragon': 'Ejderha',
    'phoenix': 'Anka Kuşu',
    'tiger': 'Kaplan',
    'eagle': 'Kartal',
    'hug': 'Sarılma',
    'like': 'Beğeni',
    'thumbs up': 'Beğeni',
    'lollipop': 'Lolipop',
    'ice cream': 'Dondurma',
    'tea': 'Çay',
    'evil eye': 'Nazar Boncuğu',
  };

  /// İngilizce hediye adı → Türkçe (bilinmiyorsa olduğu gibi).
  static String giftName(String? raw) {
    final n = (raw ?? '').trim();
    if (n.isEmpty) return 'Hediye';
    final key = n.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');
    return _giftEn[key] ?? n;
  }

  static String _humanize(String raw) {
    final s = raw.trim().replaceAll('_', ' ').replaceAll('-', ' ');
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
