import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/fortune_type_entity.dart';
import '../../services/fortune_energy_scorer.dart';

/// Premium fal sonucu kartı — tür, tarih, skorlar, özet.
class FortunePremiumResultCard extends StatelessWidget {
  const FortunePremiumResultCard({
    super.key,
    required this.result,
  });

  final FortuneReadingResult result;

  @override
  Widget build(BuildContext context) {
    final scores = FortuneEnergyScores.fromResult(result);
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ScoreChip(label: 'Enerji', value: scores.energy, color: accent),
              _ScoreChip(label: 'Aşk', value: scores.love, color: const Color(0xFFFF4EC8)),
              _ScoreChip(label: 'Para', value: scores.money, color: const Color(0xFFFFD700)),
              _ScoreChip(label: 'Kariyer', value: scores.career, color: const Color(0xFF38BDF8)),
              _ScoreChip(label: 'Şans', value: scores.luck, color: const Color(0xFF4ADE80)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.05, curve: Curves.easeOutCubic);
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.95),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '%$value',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
