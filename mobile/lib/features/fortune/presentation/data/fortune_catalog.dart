import 'package:flutter/material.dart';

import '../../domain/entities/fortune_type_entity.dart';

/// 14+ fal türü — mockup ile uyumlu katalog.
abstract final class FortuneCatalog {
  static const tagline = 'Kendini keşfet, geleceğini aydınlat';
  static const introBullets = [
    '15+ fal türü tek uygulamada',
    'Kişisel yorumlar ve enerji analizi',
    'Günlük fal hatırlatıcıları',
    'Paylaş ve kaydet',
  ];

  static const designFeatures = [
    'Modern koyu tema ve neon gradyanlar',
    'Cam efektli kartlar ve yumuşak geçişler',
    'Detaylı, kişiselleştirilmiş sonuç ekranı',
    'Instagram, WhatsApp, Telegram ile paylaşım',
    'Premium üyelere özel yorumlar',
  ];

  static final dailyFortune = FortuneTypeEntity(
    id: 'daily',
    slug: 'gunluk-fal',
    title: 'Günlük Fal',
    description: 'Bugünün enerjisi ve sürpriz mesajın',
    emoji: '🎁',
    accent: Color(0xFFB832FF),
    kind: FortuneSessionKind.generic,
    ctaLabel: 'Falını Aç',
    isDaily: true,
  );

  static const types = <FortuneTypeEntity>[
    FortuneTypeEntity(
      id: 'tarot',
      slug: 'tarot',
      title: 'Tarot',
      description: 'Kartların sırrını çöz, geleceğine ışık tut',
      emoji: '🃏',
      accent: Color(0xFFB832FF),
      kind: FortuneSessionKind.tarotCards,
      ctaLabel: 'Falına Bak',
    ),
    FortuneTypeEntity(
      id: 'ask',
      slug: 'ask-fali',
      title: 'Aşk Falı',
      description: 'Kalbinin sesini dinle, aşk yolculuğunu keşfet',
      emoji: '💜',
      accent: Color(0xFFFF4EC8),
      kind: FortuneSessionKind.loveHeart,
      ctaLabel: 'Falına Bak',
    ),
    FortuneTypeEntity(
      id: 'kahve',
      slug: 'kahve-fali',
      title: 'Kahve Falı',
      description: 'Fincanındaki desenler sana ne fısıldıyor?',
      emoji: '☕',
      accent: Color(0xFFD97706),
      kind: FortuneSessionKind.coffeeCup,
      ctaLabel: 'Falına Bak',
    ),
    FortuneTypeEntity(
      id: 'yildiz',
      slug: 'yildiz-haritasi',
      title: 'Yıldızname',
      description: 'Burç haritan ve gökyüzü rehberin',
      emoji: '✨',
      accent: Color(0xFF38BDF8),
      kind: FortuneSessionKind.zodiacWheel,
      ctaLabel: 'Yorumunu Al',
    ),
    FortuneTypeEntity(
      id: 'el',
      slug: 'el-fali',
      title: 'El Falı',
      description: 'Avuç içi çizgilerin hayat hikâyeni anlatır',
      emoji: '🖐️',
      accent: Color(0xFF4ADE80),
      kind: FortuneSessionKind.palmScan,
      ctaLabel: 'Analiz Et',
    ),
    FortuneTypeEntity(
      id: 'katina',
      slug: 'katina',
      title: 'Katina',
      description: 'Aşk ve ilişki kartlarıyla derin bakış',
      emoji: '🎴',
      accent: Color(0xFFA855F7),
      kind: FortuneSessionKind.playingCards,
      ctaLabel: 'Falına Bak',
    ),
    FortuneTypeEntity(
      id: 'iskambil',
      slug: 'iskambil',
      title: 'İskambil',
      description: 'Klasik iskambil falı ile hızlı içgörü',
      emoji: '🂡',
      accent: Color(0xFF6366F1),
      kind: FortuneSessionKind.playingCards,
      ctaLabel: 'Falına Bak',
    ),
    FortuneTypeEntity(
      id: 'melek',
      slug: 'melek-kartlari',
      title: 'Melek Kartları',
      description: 'Meleklerden rehberlik ve şifa mesajları',
      emoji: '👼',
      accent: Color(0xFF67E8F9),
      kind: FortuneSessionKind.angelCards,
      ctaLabel: 'Falına Bak',
    ),
    FortuneTypeEntity(
      id: 'numeroloji',
      slug: 'numeroloji',
      title: 'Numeroloji',
      description: 'Sayıların gücüyle kendini keşfet',
      emoji: '🔢',
      accent: Color(0xFF34D399),
      kind: FortuneSessionKind.numberInput,
      ctaLabel: 'Hesapla',
    ),
    FortuneTypeEntity(
      id: 'ruya',
      slug: 'ruya-tabiri',
      title: 'Rüya Tabiri',
      description: 'Rüyalarının anlamını keşfet, mesajlarını çöz',
      emoji: '🌙',
      accent: Color(0xFF818CF8),
      kind: FortuneSessionKind.dreamText,
      ctaLabel: 'Yorumla',
    ),
    FortuneTypeEntity(
      id: 'cin',
      slug: 'cin-fali',
      title: 'Çin Falı',
      description: 'Binlerce yıllık Çin bilgeliği sana yol gösterir',
      emoji: '🏮',
      accent: Color(0xFFEF4444),
      kind: FortuneSessionKind.chineseCoins,
      ctaLabel: 'Falına Bak',
    ),
    FortuneTypeEntity(
      id: 'pendul',
      slug: 'pendul',
      title: 'Pendül',
      description: 'Sorularına odaklan, pendül cevap söylesin',
      emoji: '🔮',
      accent: Color(0xFF14B8A6),
      kind: FortuneSessionKind.pendulum,
      ctaLabel: 'Cevap Al',
    ),
    FortuneTypeEntity(
      id: 'runik',
      slug: 'runik',
      title: 'Runik',
      description: 'Runelerin kadim gücüyle spiritüel rehberlik al',
      emoji: 'ᚠ',
      accent: Color(0xFF94A3B8),
      kind: FortuneSessionKind.runeStone,
      ctaLabel: 'Falına Bak',
    ),
    FortuneTypeEntity(
      id: 'evet-hayir',
      slug: 'evet-hayir',
      title: 'Evet / Hayır',
      description: 'Net sorulara net cevaplar, evet mi, hayır mı?',
      emoji: '❓',
      accent: Color(0xFFFBBF24),
      kind: FortuneSessionKind.yesNo,
      ctaLabel: 'Cevap Al',
    ),
  ];

