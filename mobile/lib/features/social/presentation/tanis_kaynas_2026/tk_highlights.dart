import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/social_discovery_providers.dart';
import 'tk_common.dart';
import 'tk_palette.dart';

/// Etkinlik sayaçları — seni beğenenler / eşleşmeler / gönderdiklerin.
/// Veriler: `fetchIncomingLikes`, `fetchMatches`, `fetchSentLikes`.
class TkActivityStatsStrip extends ConsumerWidget {
  const TkActivityStatsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int? count(AsyncValue<List<Object>> v) => v.valueOrNull?.length;
    final incoming = count(ref.watch(socialDiscoveryIncomingLikesProvider));
    final matches = count(ref.watch(socialDiscoveryMatchesProvider));
    final sent = count(ref.watch(socialDiscoverySentLikesProvider));
    void open(int tab) =>
        context.push('/social/tanis-kaynas/activity?tab=$tab');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              key: const Key('tk-stat-incoming'),
              icon: Icons.favorite_rounded,
              colors: const [Color(0xFFFF4D8D), Color(0xFFE63BD6)],
              value: incoming,
              label: 'Seni beğenen',
              onTap: () => open(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              key: const Key('tk-stat-matches'),
              icon: Icons.handshake_rounded,
              colors: const [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
              value: matches,
              label: 'Eşleşme',
              onTap: () => open(1),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              key: const Key('tk-stat-sent'),
              icon: Icons.send_rounded,
              colors: const [Color(0xFF3B82F6), Color(0xFF22D3EE)],
              value: sent,
              label: 'Gönderdiğin',
              onTap: () => open(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    super.key,
    required this.icon,
    required this.colors,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final List<Color> colors;
  final int? value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = TkPalette.of(context);
    return TkPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.border),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.first.withValues(alpha: p.isDark ? 0.28 : 0.18),
              colors.last.withValues(alpha: p.isDark ? 0.12 : 0.08),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: colors),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              value == null ? '—' : '$value',
              style: TextStyle(
                color: p.text,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: p.textMuted, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Görselli hızlı erişim — uyum, aşk falı, sesli odalar, hikâye, eşleşmeler.
class TkQuickActionsGrid extends StatelessWidget {
  const TkQuickActionsGrid({super.key, required this.onAddStory});

  final VoidCallback onAddStory;

  @override
  Widget build(BuildContext context) {
    final items = <_QuickItem>[
      _QuickItem(
        label: 'Burç Uyumu',
        image: 'assets/zodiac/ikizler.webp',
        colors: const [Color(0xFFEC4899), Color(0xFFF97316)],
        onTap: () => context.push('/astrology/compatibility'),
      ),
      _QuickItem(
        label: 'Aşk Falı',
        image: 'assets/fortune/ask-fali.webp',
        colors: const [Color(0xFFFF4D8D), Color(0xFFE63BD6)],
        onTap: () => context.push('/fortune'),
      ),
      _QuickItem(
        label: 'Sesli Sohbet',
        image: 'assets/fortune/aura-analizi.webp',
        colors: const [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
        onTap: () => context.push('/voice-rooms'),
      ),
      _QuickItem(
        label: 'Hikâye Paylaş',
        image: 'assets/fortune/yildiz-haritasi.webp',
        colors: const [Color(0xFF22D3EE), Color(0xFF8B5CF6)],
        onTap: onAddStory,
      ),
      _QuickItem(
        label: 'Eşleşmelerim',
        image: 'assets/fortune/melek-kartlari.webp',
        colors: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
        onTap: () => context.push('/social/tanis-kaynas/activity?tab=1'),
      ),
      _QuickItem(
        label: 'Hediye Gönder',
        image: 'assets/games/scratch.webp',
        colors: const [Color(0xFFF43F5E), Color(0xFFEC4899)],
        onTap: () => context.push('/hediye-yolla'),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TkSectionHeader(
            title: 'Keşfet & Eğlen',
            subtitle: 'Uyumunu ölç, sohbete katıl, hikâyeni paylaş',
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, c) {
              const gap = 10.0;
              final cols = c.maxWidth >= 560 ? 6 : 3;
              final w = (c.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final it in items)
                    SizedBox(width: w, child: _QuickTile(item: it)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickItem {
  const _QuickItem({
    required this.label,
    required this.image,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final String image;
  final List<Color> colors;
  final VoidCallback onTap;
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.item});

  final _QuickItem item;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return TkPressable(
      onTap: item.onTap,
      semanticLabel: item.label,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: item.colors),
                ),
              ),
              Image.asset(
                item.image,
                fit: BoxFit.cover,
                cacheWidth: 240,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      item.colors.last.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.78),
                    ],
                    stops: const [0.25, 0.6, 1],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Günün buz kırıcı sorusu — gün değiştikçe döner; «Sonraki» ile gezilir,
/// «Kopyala» ile sohbete yapıştırılır. Sunucu gerektirmez.
class TkIcebreakerCard extends StatefulWidget {
  const TkIcebreakerCard({super.key, this.today});

  /// Test için sabit gün.
  final DateTime? today;

  static const questions = <String>[
    'Hayatında seni en çok güldüren an hangisiydi?',
    'Bir gün boyunca istediğin yerde olabilsen nereye giderdin?',
    'En sevdiğin şarkının sana hatırlattığı bir anı var mı?',
    'Kahve falında en çok neyi görmek isterdin?',
    'Hafta sonu için ideal planın ne olurdu?',
    'Burcunun en çok sana uyan özelliği hangisi?',
    'Çocukken büyüyünce ne olmak istiyordun?',
    'Son okuduğun ya da izlediğin ve önerdiğin şey ne?',
    'Bir süper gücün olsa hangisini seçerdin?',
    'Seni en iyi anlatan üç kelime ne?',
    'Hiç unutamadığın bir rüyan var mı?',
    'Mükemmel bir akşam yemeği masasında kimler olurdu?',
    'Yeni öğrenmek istediğin bir hobi var mı?',
    'Seni anında mutlu eden küçük bir şey nedir?',
  ];

  @override
  State<TkIcebreakerCard> createState() => _TkIcebreakerCardState();
}

class _TkIcebreakerCardState extends State<TkIcebreakerCard> {
  late int _index;

  @override
  void initState() {
    super.initState();
    final d = widget.today ?? DateTime.now();
    final dayOfYear = d.difference(DateTime(d.year)).inDays;
    _index = dayOfYear % TkIcebreakerCard.questions.length;
  }

  String get _question => TkIcebreakerCard.questions[_index];

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _question));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 2),
        content: Text('Soru kopyalandı — sohbete yapıştırabilirsin'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = TkPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: p.border),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              TkPalette.purple.withValues(alpha: p.isDark ? 0.30 : 0.14),
              TkPalette.pink.withValues(alpha: p.isDark ? 0.18 : 0.08),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💬', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Günün buz kırıcı sorusu',
                    style: TextStyle(
                      color: p.text,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                _question,
                key: ValueKey(_index),
                style: TextStyle(
                  color: p.text,
                  fontSize: 15,
                  height: 1.35,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              children: [
                TextButton.icon(
                  key: const Key('tk-icebreaker-next'),
                  onPressed: () => setState(
                    () => _index =
                        (_index + 1) % TkIcebreakerCard.questions.length,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Sonraki'),
                ),
                TextButton.icon(
                  onPressed: _copy,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Kopyala'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
