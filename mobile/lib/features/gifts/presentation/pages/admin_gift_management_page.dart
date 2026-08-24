import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../../../../core/network/api_exception.dart';
import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../../domain/admin_gift_stats.dart';
import '../../domain/admin_gift_type.dart';
import '../../domain/gift_entity.dart';
import '../providers/admin_gift_providers.dart';
import '../providers/gift_catalog_invalidate.dart';
import '../providers/gift_providers.dart';

/// Admin Hediye Yönetim Paneli — katalog CRUD ve istatistik (`/api/admin/gifts`).
/// Admin ve kurucu (yonetici) erişebilir.
class AdminGiftManagementPage extends ConsumerStatefulWidget {
  const AdminGiftManagementPage({super.key});

  static void openEditor(BuildContext context, AdminGiftType gift) {
    context.push('/admin/gifts/${gift.id}/edit', extra: gift);
  }

  @override
  ConsumerState<AdminGiftManagementPage> createState() =>
      _AdminGiftManagementPageState();
}

class _AdminGiftManagementPageState
    extends ConsumerState<AdminGiftManagementPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManageGifts) {
      return Scaffold(
        backgroundColor: const Color(0xFF0E0524),
        appBar: AppBar(
          backgroundColor: const Color(0xFF12082A),
          title: const Text('Hediye Yönetimi'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Hediye kataloğu yalnızca admin veya kurucu (yonetici) hesaplarına açıktır.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0x99FFFFFF)),
            ),
          ),
        ),
      );
    }

    final apiAccess = ref.watch(adminGiftApiAccessProvider);
    final listState = ref.watch(adminGiftListProvider);
    final showApiWarning = !apiAccess &&
        listState.hasError &&
        listState.error is ApiException &&
        ((listState.error! as ApiException).statusCode == 401 ||
            (listState.error! as ApiException).statusCode == 403);

    return Scaffold(
        backgroundColor: const Color(0xFF0E0524),
        appBar: AppBar(
          backgroundColor: const Color(0xFF12082A),
          title: const Text('Hediye Yönetimi'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Katalog'),
              Tab(text: 'İstatistik'),
            ],
          ),
        ),
        floatingActionButton: _tabController.index == 0
            ? FloatingActionButton.extended(
                backgroundColor: const Color(0xFF7C3AED),
                onPressed: () async {
                  final created = await context.push<bool>(
                    '/admin/gifts/new',
                  );
                  if (!context.mounted || created != true) return;
                  invalidateGiftCatalogProviders(ref);
                  ref.invalidate(adminGiftListProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hediye başarıyla oluşturuldu.'),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Yeni Hediye'),
              )
            : null,
        body: Column(
          children: [
            if (listState.isLoading)
              const LinearProgressIndicator(minHeight: 2),
            if (showApiWarning)
              Material(
                color: const Color(0x33FF5252),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_rounded, color: Color(0xFFFF8A80)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Admin hediye API bağlanamadı — aşağıda uygulamadaki canlı katalog gösteriliyor. '
                          'Düzenlemek için «admin» veya «yonetici» ile giriş yapıp Yenile\'ye basın.',
                          style: const TextStyle(
                            color: Color(0xFFFFCDD2),
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.invalidate(adminGiftApiAccessProvider);
                          ref.invalidate(adminGiftListProvider);
                        },
                        child: const Text('Yenile'),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  const _CatalogTab(),
                  _LazyTab(
                    active: _tabController.index == 1,
                    child: const _StatsTab(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }
}

class _LazyTab extends StatelessWidget {
  const _LazyTab({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox.shrink();
    return child;
  }
}

// ---------------------------------------------------------------------------
// Katalog
// ---------------------------------------------------------------------------
class _CatalogTab extends ConsumerWidget {
  const _CatalogTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminGiftListProvider);

    return async.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text(
              'Hediye kataloğu yükleniyor…',
              style: TextStyle(color: Color(0x99FFFFFF)),
            ),
          ],
        ),
      ),
      error: (e, _) => _ConsumerFallbackList(
        banner: ApiException.userMessage(e),
      ),
      data: (gifts) {
        if (gifts.isEmpty) {
          return _ConsumerFallbackList(
            banner: 'Admin katalog boş — uygulamadaki canlı hediyeler:',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            invalidateGiftCatalogProviders(ref);
            ref.invalidate(adminGiftListProvider);
            await ref.read(adminGiftListProvider.future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: gifts.length,
            itemBuilder: (_, i) => _GiftRow(gift: gifts[i]),
          ),
        );
      },
    );
  }
}

class _ConsumerFallbackList extends ConsumerWidget {
  const _ConsumerFallbackList({required this.banner});

