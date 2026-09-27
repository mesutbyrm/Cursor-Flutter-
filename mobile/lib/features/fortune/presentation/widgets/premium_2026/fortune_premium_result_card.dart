import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/fortune_type_entity.dart';

/// Premium fal sonucu kartı — tür, tarih, özet.
class FortunePremiumResultCard extends StatelessWidget {
  const FortunePremiumResultCard({
    super.key,
    required this.result,
  });

  final FortuneReadingResult result;

  @override
  Widget build(BuildContext context) {
    final accent = result.type.accent;
    final date = DateFormat('d MMMM yyyy, HH:mm', 'tr').format(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        color: const Color(0xFF1A1030).withValues(alpha: 0.92),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.10),
            const Color(0xFF12081F).withValues(alpha: 0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(result.type.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fal Sonucu',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                    Text(
                      '${result.type.title} · $date',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (result.isLocalFallback) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB020).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFFB020).withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                'Canlı API geçici yanıt vermedi — bu hazır yorum gösteriliyor.',
                style: TextStyle(
                  color: const Color(0xFFFFD580),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            result.summary,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.05, curve: Curves.easeOutCubic);
  }
}
