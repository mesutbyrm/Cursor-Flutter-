
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/images/canlifal_network_image.dart';
import '../../../../feed/domain/entities/post_entity.dart';
import '../../../../fortune/presentation/data/fortune_catalog.dart';
import '../../../../fortune/presentation/widgets/fortune_type_cover_image.dart';
import '../../providers/fortune_type_counts_provider.dart';
import '../social_linked_caption_text.dart';

/// Fal paylaşımı tam ekran: falın türüne ait görsel (Tarot → tarot görseli)
/// arka planda; başlık, yorum metni ve «Devamını oku» ile tüm açılım.
class SocialFortunePage extends StatelessWidget {
  const SocialFortunePage({
    super.key,
    required this.post,
    required this.text,
    required this.topInset,
    required this.bottomInset,
    this.imageUrl,
  });

  final PostEntity post;
  final String text;
  final String? imageUrl;
  final double topInset;
  final double bottomInset;

  /// Fal türünü gönderiden çöz: slug / tür / metindeki «X Falı baktırdı».
  static ({String slug, String title, Color accent}) resolveType(PostEntity post) {
    final candidates = <String>[
      post.fortuneSlug ?? '',
      post.fortuneType ?? '',
    ];
    for (final c in candidates) {
      if (c.trim().isEmpty) continue;
      final t = FortuneCatalog.bySlug(c.trim());
      if (t != null) return (slug: t.slug, title: t.title, accent: t.accent);
    }
    final hay = '${post.fortuneType ?? ''} ${post.caption ?? ''}'.toLowerCase();
    for (final t in FortuneCatalog.types) {
      if (hay.contains(t.title.toLowerCase()) || hay.contains(t.slug)) {
        return (slug: t.slug, title: t.title, accent: t.accent);
      }
    }
    const fallback = 'tarot';
    final t = FortuneCatalog.bySlug(fallback);
    return (
      slug: t?.slug ?? fallback,
      title: 'Fal',
      accent: t?.accent ?? const Color(0xFF8B5CF6),
    );
  }

  void _openFull(BuildContext context, String title) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12101C),
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
          children: [
            Text(
              '🔮 $title',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            SocialLinkedCaptionText(
              text: text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.5,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = resolveType(post);
    final img = imageUrl;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Arka plan: kullanıcının görseli (ör. kahve fincanı) ya da fal türü görseli.
        // Ekran çözünürlüğünde (en çok 2048 px) çözülür: net görünür, büyük
        // görsellerde bellek taşması (çökme) olmaz.
        if (img != null)
          CanlifalNetworkImage(url: img, fit: BoxFit.cover)
        else
          FortuneTypeCoverImage(
            slug: type.slug,
            accent: type.accent,
            imageWidth: 1600,
            showOverlay: false,
          ),
        // Okunabilirlik: bulanıklık YOK (görsel bozuk görünüyordu); yalnız
        // altta yoğunlaşan koyu geçiş.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.15),
                Colors.black.withValues(alpha: 0.40),
                Colors.black.withValues(alpha: 0.80),
              ],
              stops: const [0, 0.5, 1],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, topInset + 64, 84, bottomInset + 84),
          child: LayoutBuilder(
            builder: (context, box) {
              // Ekrana sığan satır sayısı; taşarsa «Devamını oku».
              // Başlık + «Devamını oku» + alttaki sayaç kartı için yer ayrılır.
              final maxLines = ((box.maxHeight - 190) / 26).floor().clamp(4, 40);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fal türü başlığı üstte, tam ortada.
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: type.accent.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: type.accent.withValues(alpha: 0.5),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Text(
                      '🔮 ${type.title}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  ),
                  const SizedBox(height: 18),
                  Flexible(
                    child: SocialLinkedCaptionText(
                      text: text.isEmpty ? '…' : text,
                      maxLines: maxLines,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _openFull(context, type.title),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.menu_book_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Devamını oku',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Alttaki boşluk: bu fala kaç kişinin baktırdığı.
                  _FortuneTypeCountLine(
                    slug: type.slug,
                    title: type.title,
                    accent: type.accent,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// «👥 1.245 kişi Tarot Falı baktırdı» — paylaşımın altındaki boşluğu dolduran
/// kart. Sayı yüklenmediyse / sıfırsa davet metni gösterilir (alan boş kalmaz).
class _FortuneTypeCountLine extends ConsumerWidget {
  const _FortuneTypeCountLine({
    required this.slug,
    required this.title,
    required this.accent,
  });

  final String slug;
  final String title;
  final Color accent;

  static String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(fortuneTypeCountsProvider).valueOrNull?[slug] ?? 0;
    final label = title == 'Fal' ? 'bu falı' : title;
    final hasCount = n > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.55),
            Colors.black.withValues(alpha: 0.35),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.35),
            ),
            child: Icon(
              hasCount ? Icons.groups_rounded : Icons.auto_awesome_rounded,
              color: const Color(0xFFFFD54F),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasCount ? '${_fmt(n)} kişi' : 'Sen de baktır',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  hasCount
                      ? '$label baktırdı'
                      : '$label seni bekliyor',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fal türü kapak görseli (Keşfet kutusu vb.).
class SocialFortuneCover extends StatelessWidget {
  const SocialFortuneCover({super.key, required this.slug, required this.accent});

  final String slug;
  final Color accent;

  @override
  Widget build(BuildContext context) => FortuneTypeCoverImage(
        slug: slug,
        accent: accent,
        imageWidth: 400,
        showOverlay: false,
      );
}
