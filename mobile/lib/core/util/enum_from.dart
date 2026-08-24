/// Bilinmeyen enum değeri → [fallback] (resmî servis entegrasyon dokümanı §6).
E enumFrom<E extends Enum>(
  List<E> values,
  String? raw,
  E fallback,
) {
  if (raw == null || raw.trim().isEmpty) return fallback;
  final needle = raw.trim().toLowerCase();
  for (final v in values) {
    if (v.name.toLowerCase() == needle) return v;
  }
  return fallback;
}
