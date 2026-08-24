import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../../../cosmetics/domain/cosmetic_item.dart';
import '../../domain/admin_collection_sample_catalog.dart';
import '../../domain/achievement_badge_sample.dart';
import '../../../voice_hub/domain/voice_room_theme_catalog.dart';
import '../../presentation/providers/staff_access_provider.dart';

/// Admin — hediye & koleksiyon örnek kataloğu (arkaplan, tema, kozmetik, rozet).
class AdminGiftCollectionHubPage extends ConsumerStatefulWidget {
  const AdminGiftCollectionHubPage({super.key});

  @override
  ConsumerState<AdminGiftCollectionHubPage> createState() =>
      _AdminGiftCollectionHubPageState();
}

class _AdminGiftCollectionHubPageState
    extends ConsumerState<AdminGiftCollectionHubPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  static const _tabOrder = AdminCollectionTab.values;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _tabOrder.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManageGifts) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hediye & Koleksiyon')),
        body: const Center(
          child: Text('Yalnızca admin veya yönetici erişebilir.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0524),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12082A),
        title: const Text('Hediye & Koleksiyon'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            for (final tab in _tabOrder)
              Tab(
                text:
                    '${tab.label} (${AdminCollectionSampleCatalog.countForTab(tab)})',
              ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _BackgroundGrid(items: AdminCollectionSampleCatalog.backgroundEffects()),
          _ThemeGrid(themes: AdminCollectionSampleCatalog.roomThemes()),
          _CosmeticGrid(items: AdminCollectionSampleCatalog.avatarAccessories()),
          _CosmeticGrid(items: AdminCollectionSampleCatalog.microphoneFrames()),
          _CosmeticGrid(items: AdminCollectionSampleCatalog.chatBubbles()),
          _CosmeticGrid(items: AdminCollectionSampleCatalog.nameEffects()),
          _CosmeticGrid(items: AdminCollectionSampleCatalog.membershipBadges()),
          _CosmeticGrid(items: AdminCollectionSampleCatalog.profileFrames()),
          _BadgeGrid(badges: AdminCollectionSampleCatalog.achievementBadges()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/gifts'),
        icon: const Icon(Icons.card_giftcard),
        label: const Text('Hediye kataloğu'),
      ),
    );
  }
}

class _BackgroundGrid extends StatelessWidget {
  const _BackgroundGrid({required this.items});

  final List<AdminSampleItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return _SampleCard(
          title: item.name,
          subtitle: item.tags.join(' · '),
          imageUrl: item.previewUrl,
        );
      },
    );
  }
}

class _ThemeGrid extends StatelessWidget {
  const _ThemeGrid({required this.themes});

  final List<VoiceRoomTheme> themes;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: themes.length,
      itemBuilder: (context, i) {
        final t = themes[i];
        return _SampleCard(
          title: t.name,
          subtitle: t.id,
          imageUrl: t.backgroundUrl,
          overlay: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(t.primaryColor),
                  Color(t.secondaryColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CosmeticGrid extends StatelessWidget {
  const _CosmeticGrid({required this.items});

  final List<CosmeticItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return _SampleCard(
          title: item.name,
          subtitle: item.effectKind.name,
          imageUrl: item.previewUrl,
        );
      },
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.badges});

  final List<AchievementBadgeSample> badges;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: badges.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final b = badges[i];
        return ListTile(
          tileColor: const Color(0xFF1A1035),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF7C3AED),
            child: Text(b.iconEmoji, style: const TextStyle(fontSize: 20)),
          ),
          title: Text(
            b.name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '${b.description} · ${b.tier}',
            style: const TextStyle(color: Color(0x99FFFFFF)),
          ),
        );
      },
    );
  }
}

class _SampleCard extends StatelessWidget {
  const _SampleCard({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.overlay,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x337C3AED)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl != null)
                  CanlifalNetworkImage(
                    url: imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: overlay ?? _placeholder(),
                  )
                else
                  overlay ?? _placeholder(),
                if (overlay != null && imageUrl != null)
                  overlay!,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF2A1B4E),
      child: const Center(
        child: Icon(Icons.auto_awesome, color: Color(0xFF7C3AED)),
      ),
    );
  }
}
