import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/fortune_type_images.dart';
import '../fortune_type_cover_image.dart';

/// Fal & Tarot Premium 2026 — tek tasarım sistemi (hub, katalog, bölümler).
///
/// Cam kartlar `BackdropFilter` kullanmaz: yarı saydam gradient + ince border
/// (düşük donanımlı Android'de akıcı kalır). Sürekli animasyon yoktur.
abstract final class FortuneUi {
  // Renkler
  static const bg0 = Color(0xFF050010);
  static const bg1 = Color(0xFF0A0420);
  static const bg2 = Color(0xFF14062E);
  static const purple = Color(0xFF7A2FFF);
  static const violet = Color(0xFF8B5CF6);
  static const lilac = Color(0xFFB57DFF);
  static const magenta = Color(0xFFD946EF);
  static const gold = Color(0xFFFFD67A);
  static const goldDeep = Color(0xFFE8B84A);
  static const cyan = Color(0xFF22D3EE);
  static const green = Color(0xFF22C55E);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFC9BBE8);
  static const textMuted = Color(0xFF9A8BC0);

  // Ölçüler
  static const padH = 16.0;
  static const radiusSm = 14.0;
  static const radius = 20.0;
  static const radiusLg = 26.0;
  static const sectionGap = 22.0;

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bg2, bg1, bg0],
    stops: [0, 0.35, 1],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE9A8), gold, goldDeep],
  );

  static const purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, violet, magenta],
  );

  /// Ortak cam kart dekorasyonu (blur yok).
  static BoxDecoration glass({
    double radius = FortuneUi.radius,
    Color? accent,
    bool strong = false,
  }) {
    final tint = accent ?? violet;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          tint.withValues(alpha: strong ? 0.30 : 0.20),
          const Color(0xFF1A0A38).withValues(alpha: strong ? 0.85 : 0.70),
        ],
      ),
      border: Border.all(color: lilac.withValues(alpha: strong ? 0.38 : 0.22)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.30),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  // Tipografi: başlıklar Playfair (serif display), gövde sistem sans.
  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color color = textPrimary,
    double height = 1.2,
  }) {
    final base = TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      fontFamilyFallback: const ['serif', 'Roboto'],
    );
    try {
      return GoogleFonts.playfairDisplay(textStyle: base);
    } catch (_) {
      return base;
    }
  }

  static const title = TextStyle(
    color: textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  static const body = TextStyle(
    color: textSecondary,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  static const caption = TextStyle(
    color: textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );
}

/// Basınca hafif küçülen dokunma sarmalayıcısı.
class FortunePressable extends StatefulWidget {
  const FortunePressable({
    super.key,
    required this.onTap,
    required this.child,
    this.scale = 0.97,
    this.semanticLabel,
  });

  final VoidCallback? onTap;
  final Widget child;
  final double scale;
  final String? semanticLabel;

  @override
  State<FortunePressable> createState() => _FortunePressableState();
}

class _FortunePressableState extends State<FortunePressable> {
  var _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    return Semantics(
      button: onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: onTap == null ? null : (_) => _set(true),
        onTapUp: onTap == null ? null : (_) => _set(false),
        onTapCancel: onTap == null ? null : () => _set(false),
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap();
              },
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Cam kart (dokunulabilir).
class FortuneGlassCard extends StatelessWidget {
  const FortuneGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(12),
    this.radius = FortuneUi.radius,
    this.accent,
    this.strong = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? accent;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: FortuneUi.glass(
        radius: radius,
        accent: accent,
        strong: strong,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return FortunePressable(onTap: onTap, child: card);
  }
}

/// Bölüm başlığı: [ikon] BAŞLIK ........ Tümü >
class FortuneSectionHeader extends StatelessWidget {
  const FortuneSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.iconColor = FortuneUi.gold,
    this.onAll,
    this.allLabel = 'Tümü',
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onAll;
  final String allLabel;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.16),
                border: Border.all(color: iconColor.withValues(alpha: 0.5)),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FortuneUi.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            if (onAll != null)
              InkWell(
                onTap: onAll,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  child: Text(
                    '$allLabel >',
                    style: const TextStyle(
                      color: FortuneUi.lilac,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: const TextStyle(
              color: FortuneUi.lilac,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Bölüm iskeleti: üst boşluk + başlık + içerik.
class FortuneSection extends StatelessWidget {
  const FortuneSection({
    super.key,
    required this.header,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      FortuneUi.padH,
      FortuneUi.sectionGap,
      FortuneUi.padH,
      0,
    ),
  });

  final Widget header;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [header, const SizedBox(height: 12), child],
      ),
    );
  }
}

/// Fal türü kapak görseli (yerel sanat + API görseli) — kapak alanını doldurur.
class FortuneCover extends StatelessWidget {
  const FortuneCover({
    super.key,
    required this.slug,
    this.accent,
    this.imageUrl,
    this.imageWidth = 480,
  });

  final String slug;
  final Color? accent;
  final String? imageUrl;
  final int imageWidth;

  @override
  Widget build(BuildContext context) {
    return FortuneTypeCoverImage(
      slug: slug,
      accent: accent ?? FortuneTypeImages.glowColor(slug),
      imageWidth: imageWidth,
      networkUrlOverride: imageUrl,
      showOverlay: false,
    );
  }
}

/// Görsel üzerine alttan koyu perde + okunabilir başlık.
class FortuneImageScrim extends StatelessWidget {
  const FortuneImageScrim({super.key, this.strength = 0.85});

  final double strength;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.05),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.45 * strength),
            Colors.black.withValues(alpha: strength),
          ],
          stops: const [0, 0.4, 0.72, 1],
        ),
      ),
    );
  }
}

