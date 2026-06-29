/// Batı burçları — doğum tarihine göre Türkçe burç adı.
class FortuneZodiac {
  const FortuneZodiac({
    required this.sign,
    required this.emoji,
    required this.dateRange,
  });

  final String sign;
  final String emoji;
  final String dateRange;

  static FortuneZodiac fromBirthDate(DateTime date) {
    final m = date.month;
    final d = date.day;

    if ((m == 3 && d >= 21) || (m == 4 && d <= 19)) {
      return koc;
    }
    if ((m == 4 && d >= 20) || (m == 5 && d <= 20)) {
      return boga;
    }
    if ((m == 5 && d >= 21) || (m == 6 && d <= 20)) {
      return ikizler;
    }
    if ((m == 6 && d >= 21) || (m == 7 && d <= 22)) {
      return yengec;
    }
    if ((m == 7 && d >= 23) || (m == 8 && d <= 22)) {
      return aslan;
    }
    if ((m == 8 && d >= 23) || (m == 9 && d <= 22)) {
      return basak;
    }
    if ((m == 9 && d >= 23) || (m == 10 && d <= 22)) {
      return terazi;
    }
    if ((m == 10 && d >= 23) || (m == 11 && d <= 21)) {
      return akrep;
    }
    if ((m == 11 && d >= 22) || (m == 12 && d <= 21)) {
      return yay;
    }
    if ((m == 12 && d >= 22) || (m == 1 && d <= 19)) {
      return oglak;
    }
    if ((m == 1 && d >= 20) || (m == 2 && d <= 18)) {
      return kova;
    }
    return balik;
  }

  static const koc = FortuneZodiac(
    sign: 'Koç',
    emoji: '♈',
    dateRange: '21 Mart – 19 Nisan',
  );
  static const boga = FortuneZodiac(
    sign: 'Boğa',
    emoji: '♉',
    dateRange: '20 Nisan – 20 Mayıs',
  );
  static const ikizler = FortuneZodiac(
    sign: 'İkizler',
    emoji: '♊',
    dateRange: '21 Mayıs – 20 Haziran',
  );
  static const yengec = FortuneZodiac(
    sign: 'Yengeç',
    emoji: '♋',
    dateRange: '21 Haziran – 22 Temmuz',
  );
  static const aslan = FortuneZodiac(
    sign: 'Aslan',
    emoji: '♌',
    dateRange: '23 Temmuz – 22 Ağustos',
  );
  static const basak = FortuneZodiac(
    sign: 'Başak',
    emoji: '♍',
    dateRange: '23 Ağustos – 22 Eylül',
  );
  static const terazi = FortuneZodiac(
    sign: 'Terazi',
    emoji: '♎',
    dateRange: '23 Eylül – 22 Ekim',
  );
  static const akrep = FortuneZodiac(
    sign: 'Akrep',
    emoji: '♏',
    dateRange: '23 Ekim – 21 Kasım',
  );
  static const yay = FortuneZodiac(
    sign: 'Yay',
    emoji: '♐',
    dateRange: '22 Kasım – 21 Aralık',
  );
  static const oglak = FortuneZodiac(
    sign: 'Oğlak',
    emoji: '♑',
    dateRange: '22 Aralık – 19 Ocak',
  );
  static const kova = FortuneZodiac(
    sign: 'Kova',
    emoji: '♒',
    dateRange: '20 Ocak – 18 Şubat',
  );
  static const balik = FortuneZodiac(
    sign: 'Balık',
    emoji: '♓',
    dateRange: '19 Şubat – 20 Mart',
  );
}
