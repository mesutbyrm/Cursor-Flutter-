enum ZodiacSign {
  aries('Koç', '♈', 'Yang', 'Ateş'),
  taurus('Boğa', '♉', 'Yin', 'Toprak'),
  gemini('İkizler', '♊', 'Yang', 'Hava'),
  cancer('Yengeç', '♋', 'Yin', 'Su'),
  leo('Aslan', '♌', 'Yang', 'Ateş'),
  virgo('Başak', '♍', 'Yin', 'Toprak'),
  libra('Terazi', '♎', 'Yang', 'Hava'),
  scorpio('Akrep', '♏', 'Yin', 'Su'),
  sagittarius('Yay', '♐', 'Yang', 'Ateş'),
  capricorn('Oğlak', '♑', 'Yin', 'Toprak'),
  aquarius('Kova', '♒', 'Yang', 'Hava'),
  pisces('Balık', '♓', 'Yin', 'Su');

  const ZodiacSign(this.turkishName, this.symbol, this.polarity, this.element);

  final String turkishName;
  final String symbol;
  final String polarity;
  final String element;

  static ZodiacSign? fromString(String value) {
    try {
      return ZodiacSign.values.firstWhere(
        (z) => z.name == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  static ZodiacSign fromMonth(int month, int day) {
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return aries;
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return taurus;
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return gemini;
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return cancer;
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return leo;
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return virgo;
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return libra;
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return scorpio;
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return sagittarius;
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return capricorn;
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return aquarius;
    return pisces;
  }
}