  /// Fal & Tarot hub 2×4 grid — mockup sırası ve kısa alt metinler.
  static const hubFortuneEntries = <({String slug, String subtitle})>[
    (slug: 'tarot', subtitle: 'Kartların mesajını keşfet'),
    (slug: 'kahve-fali', subtitle: 'Fincandaki işaretleri çöz'),
    (slug: 'ask-fali', subtitle: 'Kalbinin sesini dinle'),
    (slug: 'yildiz-haritasi', subtitle: 'Burç haritan ve gökyüzü rehberin'),
    (slug: 'el-fali', subtitle: 'Avuç içindeki sırları keşfet'),
    (slug: 'katina', subtitle: 'Aşk ve ilişki kartlarıyla bakış'),
    (slug: 'melek-kartlari', subtitle: 'Meleklerden rehberlik al'),
    (slug: 'numeroloji', subtitle: 'Sayıların enerjisini öğren'),
  ];

  static List<({FortuneTypeEntity type, String subtitle})> get hubFortuneTypes {
    final out = <({FortuneTypeEntity type, String subtitle})>[];
    for (final entry in hubFortuneEntries) {
      final type = bySlug(entry.slug);
      if (type != null) {
        out.add((type: type, subtitle: entry.subtitle));
      }
    }
    return out;
  }

  static FortuneTypeEntity? bySlug(String slug) {
    final normalized =
        _slugAliases[slug.trim().toLowerCase()] ?? slug.trim().toLowerCase();
    if (dailyFortune.slug == normalized || dailyFortune.id == normalized) {
      return dailyFortune;
    }
    for (final t in types) {
      if (t.slug == normalized || t.id == normalized) return t;
    }
    return null;
  }

  static const _slugAliases = {
    'daily': 'gunluk-fal',
    'gunluk': 'gunluk-fal',
    'günlük-fal': 'gunluk-fal',
    'tarot-fali': 'tarot',
    'tarot-falı': 'tarot',
    'love': 'ask-fali',
    'ask-uyumu': 'ask-fali',
    'kahve': 'kahve-fali',
    'coffee': 'kahve-fali',
    'coffee-image': 'kahve-fali',
    'kahve-fali-image': 'kahve-fali',
    'kahve-falı': 'kahve-fali',
    'burc-yorumu': 'yildiz-haritasi',
    'yildizname': 'yildiz-haritasi',
    'yildizname-fali': 'yildiz-haritasi',
    'yıldızname': 'yildiz-haritasi',
    'horoscope': 'yildiz-haritasi',
    'dogum-haritasi': 'yildiz-haritasi',
    'birthchart': 'yildiz-haritasi',
    'palm': 'el-fali',
    'katina-fali': 'katina',
    'angel': 'melek-kartlari',
    'melek-kartlari-fali': 'melek-kartlari',
    'numerology': 'numeroloji',
    'ruya': 'ruya-tabiri',
    'ruya-yorumu': 'ruya-tabiri',
    'dream': 'ruya-tabiri',
    'yesno': 'evet-hayir',
    'evet-hayır': 'evet-hayir',
    'istihare': 'pendul',
    'istikhara': 'pendul',
  };
}
