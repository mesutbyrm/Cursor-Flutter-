import 'package:flutter/material.dart';

import '../../core/app_models.dart';
import '../../core/app_theme.dart';
import '../../shared/ui.dart';

class FortuneScreen extends StatelessWidget {
  const FortuneScreen({super.key});

  static const categories = <FortuneCategory>[
    FortuneCategory(
      name: 'Kahve Falı',
      endpoint: '/api/fortunes/kahve-fali',
      description: 'Fincan açıklaması veya fotoğraf ile yorum.',
      icon: '☕',
    ),
    FortuneCategory(
      name: 'Tarot',
      endpoint: '/api/fortunes/tarot-fali',
      description: '1/3/5/7 kart açılımı.',
      icon: '🃏',
    ),
    FortuneCategory(
      name: 'Astroloji',
      endpoint: '/api/fortunes/burc-yorumu',
      description: 'Günlük, haftalık ve aylık yorum.',
      icon: '♌',
    ),
    FortuneCategory(
      name: 'Aşk Uyumu',
      endpoint: '/api/fortunes/ask-uyumu',
      description: 'İki burç arasında uyum analizi.',
      icon: '💞',
    ),
    FortuneCategory(
      name: 'El Falı',
      endpoint: '/api/fortunes/el-fali',
      description: 'El fotoğrafı ile analiz.',
      icon: '✋',
    ),
    FortuneCategory(
      name: 'Rüya Yorumu',
      endpoint: '/api/fortunes/ruya-yorumu',
      description: 'Rüya anlatımından yorum.',
      icon: '🌙',
    ),
    FortuneCategory(
      name: 'Numeroloji',
      endpoint: '/api/fortunes/numeroloji',
      description: 'İsim ve doğum tarihi analizi.',
      icon: '🔢',
    ),
    FortuneCategory(
      name: 'Melek Kartları',
      endpoint: '/api/fortunes/melek-kartlari',
      description: 'Soruya özel kart mesajı.',
      icon: '🪽',
    ),
    FortuneCategory(
      name: 'Aura Analizi',
      endpoint: '/api/fortunes/aura-analizi',
      description: 'Selfie ile aura yorumu.',
      icon: '🌈',
    ),
    FortuneCategory(
      name: 'Doğum Haritası',
      endpoint: '/api/fortunes/dogum-haritasi',
      description: 'Saat ve lokasyon ile harita.',
      icon: '🪐',
    ),
    FortuneCategory(
      name: 'Katina',
      endpoint: '/api/fortunes/katina',
      description: 'İlişki ve niyet yorumu.',
      icon: '🔮',
    ),
    FortuneCategory(
      name: 'Evet/Hayır',
      endpoint: '/api/fortunes/evet-hayir',
      description: 'Hızlı niyet cevabı.',
      icon: '✨',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: <Widget>[
        SectionHeader(title: 'Canlı fal ve danışmanlık'),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: premiumGradient(),
          child: const Text(
            'Canlı fal odaları, falcı profilleri, puanlama sistemi ve danışman seansları için profesyonel akış.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(title: 'Fal kategorileri'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (_, index) {
            final item = categories[index];
            return GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(item.icon, style: const TextStyle(fontSize: 30)),
                  const Spacer(),
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
