/// Ortak misafir (co-broadcast) onay durumu — backend source of truth.
bool isApprovedCoGuestStatus(dynamic raw) {
  final status = raw?.toString().toLowerCase().trim() ?? '';
  if (status.isEmpty) return false;
  return status == 'approved' ||
      status == 'active' ||
      status == 'joined' ||
      status == 'accepted' ||
      status == 'live';
}

List<Map<String, dynamic>> filterApprovedCoGuests(
  List<Map<String, dynamic>> guests,
) {
  return guests
      .where((g) => isApprovedCoGuestStatus(g['status'] ?? g['state']))
      .toList(growable: false);
}
