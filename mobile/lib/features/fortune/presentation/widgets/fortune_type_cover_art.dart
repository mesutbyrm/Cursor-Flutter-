import 'package:flutter/material.dart';

import '../data/fortune_type_images.dart';

/// Çevrimdışı fal türü kapak sanatı — ağ görseli yüklenene kadar veya hata durumunda.
class FortuneTypeCoverArt extends StatelessWidget {
  const FortuneTypeCoverArt({
    super.key,
    required this.slug,
    required this.accent,
    this.fit = StackFit.expand,
  });

  final String slug;
  final Color accent;
  final StackFit fit;

  @override
  Widget build(BuildContext context) {
    final scene = FortuneTypeImages.sceneSlug(slug);
    final overlays = FortuneTypeImages.overlayColors(slug);
    final glow = FortuneTypeImages.glowColor(slug);
    final art = _artFor(scene);

    return Stack(
      fit: fit,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                glow.withValues(alpha: 0.55),
                accent.withValues(alpha: 0.35),
                const Color(0xFF0A0118),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _ScenePainter(scene: scene, glow: glow)),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: overlays.length >= 2
                  ? [
                      overlays.first.withValues(alpha: 0.25),
                      overlays.last.withValues(alpha: 0.65),
                    ]
                  : [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                    ],
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(art.emoji, style: const TextStyle(fontSize: 72, height: 1)),
              const SizedBox(height: 8),
              Text(
                art.label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static _CoverArt _artFor(String scene) => switch (scene) {
        'tarot' => const _CoverArt('🃏', 'TAROT'),
        'kahve-fali' => const _CoverArt('☕', 'KAHVE FALI'),
        'ask-fali' => const _CoverArt('💕', 'AŞK FALI'),
        'yildiz-haritasi' => const _CoverArt('✨', 'YILDIZNAME'),
        'el-fali' => const _CoverArt('🤚', 'EL FALI'),
        'katina' => const _CoverArt('🔮', 'KATİNA'),
        'iskambil' => const _CoverArt('🂡', 'İSKAMBİL'),
        'melek-kartlari' => const _CoverArt('👼', 'MELEK KARTLARI'),
        'numeroloji' => const _CoverArt('🔢', 'NUMEROLOJİ'),
        'ruya-tabiri' => const _CoverArt('🌙', 'RÜYA TABİRİ'),
        'cin-fali' => const _CoverArt('🐉', 'ÇİN FALI'),
        'istihare' => const _CoverArt('🕌', 'İSTİHARE'),
        'aura' => const _CoverArt('🌈', 'AURA'),
        'evet-hayir' => const _CoverArt('⚖️', 'EVET / HAYIR'),
        'dogum-haritasi' => const _CoverArt('🪐', 'DOĞUM HARİTASI'),
        'kursun-dokme' => const _CoverArt('🕯️', 'KURŞUN DÖKME'),
        _ => const _CoverArt('✨', 'FAL'),
      };
}

class _CoverArt {
  const _CoverArt(this.emoji, this.label);
  final String emoji;
  final String label;
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({required this.scene, required this.glow});

  final String scene;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = glow.withValues(alpha: 0.12);
    final w = size.width;
    final h = size.height;

    for (var i = 0; i < 6; i++) {
      final radius = w * (0.08 + i * 0.04);
      canvas.drawCircle(
        Offset(w * (0.2 + i * 0.12), h * (0.15 + (i % 3) * 0.2)),
        radius,
        paint,
      );
    }

    if (scene == 'tarot' || scene == 'iskambil' || scene == 'melek-kartlari') {
      final cardPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (var i = 0; i < 3; i++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.55 + i * 18, h * 0.28 + i * 10, w * 0.22, h * 0.38),
          const Radius.circular(10),
        );
        canvas.drawRRect(rect, cardPaint);
      }
    } else if (scene == 'kahve-fali') {
      final cup = Paint()..color = Colors.white.withValues(alpha: 0.1);
      canvas.drawOval(Rect.fromLTWH(w * 0.62, h * 0.42, w * 0.18, h * 0.12), cup);
      canvas.drawArc(
        Rect.fromLTWH(w * 0.58, h * 0.34, w * 0.26, h * 0.22),
        3.4,
        2.4,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    } else if (scene == 'yildiz-haritasi' || scene == 'dogum-haritasi') {
      final star = Paint()..color = Colors.white.withValues(alpha: 0.35);
      for (final p in const [
        Offset(0.72, 0.22),
        Offset(0.82, 0.38),
        Offset(0.66, 0.48),
        Offset(0.78, 0.58),
      ]) {
        canvas.drawCircle(Offset(w * p.dx, h * p.dy), 2.5, star);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) =>
      old.scene != scene || old.glow != glow;

}
