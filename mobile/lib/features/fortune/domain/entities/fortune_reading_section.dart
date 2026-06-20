/// Yapılandırılmış fal bölümü (AI yorumu).
class FortuneReadingSection {
  const FortuneReadingSection({
    required this.key,
    required this.title,
    required this.body,
    this.delaySeconds = 0,
  });

  final String key;
  final String title;
  final String body;

  /// Sonuç ekranında sıralı fade-in gecikmesi (saniye).
  final int delaySeconds;
}

/// Standart premium fal bölüm anahtarları.
abstract final class FortuneSectionKeys {
  static const general = 'general';
  static const love = 'love';
  static const career = 'career';
  static const money = 'money';
  static const future = 'future';
  static const advice = 'advice';

  static const ordered = [
    general,
    love,
    career,
    money,
    future,
    advice,
  ];

  static const titles = <String, String>{
    general: 'Genel Enerji',
    love: 'Aşk Hayatı',
    career: 'İş ve Kariyer',
    money: 'Para Durumu',
    future: 'Yakın Gelecek',
    advice: 'Tavsiye',
  };
}
