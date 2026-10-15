import 'package:equatable/equatable.dart';

class UserFortuneEntity extends Equatable {
  const UserFortuneEntity({
    required this.id,
    required this.type,
    this.slug,
    this.question,
    this.answer,
    this.summary,
    this.detail,
    this.luckyNumber,
    this.luckyColor,
    this.createdAt,
  });

  final String id;
  final String type;
  final String? slug;
  final String? question;
  final String? answer;
  final String? summary;
  final String? detail;
  final int? luckyNumber;
  final String? luckyColor;
  final DateTime? createdAt;

  /// Sunucu fal türü anahtarı (`coffee`, `dream`…) → uygulama katalog slug'ı.
  static const backendKeyToSlug = <String, String>{
    'coffee': 'kahve-fali',
    'tarot': 'tarot',
    'dream': 'ruya-tabiri',
    'horoscope': 'gunluk-fal',
    'daily_horoscope': 'gunluk-fal',
    'love': 'ask-fali',
    'palm': 'el-fali',
    'angel': 'melek-kartlari',
    'numerology': 'numeroloji',
    'aura': 'aura-analizi',
    'yesno': 'evet-hayir',
    'birthchart': 'dogum-haritasi',
    'istikhara': 'istihare',
    'katina': 'katina',
    'kursundokme': 'kursundokme',
  };

  static const _titles = <String, String>{
    'kahve-fali': 'Kahve Falı',
    'tarot': 'Tarot Falı',
    'ruya-tabiri': 'Rüya Tabiri',
    'gunluk-fal': 'Burç Yorumu',
    'ask-fali': 'Aşk Falı',
    'el-fali': 'El Falı',
    'melek-kartlari': 'Melek Kartları',
    'numeroloji': 'Numeroloji',
    'aura-analizi': 'Aura Analizi',
    'evet-hayir': 'Evet / Hayır',
    'dogum-haritasi': 'Doğum Haritası',
    'istihare': 'İstihare',
    'katina': 'Katina Falı',
    'kursundokme': 'Kurşun Dökme',
    // Sunucu üretim slug'ları
    'tarot-fali': 'Tarot Falı',
    'ask-uyumu': 'Aşk Uyumu',
    'ruya-yorumu': 'Rüya Yorumu',
    'burc-yorumu': 'Burç Yorumu',
    'kahve-fali-image': 'Kahve Falı',
    'katina-fali': 'Katina Falı',
    'iskambil': 'İskambil Falı',
    'iskambil-fali': 'İskambil Falı',
    'pendul': 'Pandül Falı',
    'pendul-fali': 'Pandül Falı',
    'runik': 'Rün Falı',
    'runik-fali': 'Rün Falı',
    'cin-fali': 'Cin Falı',
    'yildiz-haritasi': 'Yıldız Haritası',
    'melek-kartlari-fali': 'Melek Kartları',
  };

  String get displayTitle {
    final key = (slug ?? '').isNotEmpty
        ? slug!
        : (backendKeyToSlug[type.toLowerCase()] ?? type);
    // İngilizce ham tür (ör. «dream») gösterilmesin.
    return _titles[key] ??
        _titles[backendKeyToSlug[type.toLowerCase()] ?? ''] ??
        _titles[type.toLowerCase()] ??
        'Fal';
  }

  String get displayBody =>
      answer ?? detail ?? summary ?? question ?? '';

  @override
  List<Object?> get props =>
      [id, type, slug, question, answer, summary, detail, luckyNumber, luckyColor, createdAt];
}
