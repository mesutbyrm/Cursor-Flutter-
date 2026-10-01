/// PK takım düzeni: 1x1 … 4x4 (taraf başına 1–4 oyuncu).
class PkTeamLayout {
  const PkTeamLayout({
    required this.team1Count,
    required this.team2Count,
    required this.avatarSize,
    required this.perRow,
    required this.showNames,
  });

  final int team1Count;
  final int team2Count;

  /// Avatar çapı (dp) — takım büyüdükçe küçülür.
  final double avatarSize;

  /// Bir takım satırındaki en fazla avatar (4'lü takım tek satır sığar).
  final int perRow;

  /// Avatar altında isim yazılsın mı (küçük avatarlarda gizlenir).
  final bool showNames;

  /// "1x1", "2x2", "3x2" … (en büyük taraf `max`).
  String get label => '${team1Count}x$team2Count';

  static const maxPerSide = 4;

  /// [available] = bir takıma ayrılan yatay genişlik (dp).
  static PkTeamLayout compute({
    required int team1Count,
    required int team2Count,
    required double available,
  }) {
    final n1 = team1Count.clamp(0, maxPerSide);
    final n2 = team2Count.clamp(0, maxPerSide);
    final biggest = n1 > n2 ? n1 : n2;
    final slots = biggest <= 0 ? 1 : biggest;
    const gap = 6.0;
    // Tek satıra sığdır; en fazla 42, en az 24 dp (panel kompakt kalsın).
    final fit = (available - gap * (slots - 1)) / slots;
    final size = fit.clamp(24.0, 42.0);
    return PkTeamLayout(
      team1Count: n1,
      team2Count: n2,
      avatarSize: size,
      perRow: slots,
      showNames: size >= 32,
    );
  }
}
