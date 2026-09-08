import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/fortune_catalog.dart';
import '../services/fortune_reading_coordinator.dart';
import '../widgets/ultra_premium/fortune_ready_reading_premium_card.dart';
import '../widgets/ultra_premium/ultra_fortune_cosmic_background.dart';
import '../widgets/ultra_premium/ultra_fortune_tokens.dart';

class FortuneReadyReadingsPage extends ConsumerWidget {
  const FortuneReadyReadingsPage({super.key});

  static const _items = [
    (
      title: 'Kahve Falı Hazır Yorumu',
      slug: 'kahve-fali',
      body:
          'Fincanında yeni bir yol, kalabalık bir haber ve beklediğin bir görüşme görünüyor.',
    ),
    (
      title: 'Tarot Hazır Yorumu',
      slug: 'tarot',
      body: 'Kartların değişim, karar ve yeni başlangıç temasını vurguluyor.',
    ),
    (
      title: 'Yıldızname Hazır Yorumu',
      slug: 'yildiz-haritasi',
      body:
          'Gökyüzü sana sabır, plan ve doğru zamanda atılacak adım mesajı veriyor.',
    ),
    (
      title: 'Aşk Yorumu',
      slug: 'ask-fali',
      body:
          'Kalbinde netleşmeyen bir konu yakın zamanda konuşma ile aydınlanabilir.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: UltraFortuneTokens.deepNight,
      body: UltraFortuneCosmicBackground(
        child: Column(
          children: [
            SizedBox(height: top + 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  ),
                  Expanded(
                    child: Text(
                      'Hazır Yorumlar',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Anında okunabilir mistik yorumlar — tek dokunuşla falına başla.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final type = FortuneCatalog.bySlug(item.slug);
                  final accent = type?.accent ?? UltraFortuneTokens.electricPurple;
                  return FortuneReadyReadingPremiumCard(
                    slug: item.slug,
                    title: item.title,
                    body: item.body,
                    accent: accent,
                    onTap: type == null
                        ? () {}
                        : () => FortuneReadingCoordinator.openReading(
                              context: context,
                              ref: ref,
                              type: type,
                            ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
