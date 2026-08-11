/// PK davet durumu — backend `pending` ve `invited` eşdeğer.
bool isPkInvitePendingStatus(String? status) {
  final s = (status ?? '').toLowerCase().trim();
  return s == 'pending' || s == 'invited';
}