  final String banner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveCatalog = ref.watch(liveGiftCatalogProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminGiftListProvider);
        ref.invalidate(liveGiftCatalogProvider);
        await Future.wait([
          ref
              .read(adminGiftListProvider.future)
              .catchError((_) => const <AdminGiftType>[]),
          ref
              .read(liveGiftCatalogProvider.future)
              .catchError((_) => const <GiftEntity>[]),
        ]);
      },
      child: liveCatalog.when(
        loading: () => ListView(
          children: const [
            SizedBox(height: 80),
            Center(child: CircularProgressIndicator()),
          ],
        ),
        error: (_, _) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(banner, style: const TextStyle(color: Color(0xFFFFCDD2))),
            const SizedBox(height: 16),
            const Text(
              'Canlı katalog da yüklenemedi.',
              style: TextStyle(color: Color(0x99FFFFFF)),
            ),
          ],
        ),
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                banner,
                style: const TextStyle(color: Color(0xFFFFE082), fontSize: 12.5),
              ),
            ),
            for (final g in items)
              ListTile(
                leading: g.iconUrl != null && g.iconUrl!.isNotEmpty
                    ? CanlifalNetworkImage(
                        url: g.iconUrl!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorWidget: const Text('🎁'),
                      )
                    : const Text('🎁', style: TextStyle(fontSize: 22)),
                title: Text(
                  g.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${g.price} jeton',
                  style: const TextStyle(color: Color(0x99FFFFFF)),
                ),
                trailing: const Icon(Icons.info_outline, color: Color(0x99FFFFFF)),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '«${g.name}» uygulamada görünüyor. '
                        'Düzenlemek için admin API bağlantısı gerekir — «Yeni Hediye» ile ekleyebilirsiniz.',
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _GiftRow extends ConsumerWidget {
  const _GiftRow({required this.gift});
  final AdminGiftType gift;

  Future<void> _patch(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> body,
  ) async {
    try {
      await ref.read(adminGiftRemoteProvider).updateGift(gift.id, body);
      invalidateGiftCatalogProviders(ref);
      ref.invalidate(adminGiftListProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiException.userMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1030),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: gift.isActive
              ? const Color(0x22FFFFFF)
              : const Color(0x33FF5252),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (gift.thumbnailUrl != null &&
                        gift.thumbnailUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CanlifalNetworkImage(
                          url: gift.thumbnailUrl!,
                          fit: BoxFit.contain,
                          width: 40,
                          height: 40,
                        ),
                      )
                    else
                      Center(
                        child: Text(
                          gift.icon ?? '🎁',
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    if (gift.hasVideoAnimation)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C4DFF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.videocam_rounded,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gift.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.monetization_on_rounded,
                          color: Color(0xFFFFD54F),
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${gift.price}',
                          style: const TextStyle(
                            color: Color(0xFFFFE082),
                            fontSize: 12,
                          ),
                        ),
                        if (gift.category != null &&
                            gift.category!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            gift.category!,
                            style: const TextStyle(
                              color: Color(0x99FFFFFF),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (gift.isPremium ||
                        gift.comboEnabled ||
                        gift.isFullscreen ||
                        !gift.isActive)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: [
                            if (gift.isPremium)
                              _badge('Premium', const Color(0xFFFFD54F)),
                            if (gift.comboEnabled)
                              _badge('Combo', const Color(0xFF66E36F)),
                            if (gift.isFullscreen)
                              _badge('Tam ekran', const Color(0xFF3D7BFF)),
                            if (!gift.isActive)
                              _badge('Pasif', const Color(0xFFFF6E6E)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFFB388FF),
                  size: 20,
                ),
                onPressed: () => AdminGiftManagementPage.openEditor(context, gift),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFFF6E6E),
                  size: 20,
                ),
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
          Row(
            children: [
              _toggle(
                ref,
                'Aktif',
                gift.isActive,
                (v) => _patch(context, ref, {'isActive': v}),
              ),
              _toggle(
                ref,
                'Gizli',
                gift.isHidden,
                (v) => _patch(context, ref, {'isHidden': v}),
              ),
              _toggle(
                ref,
                'Öne çıkan',
                gift.isFeatured,
                (v) => _patch(context, ref, {'isFeatured': v}),
              ),
              _toggle(
                ref,
                'Popüler',
                gift.isPopular,
                (v) => _patch(context, ref, {'isPopular': v}),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toggle(
    WidgetRef ref,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Expanded(
      child: Column(
        children: [
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: value,
              activeThumbColor: const Color(0xFF66E36F),
              onChanged: onChanged,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 9.5),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hediyeyi sil'),
        content: Text(
          '"${gift.name}" silinecek. Depodaki dosyalar da silinir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminGiftRemoteProvider).deleteGift(gift.id);
      ref.invalidate(adminGiftListProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiException.userMessage(e))));
      }
    }
  }
}

// ---------------------------------------------------------------------------
// İstatistik
// ---------------------------------------------------------------------------
class _StatsTab extends ConsumerStatefulWidget {
  const _StatsTab();
  @override
  ConsumerState<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends ConsumerState<_StatsTab> {
  String _period = 'all';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminGiftStatsProvider(_period));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final p in const [
                  ('all', 'Tümü'),
                  ('daily', 'Gün'),
                  ('weekly', 'Hafta'),
                  ('monthly', 'Ay'),
                  ('yearly', 'Yıl'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(p.$2),
                      selected: _period == p.$1,
                      onSelected: (_) => setState(() => _period = p.$1),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                ApiException.userMessage(e),
                style: const TextStyle(color: Color(0x99FFFFFF)),
              ),
            ),
            data: (s) => RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(adminGiftStatsProvider(_period)),
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  Row(
                    children: [
                      _StatCard(
                        label: 'Toplam Hediye',
                        value: compactAmount(s.totalGifts),
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        label: 'Toplam Jeton',
                        value: compactAmount(s.totalCoins),
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        label: 'Site Geliri',
                        value: compactAmount(s.siteRevenue),
                        highlight: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _RankList(title: 'En Çok Gönderilen', rows: s.topSent),
                  const SizedBox(height: 18),
                  _RankList(title: 'En Çok Kazananlar', rows: s.topEarners),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.highlight = false,
  });
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: highlight ? const Color(0x337C3AED) : const Color(0xFF1A1030),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight
                ? const Color(0x887C3AED)
                : const Color(0x22FFFFFF),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankList extends StatelessWidget {
  const _RankList({required this.title, required this.rows});
  final String title;
  final List<AdminGiftRankRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          const Text('Veri yok.', style: TextStyle(color: Color(0x99FFFFFF)))
        else
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Color(0xFFFFD54F),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  Text(
                    compactAmount(rows[i].value),
                    style: const TextStyle(
                      color: Color(0xFFFFE082),
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
