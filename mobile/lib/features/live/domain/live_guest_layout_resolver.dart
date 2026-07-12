import 'entities/live_guest_layout.dart';

/// Misafir sayısı / API gridSlots → grid düzeni.
LiveGuestLayout resolveGuestLayout({
  required int guestCount,
  int gridSlots = 0,
}) {
  if (guestCount <= 0 && gridSlots <= 1) return LiveGuestLayout.solo;
  if (gridSlots == 2 || guestCount == 1) return LiveGuestLayout.duo;
  if (gridSlots == 3 || guestCount == 2) return LiveGuestLayout.trio;
  if (gridSlots == 4 || guestCount <= 3) return LiveGuestLayout.quad;
  if (gridSlots == 6 || guestCount <= 5) return LiveGuestLayout.sextet;
  if (gridSlots >= 9 || guestCount > 5) return LiveGuestLayout.nonet;
  return LiveGuestLayout.duo;
}

int parseGuestJeton(Map<String, dynamic> guest) {
  final raw = guest['jeton'] ??
      guest['jetonTotal'] ??
      guest['jetonEarned'] ??
      guest['giftTotal'] ??
      guest['coins'] ??
      guest['score'] ??
      guest['earnings'];
  if (raw is num) return raw.round();
  return int.tryParse('$raw') ?? 0;
}
