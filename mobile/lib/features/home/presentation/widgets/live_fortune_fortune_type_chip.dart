/// canlifal.com fal türleri — web «Fal Türü Seçin» ile aynı.
class LiveFortuneFortuneType {
  const LiveFortuneFortuneType({required this.key, required this.label});

  final String key;
  final String label;
}

const liveFortuneFortuneTypes = [
  LiveFortuneFortuneType(key: 'general', label: 'Genel Danışmanlık'),
  LiveFortuneFortuneType(key: 'coffee', label: 'Kahve Falı'),
  LiveFortuneFortuneType(key: 'tarot', label: 'Tarot'),
  LiveFortuneFortuneType(key: 'astrology', label: 'Astroloji'),
  LiveFortuneFortuneType(key: 'palmistry', label: 'El Falı'),
  LiveFortuneFortuneType(key: 'numerology', label: 'Numeroloji'),
];

String fortuneTypeLabel(String key) {
  final k = key.trim().toLowerCase();
  for (final t in liveFortuneFortuneTypes) {
    if (t.key == k) return t.label;
  }
  if (k.isEmpty) return 'Genel Danışmanlık';
  return key;
}

List<LiveFortuneFortuneType> fortuneTypesForTeller(List<String> specialties) {
  if (specialties.isEmpty) {
    return const [liveFortuneFortuneTypes.first];
  }
  final out = <LiveFortuneFortuneType>[];
  for (final spec in specialties) {
    final label = fortuneTypeLabel(spec);
    final key = spec.trim().toLowerCase();
    if (out.any((t) => t.key == key)) continue;
    out.add(LiveFortuneFortuneType(key: key, label: label));
  }
  if (out.isEmpty) return const [liveFortuneFortuneTypes.first];
  return out;
}
