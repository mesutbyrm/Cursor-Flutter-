/// Tanış — göreli zaman etiketi (eşleşme / etkileşim).
String? socialDiscoveryRelativeTimeLabel(DateTime? at) {
  if (at == null) return null;
  final local = at.toLocal();
  final diff = DateTime.now().difference(local);
  if (diff.isNegative) return 'Az önce';
  if (diff.inMinutes < 1) return 'Az önce';
  if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
  if (diff.inHours < 24) return '${diff.inHours} sa önce';
  if (diff.inDays < 7) return '${diff.inDays} gün önce';
  return '${local.day}.${local.month}.${local.year}';
}
