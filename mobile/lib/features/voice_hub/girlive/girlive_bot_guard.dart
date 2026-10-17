import '../domain/utils/voice_banned_word_filter.dart';
import 'girlive_word_bank.dart';

/// [GirLiveBotGuard.evaluate] sonucu.
class GirLiveBotVerdict {
  const GirLiveBotVerdict.allowed()
      : allowed = true,
        notice = null,
        error = null,
        muted = false,
        strike = 0;

  const GirLiveBotVerdict.blocked({
    required this.notice,
    required this.error,
    required this.strike,
    this.muted = false,
  }) : allowed = false;

  /// Mesaj gönderilebilir.
  final bool allowed;

  /// Sohbette bot satırı olarak (yalnızca gönderene) gösterilecek uyarı.
  final String? notice;

  /// Kısa hata / toast metni.
  final String? error;

  /// Bu ihlal susturmaya yol açtı ya da kullanıcı zaten susturulu.
  final bool muted;

  /// Penceredeki ihlal sırası (1, 2, …).
  final int strike;
}

/// GirLive Bot'un sohbet bekçisi: yasaklı kelime → uyarı → tekrarında susturma.
///
/// * [maxStrikes] ihlal [window] içinde olursa kullanıcı [muteFor] süre
///   susturulur (mesaj gönderemez).
/// * Oda başına ve cihaz içinde çalışır; sunucudaki otomatik moderasyonun
///   yerine geçmez, onun yanında ek bir koruma katmanıdır. Yetkililer (oda
///   sahibi, moderatör, admin) bu korumaya tabi değildir — çağıran taraf
///   yetkilileri hiç değerlendirmeye sokmaz.
class GirLiveBotGuard {
  GirLiveBotGuard({
    GirLiveWordBank? words,
    this.maxStrikes = 3,
    this.window = const Duration(minutes: 10),
    this.muteFor = const Duration(minutes: 5),
  }) : _words = words ?? GirLiveWordBank.instance;

  static final GirLiveBotGuard instance = GirLiveBotGuard();

  final GirLiveWordBank _words;
  final int maxStrikes;
  final Duration window;
  final Duration muteFor;

  final Map<String, List<DateTime>> _strikes = {};
  final Map<String, DateTime> _mutedUntil = {};

  /// Kalan susturma süresi; susturulu değilse `null`.
  Duration? mutedRemaining(String roomKey, {DateTime? now}) {
    final t = now ?? DateTime.now();
    final until = _mutedUntil[roomKey];
    if (until == null) return null;
    if (!until.isAfter(t)) {
      _mutedUntil.remove(roomKey);
      return null;
    }
    return until.difference(t);
  }

  /// Gönderilmek istenen mesajı değerlendirir.
  ///
  /// [roomWords]: o odanın admin / yönetici tarafından eklenen kelimeleri
  /// (tam kelime eşleşir).
  GirLiveBotVerdict evaluate({
    required String roomKey,
    required String text,
    Iterable<String> roomWords = const [],
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();

    final left = mutedRemaining(roomKey, now: t);
    if (left != null) {
      final mins = (left.inSeconds / 60).ceil().clamp(1, 999);
      return GirLiveBotVerdict.blocked(
        notice: 'Kurallara uymadığın için susturuldun. '
            'Yaklaşık $mins dk sonra tekrar yazabilirsin.',
        error: 'GirLive Bot: $mins dk susturuldun.',
        strike: 0,
        muted: true,
      );
    }

    // Odanın kendi (admin/yönetici) kelimeleri: eskisi gibi TAM kelime.
    // İnternetten alınan genel liste: ekli hâlleriyle de (4+ harf).
    final hit = VoiceBannedWordFilter.containsBannedWord(text, roomWords) ||
        _words.containsBanned(text);
    if (!hit) {
      return const GirLiveBotVerdict.allowed();
    }

    final list = (_strikes[roomKey] ?? <DateTime>[])
      ..removeWhere((d) => t.difference(d) > window)
      ..add(t);
    _strikes[roomKey] = list;

    if (list.length >= maxStrikes) {
      _strikes.remove(roomKey);
      _mutedUntil[roomKey] = t.add(muteFor);
      final mins = muteFor.inMinutes.clamp(1, 999);
      return GirLiveBotVerdict.blocked(
        notice: 'Yasaklı kelime kullanmaya devam ettiğin için $mins dk '
            'susturuldun.',
        error: 'GirLive Bot: $mins dk susturuldun.',
        strike: list.length,
        muted: true,
      );
    }

    final left2 = maxStrikes - list.length;
    return GirLiveBotVerdict.blocked(
      notice: '⚠️ Uyarı ${list.length}/$maxStrikes: bu odada yasaklı kelime '
          'kullanılamaz. $left2 ihlal daha olursa susturulacaksın.',
      error: 'Mesajınız yasaklı kelime içeriyor.',
      strike: list.length,
    );
  }

  /// Test / oda değişimi için sıfırlar.
  void reset([String? roomKey]) {
    if (roomKey == null) {
      _strikes.clear();
      _mutedUntil.clear();
    } else {
      _strikes.remove(roomKey);
      _mutedUntil.remove(roomKey);
    }
  }
}