/// Büyük görselli fal kartı: görsel + alt başlık + ok. Boyutu üst widget verir.
class FortuneCategoryCard extends StatelessWidget {
  const FortuneCategoryCard({
    super.key,
    required this.slug,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.imageUrl,
    this.accent,
    this.jetonCost,
    this.compact = false,
  });

  final String slug;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final Color? accent;
  final int? jetonCost;
  final VoidCallback onTap;

  /// Küçük (3 sütun) kart: daha küçük yazı.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final glow = accent ?? FortuneTypeImages.glowColor(slug);
    final radius = compact ? FortuneUi.radiusSm : FortuneUi.radius;
    return FortunePressable(
      onTap: onTap,
      semanticLabel: title,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: glow.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: 0.16),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 1),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FortuneCover(slug: slug, accent: glow, imageUrl: imageUrl),
              const FortuneImageScrim(),
              if (jetonCost != null && jetonCost! > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: FortuneUi.gold.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      child: Text(
                        '$jetonCost',
                        style: const TextStyle(
                          color: FortuneUi.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: compact ? 8 : 12,
                right: compact ? 6 : 10,
                bottom: compact ? 8 : 10,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: compact ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 11.5 : 15,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              shadows: const [
                                Shadow(color: Colors.black87, blurRadius: 8),
                              ],
                            ),
                          ),
                          if (!compact &&
                              subtitle != null &&
                              subtitle!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: compact ? 16 : 20,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Altın gradient CTA hapı.
class FortuneGoldButton extends StatelessWidget {
  const FortuneGoldButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.compact = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool compact;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final h = compact ? 30.0 : 48.0;
    return FortunePressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: h,
        width: expand ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 22),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: FortuneUi.goldGradient,
          borderRadius: BorderRadius.circular(h / 2),
          boxShadow: [
            BoxShadow(
              color: FortuneUi.gold.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: compact ? 14 : 18,
                color: const Color(0xFF2A1450),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF2A1450),
                  fontSize: compact ? 11.5 : 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: compact ? 0 : 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bölüm içi yükleniyor / boş / hata durumu (hafif, blur'suz).
class FortuneInlineState extends StatelessWidget {
  const FortuneInlineState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.height = 96,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: height),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: FortuneUi.glass(radius: FortuneUi.radius),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 26, color: FortuneUi.textMuted),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: FortuneUi.body),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            FortuneGoldButton(
              label: actionLabel!,
              onTap: onAction!,
              compact: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// Yatay şerit iskeleti (yükleme).
class FortuneRowSkeleton extends StatelessWidget {
  const FortuneRowSkeleton({
    super.key,
    this.height = 150,
    this.itemWidth = 120,
    this.count = 3,
  });

  final double height;
  final double itemWidth;
  final int count;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, _) => Container(
            width: itemWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FortuneUi.radius),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: FortuneUi.lilac.withValues(alpha: 0.12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
