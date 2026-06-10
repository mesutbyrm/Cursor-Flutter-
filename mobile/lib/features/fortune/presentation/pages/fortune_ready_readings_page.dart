import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../data/fortune_catalog.dart';
import '../widgets/fortune_glass_card.dart';
import '../widgets/fortune_mystic_background.dart';

class FortuneReadyReadingsPage extends StatelessWidget {
  const FortuneReadyReadingsPage({super.key});

  static const _items = [
    (
      title: 'Kahve Falı Hazır Yorumu',
      slug: 'kahve-fali',
      body:
          'Fincanında yeni bir yol, kalabalık bir haber ve beklediğin bir görüşme görünüyor.',
      icon: '☕',
    ),
    (
      title: 'Tarot Hazır Yorumu',
      slug: 'tarot',
      body: 'Kartların değişim, karar ve yeni başlangıç temasını vurguluyor.',
      icon: '🃏',
    ),
    (
      title: 'Yıldızname Hazır Yorumu',
      slug: 'yildiz-haritasi',
      body:
          'Gökyüzü sana sabır, plan ve doğru zamanda atılacak adım mesajı veriyor.',
      icon: '✨',
    ),
    (
      title: 'Aşk Yorumu',
      slug: 'ask-fali',
      body:
          'Kalbinde netleşmeyen bir konu yakın zamanda konuşma ile aydınlanabilir.',
      icon: '💜',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FortuneMysticBackground(
        child: Column(
          children: [
            SizedBox(height: top + 4),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                children: [
                  DiscoverIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Hazır Yorumlar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final type = FortuneCatalog.bySlug(item.slug);
                  return FortuneGlassCard(
                    onTap: type == null
                        ? null
                        : () => context.push('/fortune/${type.slug}/session'),
                    child: Row(
                      children: [
                        Text(item.icon, style: const TextStyle(fontSize: 34)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  color: context.colors.onSurface,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.body,
                                style: TextStyle(
                                  color: context.colors.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
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
