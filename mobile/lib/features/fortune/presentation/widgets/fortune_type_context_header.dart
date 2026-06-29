import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/fortune_type_entity.dart';

/// Fal türü adı + açıklama — başlık çubuğunun hemen altında.
class FortuneTypeContextHeader extends StatelessWidget {
  const FortuneTypeContextHeader({
    super.key,
    required this.type,
    this.subtitle,
    this.titleOverride,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 12),
  });

  final FortuneTypeEntity type;
  final String? subtitle;
  final String? titleOverride;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final text = subtitle ?? type.description;
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            titleOverride ?? type.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: 0.4,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
