import 'package:flutter/material.dart';

import '../../../../fortune/presentation/data/fortune_type_images.dart';

/// Backend `fortuneType` değerleri (coffee, palm, love…) ile mobil slug'ları
/// (kahve-fali, el-fali…) aynı sahne anahtarına çevirir. Bilinmeyen tür
/// `null` döner → kart genel mistik sahneyi (tarot) kullanır.
String? fortuneSceneSlugFor(String? type) {
  final t = type?.trim().toLowerCase();
  if (t == null || t.isEmpty) return null;
  return switch (t) {
    'coffee' || 'kahve-fali' || 'kahve' => 'kahve-fali',
    'palm' || 'el-fali' => 'el-fali',
    'tarot' || 'gunluk-tarot' || 'tarot-fali' => 'tarot',
    'love' || 'ask-fali' || 'ask-uyumu' => 'ask-fali',
    'numerology' || 'numeroloji' => 'numeroloji',
    'aura' || 'aura-analizi' => 'aura-analizi',
    'istikhara' || 'istihare' => 'istihare',
    'yesno' || 'evet-hayir' => 'evet-hayir',
    'horoscope' || 'burc-yorumu' || 'yildiz-haritasi' || 'astroloji' =>
      'yildiz-haritasi',
    'angel' || 'melek-kartlari' => 'melek-kartlari',
    'dream' || 'ruya-yorumu' || 'ruya-tabiri' => 'ruya-tabiri',
    'birthchart' || 'dogum-haritasi' => 'dogum-haritasi',
    'kursundokme' || 'kursun-dokme' => 'kursundokme',
    'katina' => 'katina',
    'iskambil' || 'iskambil-fali' => 'iskambil',
    'pendul' || 'pendul-fali' => 'pendul',
    'runik' || 'runik-fali' => 'runik',
    'cin-fali' => 'cin-fali',
    'gunluk-fal' => 'gunluk-fal',
    _ => null,
  };
}

/// Fal paylaşımı: türe uygun mistik görselin üzerine fal metni yazılır.
/// Görseller `assets/fortune/` içindedir (ağ yok, anında açılır).
class SocialFortuneSceneCard extends StatelessWidget {
  const SocialFortuneSceneCard({
    super.key,
    required this.fortuneType,
    required this.typeLabel,
    required this.body,
    required this.onTap,
    this.onDoubleTap,
    this.bottomOverlay,
    this.maxLines = 8,
  });

  final String? fortuneType;
  final String typeLabel;
  final String body;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final Widget? bottomOverlay;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final slug = fortuneSceneSlugFor(fortuneType) ?? 'tarot';
    final asset = FortuneTypeImages.assetPathFor(slug) ??
        FortuneTypeImages.assetPathFor('tarot')!;
    final overlay = FortuneTypeImages.overlayColors(slug);
    final glow = FortuneTypeImages.glowColor(slug);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final scale = MediaQuery.textScalerOf(context);

    return Semantics(
      button: true,
      label: '$typeLabel paylaşımı, detayı aç',
      child: GestureDetector(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        behavior: HitTestBehavior.opaque,
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: RepaintBoundary(
            child: LayoutBuilder(
              builder: (context, c) => Stack(
                fit: StackFit.expand,
                children: [
                  // Yavaş yaklaşma (ken-burns): tek seferlik, ucuz.
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.08, end: 1.0),
                    duration: const Duration(milliseconds: 1400),
                    curve: Curves.easeOutCubic,
                    builder: (_, s, child) =>
                        Transform.scale(scale: s, child: child),
                    child: Image.asset(
                      asset,
                      fit: BoxFit.cover,
                      cacheWidth: (c.maxWidth * dpr).round().clamp(240, 1200),
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) => DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              glow.withValues(alpha: 0.55),
                              const Color(0xFF0A0118),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Okunabilirlik: türe özel renk + alttan koyulaşan perde.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          overlay.first,
                          const Color(0x330A0118),
                          const Color(0xB30A0118),
                          const Color(0xE60A0118),
                        ],
                        stops: const [0, 0.3, 0.7, 1],
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: glow.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      14,
                      16,
                      bottomOverlay != null ? 56 : 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TypeChip(label: typeLabel, glow: glow),
                        const Spacer(),
                        Flexible(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            builder: (_, v, child) => Opacity(
                              opacity: v,
                              child: Transform.translate(
                                offset: Offset(0, (1 - v) * 10),
                                child: child,
                              ),
                            ),
                            child: Text(
                              body,
                              maxLines: scale.scale(1) > 1.3
                                  ? maxLines - 3
                                  : maxLines,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    color: Color(0xCC000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'daha fazla',
                          style: TextStyle(
                            color: Color(0xFF22D3EE),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (bottomOverlay != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: bottomOverlay!,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.glow});

  final String label;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x66000000),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: glow.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 15, color: glow),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
