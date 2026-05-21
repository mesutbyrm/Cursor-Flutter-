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
      title: 'Yıldız Falı',
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
      accent: Color(0xFFF472B6),
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
      description: 'Doğum tarihinle sayıların gücünü keşfet',
      emoji: '🔢',
      accent: Color(0xFF34D399),
      kind: FortuneSessionKind.numberInput,
      ctaLabel: 'Hesapla',
    ),
    FortuneTypeEntity(
      id: 'ruya',
      slug: 'ruya-tabiri',
      title: 'Rüya Tabiri',
      description: 'Rüyalarının gizli anlamını çöz',
      emoji: '🌙',
      accent: Color(0xFF818CF8),
      kind: FortuneSessionKind.dreamText,
      ctaLabel: 'Yorumla',
    ),
    FortuneTypeEntity(
      id: 'cin',
      slug: 'cin-fali',
      title: 'Çin Falı',
      description: 'I-Ching ile kadim bilgelik',
      emoji: '🏮',
      accent: Color(0xFFEF4444),
      kind: FortuneSessionKind.chineseCoins,
      ctaLabel: 'Falına Bak',
    ),
    FortuneTypeEntity(
      id: 'pendul',
      slug: 'pendul',
      title: 'Pendül',
      description: 'Enerji dengeni pendül ile ölç',
      emoji: '🔮',
      accent: Color(0xFF14B8A6),
      kind: FortuneSessionKind.pendulum,
      ctaLabel: 'Cevap Al',
    ),
    FortuneTypeEntity(
      id: 'runik',
      slug: 'runik',
      title: 'Runik',
      description: 'Kadim runik sembollerden mesaj al',
      emoji: 'ᚠ',
      accent: Color(0xFF94A3B8),
      kind: FortuneSessionKind.runeStone,
      ctaLabel: 'Falına Bak',
    ),
    FortuneTypeEntity(
      id: 'evet-hayir',
      slug: 'evet-hayir',
      title: 'Evet / Hayır',
      description: 'Tek soruna net ve hızlı cevap',
      emoji: '❓',
      accent: Color(0xFFFBBF24),
      kind: FortuneSessionKind.yesNo,
      ctaLabel: 'Cevap Al',
    ),
  ];

  static FortuneTypeEntity? bySlug(String slug) {
    if (dailyFortune.slug == slug) return dailyFortune;
    for (final t in types) {
      if (t.slug == slug) return t;
    }
    return null;
  }
}
