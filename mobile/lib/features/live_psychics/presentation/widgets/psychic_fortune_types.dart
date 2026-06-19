/// Canlı fal türleri — web «Fal Türü Seçin» ile aynı.
class PsychicFortuneType {
  const PsychicFortuneType({required this.key, required this.label});

  final String key;
  final String label;
}

const psychicFortuneTypes = [
  PsychicFortuneType(key: 'general', label: 'Genel Danışmanlık'),
  PsychicFortuneType(key: 'coffee', label: 'Kahve Falı'),
  PsychicFortuneType(key: 'tarot', label: 'Tarot'),
  PsychicFortuneType(key: 'astrology', label: 'Astroloji'),
  PsychicFortuneType(key: 'palmistry', label: 'El Falı'),
  PsychicFortuneType(key: 'numerology', label: 'Numeroloji'),
];

String psychicFortuneTypeLabel(String key) {
  final k = key.trim().toLowerCase();
  for (final t in psychicFortuneTypes) {
    if (t.key == k) return t.label;
  }
  if (k.isEmpty) return 'Genel Danışmanlık';
  return key;
}

List<PsychicFortuneType> psychicFortuneTypesForPsychic(List<String> specialties) {
  if (specialties.isEmpty) {
    return [psychicFortuneTypes.first];
  }
  final out = <PsychicFortuneType>[];
  for (final spec in specialties) {
    final label = psychicFortuneTypeLabel(spec);
    final key = spec.trim().toLowerCase();
    if (out.any((t) => t.key == key)) continue;
    out.add(PsychicFortuneType(key: key, label: label));
  }
  if (out.isEmpty) return [psychicFortuneTypes.first];
  return out;
}

/// Randevu süre seçenekleri (5–30 dk).
class PsychicDurationOption {
  const PsychicDurationOption({
    required this.minutes,
    required this.jetonPerMinute,
  });

  final int minutes;
  final int jetonPerMinute;

  int get totalJeton => minutes * jetonPerMinute;

  String get label => '$minutes dk';

  static List<PsychicDurationOption> forPsychic(int pricePerMinute) {
    final perMin = pricePerMinute > 0 ? pricePerMinute : 10;
    return [5, 10, 15, 20, 25, 30]
        .map((m) => PsychicDurationOption(minutes: m, jetonPerMinute: perMin))
        .toList();
  }
}
