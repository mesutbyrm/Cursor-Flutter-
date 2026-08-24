import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../../../../core/performance/list_perf.dart';
import '../../domain/gift_collection.dart';
import '../../domain/supporter_badge.dart';
import '../providers/gift_insights_providers.dart';
import '../widgets/supporter_badge_pill.dart';

/// Destekçi profili — rozet + koleksiyon (tamamlanma %) + albüm.
/// userId boşsa kendi profilim.
class GiftCollectionPage extends ConsumerWidget {
  const GiftCollectionPage({super.key, this.userId});

  final String? userId;

  bool get _isSelf => userId == null || userId!.isEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badge = ref.watch(supporterBadgeProvider(_isSelf ? null : userId));
    final uid = userId ?? '';
    final collection =
        _isSelf ? null : ref.watch(giftCollectionProvider(uid));
    final album = _isSelf ? null : ref.watch(giftAlbumProvider(uid));

    return Scaffold(
      backgroundColor: const Color(0xFF0E0524),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12082A),
        title: Text(_isSelf ? 'Destekçi Profilim' : 'Destekçi Profili'),
        actions: [
          if (_isSelf)
            IconButton(
              tooltip: 'Hediye Geçmişim',
              icon: const Icon(Icons.history_rounded),
              onPressed: () => context.push('/gifts/history'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(supporterBadgeProvider(_isSelf ? null : userId));
          if (!_isSelf) {
            ref.invalidate(giftCollectionProvider(uid));
            ref.invalidate(giftAlbumProvider(uid));
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            badge.when(
              data: (b) => b == null
                  ? const SizedBox.shrink()
                  : _BadgeHeader(badge: b),
              loading: () => const _Loading(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            if (!_isSelf && collection != null) ...[
              const SizedBox(height: 18),
              collection.when(
                data: (c) => _CollectionSection(collection: c),
                loading: () => const _Loading(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
            if (!_isSelf && album != null) ...[
              const SizedBox(height: 18),
              album.when(
                data: (a) => _AlbumSection(album: a),
                loading: () => const _Loading(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BadgeHeader extends StatelessWidget {
  const _BadgeHeader({required this.badge});
  final SupporterBadge badge;

  @override
  Widget build(BuildContext context) {
    final current = badge.current;
    final next = badge.next;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A1660), Color(0xFF14093A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (current != null)
                SupporterBadgePill(code: current.code, label: current.label),
              const Spacer(),
              Text(
                '${badge.totalSentDisplay} jeton',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${badge.totalGifts} hediye gönderildi',
            style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
          ),
          if (next != null && (next.remaining ?? 0) > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: badge.progressToNext,
                minHeight: 8,
                backgroundColor: const Color(0x33FFFFFF),
                valueColor: AlwaysStoppedAnimation<Color>(
                  SupporterBadgeStyle.of(next.code).color,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${next.label} rozetine ${next.remaining} jeton kaldı',
              style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11.5),
            ),
          ],
          if (badge.allTiers.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in badge.allTiers)
                  SupporterBadgePill(code: t.code, label: t.label, compact: true),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CollectionSection extends StatelessWidget {
  const _CollectionSection({required this.collection});
  final GiftCollection collection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          'Koleksiyon',
          trailing:
              '${collection.distinctReceived}/${collection.totalGiftTypes} · %${collection.percent}',
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: collection.totalGiftTypes == 0
                ? 0
                : collection.percent / 100,
            minHeight: 8,
            backgroundColor: const Color(0x33FFFFFF),
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFFB388FF)),
          ),
        ),
        const SizedBox(height: 12),
        if (collection.received.isEmpty)
          const Text('Henüz hediye alınmamış.',
              style: TextStyle(color: Color(0x99FFFFFF)))
        else
          _GiftGrid(items: collection.received),
      ],
    );
  }
}

class _AlbumSection extends StatelessWidget {
  const _AlbumSection({required this.album});
  final GiftAlbum album;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Albüm', trailing: '${album.totalDistinct} tür'),
        const SizedBox(height: 12),
        if (album.items.isEmpty)
          const Text('Albüm boş.',
              style: TextStyle(color: Color(0x99FFFFFF)))
        else
          _GiftGrid(items: album.items),
      ],
    );
  }
}

class _GiftGrid extends StatelessWidget {
  const _GiftGrid({required this.items});
  final List<GiftCollectionItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 4;
        const spacing = 8.0;
        const aspect = 0.82;
        final gridHeight = ListPerf.nestedGridHeight(
          itemCount: items.length,
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: aspect,
          crossAxisExtent: constraints.maxWidth,
        );
        return SizedBox(
          height: gridHeight,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: aspect,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final it = items[i];
              return Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0x22FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: it.iconUrl != null && it.iconUrl!.isNotEmpty
                          ? CanlifalNetworkImage(
                              url: it.iconUrl!, fit: BoxFit.contain)
                          : const Icon(Icons.card_giftcard_rounded,
                              color: Color(0xFFB388FF), size: 30),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      it.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    if (it.count > 0)
                      Text(
                        '×${it.count}',
                        style: const TextStyle(
                          color: Color(0xFFFFD54F),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.trailing});
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
          ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
}
