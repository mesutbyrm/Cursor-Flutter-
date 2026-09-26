import '../../voice_hub/domain/voice_official_join.dart';
import 'gift_feed_item.dart';

/// Ana sayfa ticker / duyuru satırından ayrıştırılmış hediye.
class TickerGiftAnnouncement {
  const TickerGiftAnnouncement({
    required this.raw,
    required this.senderName,
    required this.giftName,
    required this.receiverName,
    required this.amount,
  });

  final String raw;
  final String senderName;
  final String giftName;
  final String receiverName;
  final int amount;

  String get eventId => 'ticker:${raw.trim().toLowerCase()}';

  String announcementLabelFor({String jetonLabel = 'Jeton'}) =>
      HomepageGiftTicker.composeAnnouncement(
        senderName: senderName,
        giftName: giftName,
        receiverName: receiverName,
        amount: amount,
        jetonLabel: jetonLabel,
      );

  String get announcementLabel => announcementLabelFor();
}

/// Homepage ticker hediye satırları — ana şeritte döndürülmez.
abstract final class HomepageGiftTicker {
  static final _parse = RegExp(
    r'^(?:🎁\s*)?(.+?)\s*(?:->|→)\s*(.+?)\s*\(\s*(\d+)\s*jeton\s*\)\s*(?:->|→)\s*(.+?)(?:\s*🎁)?\s*$',
    caseSensitive: false,
  );

  static bool isGiftLine(String raw) {
    return VoiceOfficialJoin.isHomeBannerGiftAnnouncement(raw);
  }

  static List<String> newsLines(Iterable<String> lines) {
    return lines.where((line) => !isGiftLine(line)).toList(growable: false);
  }

  static List<String> giftLines(Iterable<String> lines) {
    return lines.where(isGiftLine).toList(growable: false);
  }

  static TickerGiftAnnouncement? tryParse(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final match = _parse.firstMatch(t);
    if (match == null) {
      if (!isGiftLine(t)) return null;
      return TickerGiftAnnouncement(
        raw: t,
        senderName: 'Biri',
        giftName: t.replaceAll('🎁', '').trim(),
        receiverName: '',
        amount: 0,
      );
    }
    return TickerGiftAnnouncement(
      raw: t,
      senderName: match[1]!.trim(),
      giftName: match[2]!.trim(),
      receiverName: match[4]!.replaceAll('🎁', '').trim(),
      amount: int.tryParse(match[3]!) ?? 0,
    );
  }

  static String composeAnnouncement({
    required String senderName,
    required String giftName,
    String? receiverName,
    int amount = 0,
    String? giftIcon,
    String jetonLabel = 'Jeton',
  }) {
    final sender = senderName.trim().isEmpty ? 'Biri' : senderName.trim();
    final giftBits = <String>[
      if (giftIcon != null && giftIcon.trim().isNotEmpty) giftIcon.trim(),
      giftName.trim().isEmpty ? 'Hediye' : giftName.trim(),
      if (amount > 0) '($amount $jetonLabel)',
    ];
    final gift = giftBits.join(' ');
    final recv = receiverName?.trim() ?? '';
    if (recv.isNotEmpty) return '🎁 $sender → $gift → $recv';
    return '🎁 $sender → $gift';
  }
}

/// İlk yüklemede geçmiş hediyeleri işaretler; yalnızca yeni satırları döner.
class HomepageGiftTickerGate {
  final _seen = <String>{};
  var seeded = false;

  /// Duyuru (hediye dışı) satırları — çağrı yeri başına ayrı seed tutulur ki
  /// bir kaynağın ilk poll'ü diğerinin geçmişini "yeni" göstermesin.
  final _newsSeen = <String, Set<String>>{};

