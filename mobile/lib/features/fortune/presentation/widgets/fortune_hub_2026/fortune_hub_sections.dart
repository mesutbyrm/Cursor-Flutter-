import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../bana_ozel/presentation/navigation/bana_ozel_navigation.dart';
import '../../../../bana_ozel/presentation/providers/bana_ozel_providers.dart';
import '../../data/fortune_catalog.dart';
import '../../navigation/fortune_card_navigation.dart';
import '../../providers/fortune_api_providers.dart';
import '../../providers/fortune_hub_providers.dart';
import '../../providers/fortune_types_display_provider.dart';
import 'fortune_hub_kit.dart';

/// Kartları tek satır `Row`lar halinde dizer (iç içe kaydırma yok).
class FortuneGridRows extends StatelessWidget {
  const FortuneGridRows({
    super.key,
    required this.children,
    required this.columns,
    this.aspectRatio,
    this.spacing = 10,
  });

  final List<Widget> children;
  final int columns;

  /// Verilirse kartlar sabit orandadır; `null` ise satır yüksekliği içeriğe
  /// göre belirlenir (yazı büyütmede taşmayı önler).
  final double? aspectRatio;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    final ratio = aspectRatio;
    for (var i = 0; i < children.length; i += columns) {
      final row = Row(
        crossAxisAlignment: ratio == null
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.center,
        children: [
          for (var c = 0; c < columns; c++) ...[
            if (c > 0) SizedBox(width: spacing),
            Expanded(
              child: i + c < children.length
                  ? (ratio == null
                        ? children[i + c]
                        : AspectRatio(
                            aspectRatio: ratio,
                            child: children[i + c],
                          ))
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      );
      rows.add(ratio == null ? IntrinsicHeight(child: row) : row);
      if (i + columns < children.length) {
        rows.add(SizedBox(height: spacing));
      }
    }
    return Column(children: rows);
  }
}

/// "2 gün önce" tarzı kısa göreli tarih.
String fortuneRelativeDate(DateTime? date, {DateTime? now}) {
  if (date == null) return '';
  final diff = (now ?? DateTime.now()).difference(date);
  if (diff.isNegative || diff.inMinutes < 1) return 'Az önce';
  if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
  if (diff.inHours < 24) return '${diff.inHours} saat önce';
  if (diff.inDays == 1) return 'Dün';
  if (diff.inDays < 7) return '${diff.inDays} gün önce';
  if (diff.inDays < 30) return '${diff.inDays ~/ 7} hafta önce';
  if (diff.inDays < 365) return '${diff.inDays ~/ 30} ay önce';
  return '${diff.inDays ~/ 365} yıl önce';
}

/// Hızlı erişim — 3 × 2 cam kart.
class FortuneHubQuickGrid extends StatelessWidget {
  const FortuneHubQuickGrid({super.key});

  static const _items = <_Quick>[
    _Quick(
      'Hazır\nYorumlar',
      Icons.menu_book_rounded,
      FortuneUi.gold,
      '/fortune/ready',
    ),
    _Quick(
      'Fal\nGeçmişim',
      Icons.history_rounded,
      FortuneUi.lilac,
      '/favorites',
    ),
    _Quick(
      'Canlı\nFalcılar',
      Icons.person_rounded,
      FortuneUi.cyan,
      '/canli-falcilar',
    ),
    _Quick(
      'Bana\nÖzel',
      Icons.auto_fix_high_rounded,
      FortuneUi.green,
      '/fortune/bana-ozel',
    ),
    _Quick(
      'Burç\nUyumu',
      Icons.favorite_rounded,
      Color(0xFFF472B6),
      '/astrology/compatibility',
    ),
    _Quick(
      'Rüya\nYarışması',
      Icons.emoji_events_rounded,
      FortuneUi.goldDeep,
      '/dreams/contest',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(FortuneUi.padH, 14, FortuneUi.padH, 0),
      child: FortuneGridRows(
        columns: 3,
        children: [
          for (final q in _items)
            FortuneGlassCard(
              onTap: () => context.push(q.route),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: q.color.withValues(alpha: 0.16),
                      border: Border.all(
                        color: q.color.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Icon(q.icon, color: q.color, size: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
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

class _Quick {
  const _Quick(this.label, this.icon, this.color, this.route);

  final String label;
  final IconData icon;
  final Color color;
  final String route;
}

/// Günlük kehanet — 3 yatay kart (günlük fal / burç / enerji).
class FortuneHubDailyProphecy extends StatelessWidget {
  const FortuneHubDailyProphecy({super.key});

  static const _items = <({String slug, String title, String route})>[
    (slug: 'tarot', title: 'Günlük\nTarot Kartı', route: '/fortune/gunluk-fal'),
    (
      slug: 'yildiz-haritasi',
      title: 'Günlük\nBurç Yorumu',
      route: '/fortune/yildiz-haritasi',
    ),
    (slug: 'aura', title: 'Günün\nEnerjisi', route: '/fortune/aura-analizi'),
  ];

  @override
  Widget build(BuildContext context) {
    return FortuneSection(
      header: FortuneSectionHeader(
        title: 'GÜNLÜK KEHANET',
        icon: Icons.auto_awesome_rounded,
        iconColor: Color(0xFFF472B6),
        onAll: () => openFortuneTypesCatalog(context),
        allLabel: 'Tümünü Gör',
      ),
      child: FortuneGridRows(
        columns: 3,
        aspectRatio: 0.62,
        children: [
          for (final it in _items)
            FortunePressable(
              onTap: () => context.push(it.route),
              semanticLabel: it.title.replaceAll('\n', ' '),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(FortuneUi.radius),
                  border: Border.all(
                    color: FortuneUi.gold.withValues(alpha: 0.4),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(FortuneUi.radius - 1),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FortuneCover(slug: it.slug),
                      const FortuneImageScrim(),
                      Positioned(
                        left: 6,
                        right: 6,
                        bottom: 8,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              it.title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                                shadows: [
                                  Shadow(color: Colors.black87, blurRadius: 8),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const _MiniGold(label: 'Şimdi Bak'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniGold extends StatelessWidget {
  const _MiniGold({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: FortuneUi.goldGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          color: Color(0xFF2A1450),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// Son fallar — gerçek `fortuneHistoryProvider` yatay şeridi.
class FortuneHubRecentReadings extends ConsumerWidget {
  const FortuneHubRecentReadings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(fortuneHistoryProvider);
    const cardW = 124.0;
    const cardH = 150.0;

    return FortuneSection(
      header: FortuneSectionHeader(
        title: 'SON FALLARIN',
        icon: Icons.history_rounded,
        iconColor: FortuneUi.lilac,
        onAll: () => context.push('/favorites'),
      ),
      child: history.when(
        loading: () =>
            const FortuneRowSkeleton(height: cardH, itemWidth: cardW),
        error: (_, _) => FortuneInlineState(
          icon: Icons.cloud_off_rounded,
          message: 'Son fallar yüklenemedi',
          actionLabel: 'Tekrar dene',
          onAction: () => ref.invalidate(fortuneHistoryProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return FortuneInlineState(
              icon: Icons.history_rounded,
              message: 'Henüz fal geçmişi yok',
              actionLabel: 'Fal baktır',
              onAction: () => context.push('/fortune/tarot'),
            );
          }
          final list = items.take(10).toList();
          return SizedBox(
            height: cardH,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final item = list[i];
                final slug = item.slug ?? '';
                final catalog = FortuneCatalog.bySlug(slug);
                final title = catalog?.title ?? item.displayTitle;
                return SizedBox(
                  width: cardW,
                  child: FortunePressable(
                    onTap: () => slug.isNotEmpty
                        ? context.push('/fortune/$slug')
                        : context.push('/favorites'),
                    semanticLabel: title,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(FortuneUi.radius),
                        border: Border.all(
                          color: FortuneUi.lilac.withValues(alpha: 0.4),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          FortuneUi.radius - 1,
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            FortuneCover(
                              slug: slug.isNotEmpty ? slug : 'tarot',
                              accent: catalog?.accent,
                            ),
                            const FortuneImageScrim(),
                            Positioned(
                              left: 10,
                              right: 8,
                              bottom: 9,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          fortuneRelativeDate(item.createdAt),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.72,
                                            ),
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        size: 16,
                                        color: Colors.white70,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Popüler fal türleri — 2 sütun büyük görsel kartlar.
class FortuneHubPopularTypes extends ConsumerWidget {
  const FortuneHubPopularTypes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(fortuneHubSearchQueryProvider);
    final entries = FortuneCatalog.hubFortuneTypes
        .where(
          (e) => fortuneHubMatchesSearch(
            query: query,
            title: e.type.title,
            slug: e.type.slug,
            subtitle: e.subtitle,
          ),
        )
        .take(6)
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return FortuneSection(
      header: FortuneSectionHeader(
        title: 'POPÜLER FAL TÜRLERİ',
        icon: Icons.local_fire_department_rounded,
        iconColor: FortuneUi.goldDeep,
        onAll: () => openFortuneTypesCatalog(context),
      ),
      child: FortuneGridRows(
        columns: 2,
        aspectRatio: 1.22,
        children: [
          for (final e in entries)
            FortuneCategoryCard(
              slug: e.type.slug,
              title: e.type.title,
              accent: e.type.accent,
              onTap: () => context.push('/fortune/${e.type.slug}'),
            ),
        ],
      ),
    );
  }
}

/// Sana özel öneri bandı — gerçek Bana Özel kataloğunun ilk içeriği.
class FortuneHubForYouBanner extends ConsumerWidget {
  const FortuneHubForYouBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(banaOzelCatalogProvider);
    final item = catalog.valueOrNull?.items.isNotEmpty == true
        ? catalog.valueOrNull!.items.first
        : null;
    if (item == null) return const SizedBox.shrink();

    final desc = item.descTr?.trim();
    return FortuneSection(
      header: FortuneSectionHeader(
        title: 'SANA ÖZEL ÖNERİLER',
        icon: Icons.favorite_rounded,
        iconColor: const Color(0xFFF472B6),
        onAll: () => openBanaOzelCatalog(context),
      ),
      child: FortuneGlassCard(
        onTap: () => openBanaOzelCatalog(context, slug: item.slug),
        strong: true,
        accent: FortuneUi.magenta,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FortuneUi.magenta.withValues(alpha: 0.2),
                border: Border.all(
                  color: FortuneUi.magenta.withValues(alpha: 0.6),
                ),
              ),
              child: Text(item.icon, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.nameTr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  if (desc != null && desc.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: FortuneUi.body,
                      ),
                    ),
                  const SizedBox(height: 10),
                  FortuneGoldButton(
                    label: 'Hemen Bak',
                    compact: true,
                    onTap: () => openBanaOzelCatalog(context, slug: item.slug),
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

/// Tüm fal türleri — 3 sütun (gerçek API / katalog vitrini).
class FortuneHubAllTypes extends ConsumerWidget {
  const FortuneHubAllTypes({super.key, this.limit = 12});

  /// Hub'da gösterilecek en fazla tür; arama açıkken tüm eşleşmeler.
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(fortuneTypesDisplayProvider);
    final query = ref.watch(fortuneHubSearchQueryProvider);

    return FortuneSection(
      header: FortuneSectionHeader(
        title: 'TÜM FAL TÜRLERİ',
        icon: Icons.auto_awesome_mosaic_rounded,
        iconColor: FortuneUi.lilac,
        subtitle: 'Kategoriye dokun — detay ve hizmetler',
        onAll: () => openFortuneTypesCatalog(context),
      ),
      child: entries.when(
        loading: () => FortuneGridRows(
          columns: 3,
          aspectRatio: 0.95,
          children: [
            for (var i = 0; i < 6; i++)
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(FortuneUi.radiusSm),
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: FortuneUi.lilac.withValues(alpha: 0.12),
                  ),
                ),
              ),
          ],
        ),
        error: (_, _) => FortuneInlineState(
          icon: Icons.refresh_rounded,
          message: 'Fal türleri yüklenemedi',
          actionLabel: 'Tekrar dene',
          onAction: () => invalidateFortuneTypesDisplay(ref),
        ),
        data: (list) {
          final filtered = list
              .where(
                (e) => fortuneHubMatchesSearch(
                  query: query,
                  title: e.title,
                  slug: e.slug,
                  subtitle: e.subtitle,
                ),
              )
              .toList();
          if (filtered.isEmpty) {
            return FortuneInlineState(
              icon: query.trim().isEmpty
                  ? Icons.auto_awesome_rounded
                  : Icons.search_off_rounded,
              message: query.trim().isEmpty
                  ? 'Şu anda fal türleri bulunamadı'
                  : 'Aramana uygun fal türü bulunamadı',
              actionLabel: query.trim().isEmpty ? 'Yenile' : null,
              onAction: query.trim().isEmpty
                  ? () => invalidateFortuneTypesDisplay(ref)
                  : null,
            );
          }
          final shown = query.trim().isEmpty
              ? filtered.take(limit).toList()
              : filtered;
          return FortuneGridRows(
            columns: 3,
            aspectRatio: 0.95,
            children: [
              for (final e in shown)
                FortuneCategoryCard(
                  slug: e.slug,
                  title: e.title,
                  imageUrl: e.imageUrl,
                  accent: e.accent,
                  jetonCost: e.jetonCost,
                  compact: true,
                  onTap: () => openFortuneTypeDestination(context, e),
                ),
            ],
          );
        },
      ),
    );
  }
}
