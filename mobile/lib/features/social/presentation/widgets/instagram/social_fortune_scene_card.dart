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
    'gunluk-fal' || 'gunluk-kehanet' || 'gelecek-kehaneti' || 'para-kariyer' ||
    'nazar-analizi' =>
      'gunluk-fal',
    // Backend "Bana Özel" ve ek slug'lar (social-helper FORTUNE_TYPE_LABELS)
    'askuyumu' || 'iliski-gelecegi' || 'ruh-esi' || 'gizli-duygular' =>
      'ask-fali',
    'daily_horoscope' || 'gunluk-burc' || 'haftalik-burc' || 'ay-burcu' ||
    'yukselen-burc' || 'yildizname' =>
      'yildiz-haritasi',
    '3-kart-tarot' || '7-kart-tarot' => 'tarot',
    'enerji-analizi' => 'aura-analizi',
    'evren-mesaj' || 'spiritüel-rehber' || 'gizli-mesaj' => 'melek-kartlari',
    'sansli-sayilar' => 'numeroloji',
    _ => null,
  };
}

/// Fal paylaşımı: türe uygun mistik görselin üzerine fal metni yazılır.
/// Görseller `assets/fortune/` içindedir (ağ yok, anında açılır).
///
/// Metin görselin ÜST kısmındadır; «daha fazla» metnin tamamını kartın
/// içinde açar (kart uzar), «daha az» geri kapatır. Karta dokunmak detayı açar.
class SocialFortuneSceneCard extends StatefulWidget {
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
  State<SocialFortuneSceneCard> createState() => _SocialFortuneSceneCardState();
}

class _SocialFortuneSceneCardState extends State<SocialFortuneSceneCard> {
  var _expanded = false;

  static const _bodyStyle = TextStyle(
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
  );

  bool _overflows(String text, int lines, double width, TextScaler scaler) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: _bodyStyle),
      maxLines: lines,
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout(maxWidth: width);
    final over = tp.didExceedMaxLines;
    tp.dispose();
    return over;
  }

  @override
  Widget build(BuildContext context) {
    final slug = fortuneSceneSlugFor(widget.fortuneType) ?? 'gunluk-fal';
    final asset = FortuneTypeImages.assetPathFor(slug) ??
        FortuneTypeImages.assetPathFor('gunluk-fal') ??
        FortuneTypeImages.assetPathFor('tarot')!;
    final overlay = FortuneTypeImages.overlayColors(slug);
    final glow = FortuneTypeImages.glowColor(slug);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final scale = MediaQuery.textScalerOf(context);
    final lines =
        scale.scale(1) > 1.3 ? widget.maxLines - 3 : widget.maxLines;
    final hasOverlay = widget.bottomOverlay != null;

    return Semantics(
      button: true,
      label: '${widget.typeLabel} paylaşımı, detayı aç',
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        behavior: HitTestBehavior.opaque,
        child: RepaintBoundary(
          child: LayoutBuilder(
            builder: (context, c) {
              final width = c.maxWidth;
              final textWidth = width - 32;
              final canExpand =
                  _overflows(widget.body, lines, textWidth, scale);
              return ConstrainedBox(
                // Kapalıyken 4:5; açılınca metin kadar uzar.
                constraints: BoxConstraints(minHeight: width * 5 / 4),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRect(
                        // Yavaş yaklaşma (ken-burns): tek seferlik, ucuz.
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 1.08, end: 1.0),
                          duration: const Duration(milliseconds: 1400),
                          curve: Curves.easeOutCubic,
                          builder: (_, s, child) =>
                              Transform.scale(scale: s, child: child),
                          child: Image.asset(
                            asset,
                            fit: BoxFit.cover,
                            cacheWidth: (width * dpr).round().clamp(240, 1200),
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
                      ),
                    ),
                    // Okunabilirlik: metin üstte → perde yukarıda koyu,
                    // görselin alt kısmı açık kalır.
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xE60A0118),
                              const Color(0xB30A0118),
                              overlay.first,
                              hasOverlay
                                  ? const Color(0x990A0118)
                                  : const Color(0x330A0118),
                            ],
                            stops: const [0, 0.45, 0.75, 1],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: glow.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        14,
                        16,
                        hasOverlay ? 56 : 16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TypeChip(label: widget.typeLabel, glow: glow),
                          const SizedBox(height: 12),
                          TweenAnimationBuilder<double>(
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
                              widget.body,
                              maxLines: _expanded ? null : lines,
                              overflow: _expanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              style: _bodyStyle,
                            ),
                          ),
                          if (canExpand) ...[
                            const SizedBox(height: 6),
                            GestureDetector(
                              key: const Key('fortune-scene-more'),
                              behavior: HitTestBehavior.opaque,
                              onTap: () =>
                                  setState(() => _expanded = !_expanded),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  _expanded ? 'daha az' : 'daha fazla',
                                  style: const TextStyle(
                                    color: Color(0xFF22D3EE),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (hasOverlay)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: widget.bottomOverlay!,
                      ),
                  ],
                ),
              );
            },
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
