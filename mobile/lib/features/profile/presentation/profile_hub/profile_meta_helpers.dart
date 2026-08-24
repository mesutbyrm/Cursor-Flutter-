/// Burç / takım etiketleri — yalnızca backend değerlerinden.
String profileZodiacLabelTr(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return value;
  final key = value.toLowerCase();
  return switch (key) {
    'aries' => 'Koç',
    'taurus' => 'Boğa',
    'gemini' => 'İkizler',
    'cancer' => 'Yengeç',
    'leo' => 'Aslan',
    'virgo' => 'Başak',
    'libra' => 'Terazi',
    'scorpio' => 'Akrep',
    'sagittarius' => 'Yay',
    'capricorn' => 'Oğlak',
    'aquarius' => 'Kova',
    'pisces' => 'Balık',
    _ => value,
  };
}

String? profileZodiacEmoji(String raw) {
  final key = raw.trim().toLowerCase();
  return switch (key) {
    'aries' || 'koç' || 'koc' => '♈',
    'taurus' || 'boğa' || 'boga' => '♉',
    'gemini' || 'ikizler' => '♊',
    'cancer' || 'yengeç' || 'yengec' => '♋',
    'leo' || 'aslan' => '♌',
    'virgo' || 'başak' || 'basak' => '♍',
    'libra' || 'terazi' => '♎',
    'scorpio' || 'akrep' => '♏',
    'sagittarius' || 'yay' => '♐',
    'capricorn' || 'oğlak' || 'oglak' => '♑',
    'aquarius' || 'kova' => '♒',
    'pisces' || 'balık' || 'balik' => '♓',
    _ => null,
  };
}
