import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../vip_gold/domain/vip_tier.dart';
import '../../../vip_gold/presentation/providers/vip_membership_provider.dart';
import '../../domain/cosmetic_catalog_defaults.dart';
import '../../domain/cosmetic_item.dart';
import '../../domain/cosmetic_slot.dart';
import '../providers/cosmetics_providers.dart';
import '../widgets/cosmetic_avatar_frame.dart';
import '../widgets/cosmetic_name_label.dart';

/// Gold+ — profil çerçevesi, isim ve profil efekti seçimi.
class ProfileCosmeticsPage extends ConsumerStatefulWidget {
  const ProfileCosmeticsPage({super.key});

  @override
  ConsumerState<ProfileCosmeticsPage> createState() =>
      _ProfileCosmeticsPageState();
}

class _ProfileCosmeticsPageState extends ConsumerState<ProfileCosmeticsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = ref.watch(vipTierProvider);
    final canCustomize = tier.index >= VipTier.gold.index;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Premium Profil',
          body: canCustomize
              ? Column(
                  children: [
                    TabBar(
                      controller: _tabs,
                      tabs: const [
                        Tab(text: 'Çerçeve'),
                        Tab(text: 'İsim'),
                        Tab(text: 'Efekt'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _CosmeticGrid(
                            slot: CosmeticSlot.profileFrame,
                            catalog: _mergedCatalog(
                              ref,
                              CosmeticSlot.profileFrame,
                            ),
                            tier: tier,
                          ),
                          _CosmeticGrid(
                            slot: CosmeticSlot.nameEffect,
                            catalog: catalogForSlot(CosmeticSlot.nameEffect),
                            tier: tier,
                          ),
                          _CosmeticGrid(
                            slot: CosmeticSlot.profileEffect,
                            catalog: catalogForSlot(CosmeticSlot.profileEffect),
                            tier: tier,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'Profil çerçevesi ve efekt seçimi Gold üyelik gerektirir.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.push('/vip-gold'),
                          child: const Text('Gold\'a yükselt'),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  List<CosmeticItem> _mergedCatalog(WidgetRef ref, CosmeticSlot slot) {
    final remote = ref.watch(profileFramesCatalogProvider).valueOrNull;
    final local = CosmeticCatalogDefaults.forSlot(slot);
    if (remote == null || remote.isEmpty) return local;
    final ids = remote.map((e) => e.id).toSet();
    return [...remote, ...local.where((e) => !ids.contains(e.id))];
  }
}

class _CosmeticGrid extends ConsumerWidget {
  const _CosmeticGrid({
    required this.slot,
    required this.catalog,
    required this.tier,
  });

  final CosmeticSlot slot;
  final List<CosmeticItem> catalog;
  final VipTier tier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadout = ref.watch(cosmeticLoadoutProvider).valueOrNull;
    final equipped = loadout?.idFor(slot);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: catalog.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          final selected = equipped == null;
          return _CosmeticTile(
            title: 'Varsayılan',
            selected: selected,
            child: const CircleAvatar(
              radius: 28,
              child: Icon(Icons.person),
            ),
            onTap: () => ref
                .read(cosmeticLoadoutProvider.notifier)
                .equip(slot, null),
          );
        }
        final item = catalog[i - 1];
        final unlocked = item.isUnlockedFor(tier: tier);
        final selected = equipped == item.id;
        return _CosmeticTile(
          title: item.name,
          selected: selected,
          locked: !unlocked,
          child: slot == CosmeticSlot.nameEffect
              ? CosmeticNameLabel(
                  text: 'Ad',
                  item: item,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                )
              : CosmeticAvatarFrame(
                  item: item,
                  size: 64,
                  showParticles: false,
                  child: const CircleAvatar(
                    radius: 26,
                    child: Icon(Icons.person, size: 28),
                  ),
                ),
          onTap: unlocked
              ? () => ref
                  .read(cosmeticLoadoutProvider.notifier)
                  .equip(slot, item.id)
              : null,
        );
      },
    );
  }
}

class _CosmeticTile extends StatelessWidget {
  const _CosmeticTile({
    required this.title,
    required this.child,
    required this.selected,
    this.locked = false,
    this.onTap,
  });

  final String title;
  final Widget child;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(opacity: locked ? 0.4 : 1, child: child),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              if (locked)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.lock, size: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
