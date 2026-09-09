import '../../profile/data/jeton_packages_catalog.dart';

/// Yayın veya sesli oda oturumu sonunda gösterilen hediye özeti.
class SessionGiftSummary {
  const SessionGiftSummary({
    required this.title,
    required this.totalGrossJeton,
    required this.myNetJeton,
    required this.guestNetJeton,
    required this.senders,
    this.jetonTlRate = kDefaultJetonTlRate,
    this.isHostOrOwner = false,
    this.recipientOnly = false,
    this.duration,
    this.viewerCount = 0,
    this.peakViewerCount = 0,
    this.likeCount = 0,
    this.giftEventCount = 0,
    this.fortuneRequestCount = 0,
    this.fortuneAcceptedCount = 0,
  });

  final String title;
  /// Oturumda atılan toplam brüt jeton (herkesin gördüğü).
  final int totalGrossJeton;
  /// Bana kalan net jeton (%50 pay).
  final int myNetJeton;
  /// Misafirlere / koltuk alıcılarına giden net jeton toplamı.
  final int guestNetJeton;
  final List<SessionGiftSenderRow> senders;
  final double jetonTlRate;
  final bool isHostOrOwner;
  /// Yalnızca hediye alan kullanıcı — cüzdan yenilemesi için.
  final bool recipientOnly;
  final Duration? duration;
  final int viewerCount;
  final int peakViewerCount;
  final int likeCount;
  final int giftEventCount;
  final int fortuneRequestCount;
  final int fortuneAcceptedCount;

  double tlForJeton(int jeton) =>
      jeton <= 0 ? 0 : (jeton * jetonTlRate);

  String formatJeton(int jeton, {String label = 'jeton'}) => '$jeton $label';

  String formatJetonWithTl(int jeton, {String label = 'jeton'}) {
    if (jeton <= 0) return '0 $label';
    final tl = tlForJeton(jeton);
    return '$jeton $label (${tl.toStringAsFixed(2)} ₺)';
  }

  String formatDuration(Duration? d) {
    if (d == null) return '—';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}s ${m}dk';
    if (m > 0) return '${m}dk ${s}sn';
    return '${s}sn';
  }

  bool get hasData =>
      totalGrossJeton > 0 ||
      senders.isNotEmpty ||
      myNetJeton > 0 ||
      likeCount > 0 ||
      fortuneRequestCount > 0 ||
      (isHostOrOwner && duration != null);
}

class SessionGiftSenderRow {
  const SessionGiftSenderRow({
    required this.displayName,
    required this.grossJeton,
    this.giftCount = 0,
  });

  final String displayName;
  final int grossJeton;
  final int giftCount;
}