  /// Hediye dışı ticker satırları. `/api/homepage-ticker` sunucuda birikmiş
  /// duyuru geçmişini her poll'de yeniden döndürür; ilk çağrı bu geçmişi
  /// işaretleyip boş döner, sonraki çağrılarda yalnızca yeni satırlar gelir.
  /// Aksi halde eski "… odasına giriş yaptı" satırları her poll'de canlı
  /// olaymış gibi tekrar gösterilir.
  List<String> takeNewNewsLines(
    Iterable<String> lines, {
    required String source,
  }) {
    final news = HomepageGiftTicker.newsLines(lines);
    final seen = _newsSeen[source];
    if (seen == null) {
      _newsSeen[source] = {for (final line in news) _key(line)};
      return const [];
    }
    final fresh = <String>[];
    for (final line in news) {
      if (!seen.add(_key(line))) continue;
      fresh.add(line);
    }
    while (seen.length > 400) {
      seen.remove(seen.first);
    }
    return fresh;
  }

  /// Kaynağı yeniden seed'e zorlar. Uygulama arka plandayken kaçırılan
  /// duyurular dönüşte canlı olay gibi toplu gösterilmesin diye kullanılır.
  void resetNewsSource(String source) {
    _newsSeen.remove(source);
  }

  /// Oturum değişimi — önceki kullanıcının görülmüş satırları yeni oturuma
  /// taşınmaz ve yeni oturumun ilk poll'ü yeniden seed edilir.
  void reset() {
    _seen.clear();
    seeded = false;
    _newsSeen.clear();
  }

  List<TickerGiftAnnouncement> takeNewGiftAnnouncements(Iterable<String> lines) {
    final gifts = HomepageGiftTicker.giftLines(lines);
    if (!seeded) {
      for (final line in gifts) {
        _seen.add(_key(line));
      }
      seeded = true;
      return const [];
    }
    final fresh = <TickerGiftAnnouncement>[];
    for (final line in gifts) {
      if (!_seen.add(_key(line))) continue;
      fresh.add(
        HomepageGiftTicker.tryParse(line) ??
            TickerGiftAnnouncement(
              raw: line,
              senderName: 'Biri',
              giftName: line,
              receiverName: '',
              amount: 0,
            ),
      );
    }
    _trim();
    return fresh;
  }

  void _trim() {
    while (_seen.length > 400) {
      _seen.remove(_seen.first);
    }
  }

  static String _key(String raw) => raw.trim().toLowerCase();
}

/// Insights feed — ilk poll geçmişi oynatmaz.
class GlobalGiftFeedGate {
  final _seen = <String>{};
  var seeded = false;

  List<GiftFeedItem> takeNew(Iterable<GiftFeedItem> items) {
    final list = items.toList(growable: false);
    if (!seeded) {
      for (final item in list) {
        final id = _id(item);
        if (id.isNotEmpty) _seen.add(id);
      }
      seeded = true;
      return const [];
    }
    final fresh = <GiftFeedItem>[];
    for (final item in list) {
      final id = _id(item);
      if (id.isEmpty) continue;
      if (!_seen.add(id)) continue;
      fresh.add(item);
    }
    while (_seen.length > 400) {
      _seen.remove(_seen.first);
    }
    return fresh;
  }

  static String _id(GiftFeedItem item) {
    final id = item.id.trim();
    if (id.isNotEmpty) return id;
    return '${item.senderName}|${item.receiverName}|${item.giftName}|${item.amount}'
        .toLowerCase();
  }
}

/// Metin/id listesi — ilk poll geçmişi oynatmaz (`recent-big` vb.).
class GlobalGiftIdGate {
  final _seen = <String>{};
  var seeded = false;

  List<T> takeNew<T>(Iterable<T> items, String Function(T) idOf) {
    final list = items.toList(growable: false);
    if (!seeded) {
      for (final item in list) {
        final id = idOf(item).trim();
        if (id.isNotEmpty) _seen.add(id);
      }
      seeded = true;
      return <T>[];
    }
    final fresh = <T>[];
    for (final item in list) {
      final id = idOf(item).trim();
      if (id.isEmpty) continue;
      if (!_seen.add(id)) continue;
      fresh.add(item);
    }
    while (_seen.length > 400) {
      _seen.remove(_seen.first);
    }
    return fresh;
  }
}
