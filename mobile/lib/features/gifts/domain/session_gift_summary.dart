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

  double tlForJeton(int jeton) =>
      jeton <= 0 ? 0 : (jeton * jetonTlRate);

  String formatJeton(int jeton) => '$jeton jeton';

  String formatJetonWithTl(int jeton) {
    if (jeton <= 0) return '0 jeton';
    final tl = tlForJeton(jeton);
    return '$jeton jeton (${tl.toStringAsFixed(2)} ₺)';
  }

  bool get hasData =>
      totalGrossJeton > 0 || senders.isNotEmpty || myNetJeton > 0;
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
