import 'package:intl/intl.dart';

/// Sohbet listesi saati: bugün → `14:05`, son 7 gün → gün adı, daha eski → `12 Eki`.
String formatConversationTime(DateTime? dt, {DateTime? now}) {
  if (dt == null) return '';
  final local = dt.toLocal();
  final n = now ?? DateTime.now();
  if (_sameDay(local, n)) return DateFormat.Hm('tr').format(local);
  if (n.difference(local).inDays < 7) return DateFormat.E('tr').format(local);
  return DateFormat('d MMM', 'tr').format(local);
}

/// Gerçek veriye dayalı durum satırı. Veri yoksa boş döner — uydurma
/// "yakın zamanda" gibi ifadeler gösterilmez.
String presenceLabel({required bool isOnline, DateTime? lastSeenAt, DateTime? now}) {
  if (isOnline) return 'çevrimiçi';
  if (lastSeenAt == null) return '';
  final local = lastSeenAt.toLocal();
  final n = now ?? DateTime.now();
  final hm = DateFormat.Hm('tr').format(local);
  if (_sameDay(local, n)) return 'son görülme bugün $hm';
  if (_sameDay(local, n.subtract(const Duration(days: 1)))) return 'son görülme dün $hm';
  if (local.year == n.year) return 'son görülme ${DateFormat('d MMM', 'tr').format(local)} $hm';
  return 'son görülme ${DateFormat('d MMM y', 'tr').format(local)}';
}

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
