/// Türkçe burç adı ↔ API `zodiacSign` (İngilizce) eşlemesi.
abstract final class HomeZodiacSigns {
  static const apiByTurkish = <String, String>{
    'Koç': 'aries',
    'Boğa': 'taurus',
    'İkizler': 'gemini',
    'Yengeç': 'cancer',
    'Aslan': 'leo',
    'Başak': 'virgo',
    'Terazi': 'libra',
    'Akrep': 'scorpio',
    'Yay': 'sagittarius',
    'Oğlak': 'capricorn',
    'Kova': 'aquarius',
    'Balık': 'pisces',
  };

  static String apiValueFor(String turkishSign) {
    return apiByTurkish[turkishSign] ?? turkishSign.toLowerCase();
  }
}
