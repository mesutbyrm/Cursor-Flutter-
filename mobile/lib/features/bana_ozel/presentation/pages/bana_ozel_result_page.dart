import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../../fortune/presentation/widgets/fortune_type_cover_image.dart';
import '../../../fortune/presentation/widgets/ultra_premium/ultra_fortune_cosmic_background.dart';
import '../../../fortune/presentation/widgets/ultra_premium/ultra_fortune_liquid_surface.dart';
import '../../../fortune/presentation/widgets/ultra_premium/ultra_fortune_tokens.dart';
import '../../domain/entities/bana_ozel_entities.dart';
import '../data/bana_ozel_display_resolver.dart';

/// Bana Özel sonuç — `POST /api/bana-ozel/open`.
class BanaOzelResultPage extends ConsumerWidget {
  const BanaOzelResultPage({super.key, required this.result});

  final BanaOzelOpenResultEntity result;

  BanaOzelItemEntity _itemFromResult() {
    return BanaOzelItemEntity(
      id: result.itemSlug,
      slug: result.itemSlug,
      nameTr: result.itemName,
      icon: result.icon,
      jetonCost: result.jetonSpent,
      category: 'fortune',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serif = GoogleFonts.playfairDisplay;
    const gold = UltraFortuneTokens.metallicGold;
    final locale = Localizations.localeOf(context);
    final jetonName = economyCurrencyLabel(ref, key: 'jeton', locale: locale);
    final cfcName = economyCurrencyLabel(ref, key: 'cfc', locale: locale);
    final paymentLine = result.paymentSummary(
      jetonName: jetonName,
      cfcName: cfcName,
    );
    final item = _itemFromResult();
    final coverSlug = BanaOzelDisplayResolver.coverSlugFor(item);
    final fortuneSlug = BanaOzelDisplayResolver.fortuneSlugFor(item);
    final accent = BanaOzelDisplayResolver.accentFor(item);
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
                      '${result.icon} ${result.itemName}',
                      textAlign: TextAlign.center,
                      style: serif(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Share.share(
                      '${result.itemName}\n\n${result.content}',
                      subject: result.itemName,
                    ),
                    icon: const Icon(Icons.ios_share_rounded),
                    tooltip: 'Paylaş',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 148,
                      width: double.infinity,
                      child: FortuneTypeCoverImage(
                        slug: coverSlug,
                        accent: accent,
                        imageWidth: 900,
                        networkUrlOverride:
                            BanaOzelDisplayResolver.imageUrlFor(item),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (paymentLine.isNotEmpty)
                    Text(
                      paymentLine,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: gold.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  if (result.streak != null &&
                      result.streak!.currentStreak > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '🔥 ${result.streak!.currentStreak} günlük seri',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: gold.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  UltraFortuneLiquidSurface(
                    goldAccent: true,
                    borderRadius: BorderRadius.circular(22),
                    padding: const EdgeInsets.all(20),
                    child: SelectableText(
                      result.content,
                      style: serif(
                        fontSize: 17,
                        height: 1.55,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: result.content),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Metin kopyalandı')),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Kopyala'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Share.share(
                            '${result.itemName}\n\n${result.content}',
                            subject: result.itemName,
                          ),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('Paylaş'),
                          style: FilledButton.styleFrom(
                            backgroundColor: gold,
                            foregroundColor: const Color(0xFF1A0A32),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/fortune/$fortuneSlug'),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: const Text('İlgili fal türüne git'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => context.go('/fortune/bana-ozel'),
                    style: FilledButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: const Color(0xFF1A0A32),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Başka içerik'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
