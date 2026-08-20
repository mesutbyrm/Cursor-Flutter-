import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../fortune/presentation/widgets/fortune_mystic_background.dart';
import '../../../fortune/presentation/widgets/fortune_mystic_title_bar.dart';
import '../../../fortune/presentation/widgets/ultra_premium/ultra_fortune_tokens.dart';
import '../../domain/entities/bana_ozel_entities.dart';

/// Bana Özel sonuç — `POST /api/bana-ozel/open`.
class BanaOzelResultPage extends StatelessWidget {
  const BanaOzelResultPage({super.key, required this.result});

  final BanaOzelOpenResultEntity result;

  @override
  Widget build(BuildContext context) {
    final serif = GoogleFonts.playfairDisplay;
    const gold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: UltraFortuneTokens.deepNight,
      body: FortuneMysticBackground(
        child: Column(
          children: [
            FortuneMysticTitleBar(
              title: '${result.icon} ${result.itemName}',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  if (result.jetonSpent > 0)
                    Text(
                      '${result.jetonSpent} jeton harcandı · Bakiye: ${result.jetonBalance}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: gold.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: gold.withValues(alpha: 0.35)),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.03),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
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
                        child: FilledButton(
                          onPressed: () => context.go('/fortune/bana-ozel'),
                          style: FilledButton.styleFrom(
                            backgroundColor: gold,
                            foregroundColor: Colors.black87,
                          ),
                          child: const Text('Başka içerik'),
                        ),
                      ),
                    ],
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
